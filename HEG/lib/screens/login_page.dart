import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../data/session_store.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _userController = TextEditingController();
  final _passController = TextEditingController();

  final FocusNode _userFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  bool _obscure = true;
  bool _loading = false;

  // Animation controllers for stunning entrance & ambient motion
  late final AnimationController _entranceController;
  late final AnimationController _ambientController;

  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _headerSlide;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _ambientFloat;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _ambientFloat = Tween<double>(begin: -15.0, end: 15.0).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOutSine),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _quickFill(String username, String password) {
    HapticFeedback.selectionClick();
    setState(() {
      _userController.text = username;
      _passController.text = password;
    });
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.flash_on, color: Color(0xFFFBBF24), size: 18),
            const SizedBox(width: 8),
            Text('Filled demo credentials for "$username"'),
          ],
        ),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchEmployeeDetails(String empCode) async {
    final code = empCode.trim();

    if (code.isEmpty) {
      return null;
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.employeeReport}/${Uri.encodeComponent(code)}',
            ),
            headers: {
              'x-api-key': ApiConfig.apiKey,
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(milliseconds: 12000));

      if (response.statusCode != 200) {
        return null;
      }

      final body = jsonDecode(response.body);

      if (body is! Map<String, dynamic>) {
        return null;
      }

      final data = body['data'];

      return data is Map<String, dynamic> ? data : body;
    } catch (_) {
      return null;
    }
  }

  String _firstText(List<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty &&
          text.toUpperCase() != 'NULL' &&
          text.toUpperCase() != 'N/A') {
        return text;
      }
    }

    return fallback;
  }

  void _showFeedbackToast({
    required String message,
    required IconData icon,
    Color iconColor = const Color(0xFFF87171),
  }) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 8,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
    );
  }

  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    HapticFeedback.mediumImpact();
    setState(() => _loading = true);

    final u = _userController.text.trim();
    final p = _passController.text.trim();

    // ════════════════════════════════════════════════════════════
    // KEEP EXISTING DEMO LOGINS (for offline testing)
    // ════════════════════════════════════════════════════════════

    // ADMIN LOGIN
    if (u == 'admin' && p == '123456') {
      const user = SessionUser(
        name: 'Admin',
        ec: '929',
        department: 'ADMIN',
        designation: 'Administrator',
        category: 'Admin',
        role: 'APPROVER',
      );

      await SessionStore.saveLogin(userId: 'admin', admin: true, user: user);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    // USER 1
    if (u == 'admin1' && p == '123456') {
      const user = SessionUser(
        name: 'Prabhat Saxena',
        ec: '185',
        department: 'IT 163',
        designation: 'Manager',
        category: 'Executive',
        role: 'EMPLOYEE',
      );

      await SessionStore.saveLogin(userId: 'admin1', admin: false, user: user);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    // USER 2
    if (u == 'admin2' && p == '123456') {
      const user = SessionUser(
        name: 'Arvind Kumar Bairagi',
        ec: '113',
        department: 'IT 163',
        designation: 'Senior Manager',
        category: 'Executive',
        role: 'EMPLOYEE',
      );

      await SessionStore.saveLogin(userId: 'admin2', admin: false, user: user);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    // ════════════════════════════════════════════════════════════
    // CALL WEB API LOGIN (same as web UI)
    // ════════════════════════════════════════════════════════════

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/authority/login'),
            headers: {
              'x-api-key': ApiConfig.apiKey,
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'username': u, 'password': p}),
          )
          .timeout(const Duration(milliseconds: 12000));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map;

        final roleStr = (data['role'] ?? 'UPLOADER')
            .toString()
            .toUpperCase()
            .trim();
        final empCodeStr = (data['empNo'] ?? u).toString().trim();

        String mappedRole;
        String mappedCategory;

        if (roleStr == 'APPROVER' || roleStr == 'ADMIN') {
          mappedRole = 'APPROVER';
          mappedCategory = 'Authority';
        } else if (roleStr == 'CONFIRMER') {
          mappedRole = 'CONFIRMER';
          mappedCategory = 'Authority';
        } else if (roleStr == 'UPLOADER') {
          mappedRole = 'UPLOADER';
          mappedCategory = 'Authority';
        } else {
          mappedRole = 'EMPLOYEE';
          mappedCategory = 'Company_Employee';
        }

        final employeeDetails = await _fetchEmployeeDetails(empCodeStr) ?? {};

        final user = SessionUser(
          name: _firstText([
            employeeDetails['empName'],
            employeeDetails['name'],
            employeeDetails['employeeName'],
            data['empName'],
            data['name'],
            empCodeStr,
          ], fallback: empCodeStr),
          ec: empCodeStr,
          department: _firstText([
            employeeDetails['department'],
            employeeDetails['departmentName'],
            employeeDetails['dept'],
            employeeDetails['deptName'],
            employeeDetails['DEPARTMENT'],
            employeeDetails['DEPT'],
            data['department'],
            data['departmentName'],
            data['dept'],
            data['deptName'],
          ], fallback: '-'),
          designation: _firstText([
            employeeDetails['designation'],
            employeeDetails['designationName'],
            employeeDetails['desig'],
            data['designation'],
            data['designationName'],
            mappedRole,
          ], fallback: mappedRole),
          category: _firstText([
            employeeDetails['category'],
            employeeDetails['employeeCategory'],
            employeeDetails['userCategory'],
            data['category'],
            data['employeeCategory'],
            mappedCategory,
          ], fallback: mappedCategory),
          role: mappedRole,
        );

        await SessionStore.saveLogin(
          userId: empCodeStr,
          admin: mappedRole == 'APPROVER',
          user: user,
        );

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else if (response.statusCode == 401) {
        if (!mounted) return;
        setState(() => _loading = false);
        _showFeedbackToast(
          message: 'Invalid Employee Code or Password',
          icon: Icons.error_outline_rounded,
        );
      } else if (response.statusCode == 404) {
        if (!mounted) return;
        setState(() => _loading = false);
        _showFeedbackToast(
          message: 'Employee Code "$u" not found in registry',
          icon: Icons.person_off_outlined,
        );
      } else {
        if (!mounted) return;
        setState(() => _loading = false);
        _showFeedbackToast(
          message: 'Authentication failed. Please verify credentials.',
          icon: Icons.lock_clock_outlined,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showFeedbackToast(
        message: 'Cannot reach server. Please check your network connection.',
        icon: Icons.wifi_off_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFF070D1B),
      body: Stack(
        children: [
          // ── Layer 1: Multi-depth Gradient Base ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF060B14),
                    Color(0xFF0B172B),
                    Color(0xFF0F264A),
                    Color(0xFF1E3A8A),
                  ],
                  stops: [0.0, 0.35, 0.70, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // ── Layer 2: Animated Floating Ambient Mesh Orbs ──
          AnimatedBuilder(
            animation: _ambientFloat,
            builder: (context, child) {
              return Stack(
                children: [
                  // Top Cyan Ambient Glow
                  Positioned(
                    top: -70 + _ambientFloat.value,
                    right: -50 - (_ambientFloat.value * 0.5),
                    child: _GlowOrb(
                      size: 260,
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.18),
                      blurRadius: 100,
                    ),
                  ),

                  // Middle Royal Blue Accent
                  Positioned(
                    top: size.height * 0.35 - _ambientFloat.value,
                    left: -90 + (_ambientFloat.value * 0.6),
                    child: _GlowOrb(
                      size: 280,
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.16),
                      blurRadius: 110,
                    ),
                  ),

                  // Bottom Indigo Ambient
                  Positioned(
                    bottom: -80 + (_ambientFloat.value * 0.8),
                    right: -40,
                    child: _GlowOrb(
                      size: 320,
                      color: const Color(0xFF6366F1).withValues(alpha: 0.14),
                      blurRadius: 120,
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Layer 3: Subtle Hex / Grid Texture Overlay ──
          Positioned.fill(
            child: CustomPaint(
              painter: _TechPatternPainter(
                color: Colors.white.withValues(alpha: 0.02),
              ),
            ),
          ),

          // ── Layer 4: Main Interactive UI with Staggered Entrance ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Brand Header
                        SlideTransition(
                          position: _headerSlide,
                          child: const _ModernBrandHeader(),
                        ),

                        const SizedBox(height: 28),

                        // Animated Glassmorphism Login Card
                        SlideTransition(
                          position: _cardSlide,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildFormCard(context),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Security / Portal Footer Tag
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'HEG Internal Enterprise Access • SSL Encrypted',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E36).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 36,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card Title & Subtitle
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF60A5FA).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_person_outlined,
                        color: Color(0xFF60A5FA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Enter your credentials to continue',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Username / Employee Code Field
                _PremiumTextField(
                  controller: _userController,
                  focusNode: _userFocus,
                  label: 'Username / Employee Code',
                  hint: 'e.g., admin, admin1, admin2',
                  icon: Icons.badge_outlined,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_passFocus);
                  },
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Enter your username';
                    if (value.length < 3) return 'Must be at least 3 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password Field
                _PremiumTextField(
                  controller: _passController,
                  focusNode: _passFocus,
                  label: 'Password',
                  hint: 'Enter your account password',
                  icon: Icons.key_outlined,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loading ? null : _onLogin(),
                  suffix: IconButton(
                    splashRadius: 20,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _obscure = !_obscure);
                    },
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        key: ValueKey<bool>(_obscure),
                        color: Colors.white.withValues(alpha: 0.75),
                        size: 20,
                      ),
                    ),
                  ),
                  validator: (v) {
                    final value = v ?? '';
                    if (value.isEmpty) return 'Enter your password';
                    if (value.length < 6) {
                      return 'Minimum 6 characters required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Radiant Animated Submit Button
                _GradientActionButton(
                  loading: _loading,
                  onPressed: _loading ? null : _onLogin,
                  text: 'Login to Portal',
                ),

                const SizedBox(height: 22),

                // Demo accounts information container (interactive + preserves all text)
                _buildDemoSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 14,
                color: const Color(0xFF60A5FA).withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Text(
                'Quick Demo Access (Tap to fill)',
                style: TextStyle(
                  color: const Color(0xFF93C5FD).withValues(alpha: 0.95),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              _DemoChip(
                label: 'admin',
                role: 'Approver',
                onTap: () => _quickFill('admin', '123456'),
              ),
              _DemoChip(
                label: 'admin1',
                role: 'Employee 1',
                onTap: () => _quickFill('admin1', '123456'),
              ),
              _DemoChip(
                label: 'admin2',
                role: 'Employee 2',
                onTap: () => _quickFill('admin2', '123456'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Demo: admin / 123456  •  admin1 / 123456  •  admin2 / 123456',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BRAND HEADER WITH PREMIUM LOGO BADGE & GRADIENT TEXT
// ─────────────────────────────────────────────────────────────

class _ModernBrandHeader extends StatelessWidget {
  const _ModernBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Glowing Logo Badge Container
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF60A5FA).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/image3.jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(
                  Icons.business_rounded,
                  color: Color(0xFF60A5FA),
                  size: 36,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Brand Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF60A5FA).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF34D399),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'ENTERPRISE MOBILITY SYSTEM',
                style: TextStyle(
                  color: Color(0xFF93C5FD),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Main App Title
        const Text(
          'HEG Employee Portal',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 4),

        // Subtitle
        Text(
          'Login to continue to your authorized workspace',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODERN TEXT FIELD WITH DYNAMIC HIGHLIGHT & CLEAR FOCUS
// ─────────────────────────────────────────────────────────────

class _PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputAction textInputAction;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _PremiumTextField({
    required this.controller,
    this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.suffix,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<_PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<_PremiumTextField> {
  late FocusNode _node;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node = widget.focusNode ?? FocusNode();
    _node.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _focused = _node.hasFocus);
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _node.dispose();
    } else {
      _node.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: _focused ? const Color(0xFF60A5FA) : Colors.white.withValues(alpha: 0.85),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _node,
            obscureText: widget.obscureText,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: const Color(0xFF60A5FA),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13.5,
              ),
              prefixIcon: Icon(
                widget.icon,
                color: _focused
                    ? const Color(0xFF60A5FA)
                    : Colors.white.withValues(alpha: 0.65),
                size: 20,
              ),
              suffixIcon: widget.suffix,
              filled: true,
              fillColor: _focused
                  ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.07),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF60A5FA),
                  width: 1.6,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFF87171),
                  width: 1.2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 1.6,
                ),
              ),
              errorStyle: const TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            validator: widget.validator,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RADIANT GRADIENT ACTION BUTTON WITH SHIMMER / GLOW
// ─────────────────────────────────────────────────────────────

class _GradientActionButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  final String text;

  const _GradientActionButton({
    required this.loading,
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: loading
              ? [const Color(0xFF1E3A8A), const Color(0xFF2563EB)]
              : [
                  const Color(0xFF2563EB),
                  const Color(0xFF0284C7),
                  const Color(0xFF06B6D4),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: loading
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.38),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Center(
            child: loading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Authenticating...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// QUICK-FILL DEMO CHIP
// ─────────────────────────────────────────────────────────────

class _DemoChip extends StatelessWidget {
  final String label;
  final String role;
  final VoidCallback onTap;

  const _DemoChip({
    required this.label,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF60A5FA).withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF93C5FD),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($role)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AMBIENT GLOW ORB
// ─────────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double blurRadius;

  const _GlowOrb({
    required this.size,
    required this.color,
    required this.blurRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUBTLE TECH PATTERN PAINTER
// ─────────────────────────────────────────────────────────────

class _TechPatternPainter extends CustomPainter {
  final Color color;

  _TechPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const step = 44.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        if ((x + y) % (step * 2) == 0) {
          canvas.drawCircle(Offset(x, y), 1.2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TechPatternPainter oldDelegate) => false;
}
