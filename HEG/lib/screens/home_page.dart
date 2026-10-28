import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/session_store.dart';
import '../widgets/chat_bubble_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const List<_MenuItem> _items = [
    _MenuItem(
      title: 'My Profile',
      subtitle: 'Employee credentials, department & role info',
      icon: Icons.person_rounded,
      route: '/profile',
      accentColor: Color(0xFF818CF8),
      badgeText: 'Personal',
    ),
    _MenuItem(
      title: 'Pass System',
      subtitle: 'Vehicle pass registry, gate tracking & stickers',
      icon: Icons.directions_car_rounded,
      route: '/vehicleTracking',
      accentColor: Color(0xFF38BDF8),
      badgeText: 'VPMS',
    ),
    _MenuItem(
      title: 'Permission System',
      subtitle: 'Contractor permissions, gate logs & PDF passes',
      icon: Icons.receipt_long_rounded,
      route: '/cvpsRequests',
      accentColor: Color(0xFF34D399),
      badgeText: 'CVPS',
    ),
  ];

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  Timer? _notifTimer;

  late final AnimationController _entranceController;
  late final AnimationController _ambientController;

  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _headerSlide;
  late final Animation<Offset> _gridSlide;
  late final Animation<double> _ambientFloat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _gridSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _ambientFloat = Tween<double>(begin: -12.0, end: 12.0).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOutSine),
    );

    _entranceController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _startPolling();
    });
  }

  void _startPolling() {
    _notifTimer?.cancel();
    _notifTimer = Timer.periodic(const Duration(seconds: 8), (_) {});
  }

  void _stopPolling() {
    _notifTimer?.cancel();
    _notifTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _stopPolling();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await SessionStore.logout();

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = SessionStore.employeeId ?? 'emp_001';
    final String currentUserName = SessionStore.employeeName ?? 'Employee';
    final user = SessionStore.currentUser;
    final bool isAdmin = SessionStore.isChatAdmin;
    final String receiverId = SessionStore.chatReceiverId;

    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF070D1B),

      // Custom Modern Glass AppBar
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.6),
                border: Border.all(
                  color: const Color(0xFF60A5FA).withValues(alpha: 0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/image3.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.business_rounded,
                    color: Color(0xFF60A5FA),
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'HEG HRMS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF070D1B).withValues(alpha: 0.75),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF60A5FA).withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF1E3A8A),
                child: Icon(
                  Icons.person_rounded,
                  color: Color(0xFF93C5FD),
                  size: 16,
                ),
              ),
            ),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // Chat FAB with existing parameters
      floatingActionButton: ChatBubbleButton(
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        receiverId: receiverId,
        isAdmin: isAdmin,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Animated Background + Body
      body: Stack(
        children: [
          // Base gradient
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
                  stops: [0.0, 0.3, 0.7, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Ambient floating orbs
          AnimatedBuilder(
            animation: _ambientFloat,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: 40 + _ambientFloat.value,
                    right: -60,
                    child: _GlowOrb(
                      size: 260,
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.16),
                      blurRadius: 100,
                    ),
                  ),
                  Positioned(
                    bottom: 80 - _ambientFloat.value,
                    left: -70,
                    child: _GlowOrb(
                      size: 280,
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.14),
                      blurRadius: 110,
                    ),
                  ),
                ],
              );
            },
          ),

          // Tech grid overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _TechPatternPainter(
                color: Colors.white.withValues(alpha: 0.02),
              ),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 18,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome & Profile Hero Card
                    SlideTransition(
                      position: _headerSlide,
                      child: _HeroGreetingCard(
                        greeting: _getGreeting(),
                        user: user,
                        employeeName: currentUserName,
                        employeeId: currentUserId,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section Heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quick Modules',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Choose an enterprise service to proceed',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${HomePage._items.length} Active',
                                style: const TextStyle(
                                  color: Color(0xFF93C5FD),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Grid of Menu Cards with Entrance Motion
                    SlideTransition(
                      position: _gridSlide,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return isTablet
                              ? Row(
                                  children: HomePage._items.map((item) {
                                    final bool isEnabled =
                                        item.route == '/profile' ||
                                        item.route == '/vehicleTracking' ||
                                        item.route == '/cvpsRequests';
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: _ModernMenuCard(
                                          item: item,
                                          isEnabled: isEnabled,
                                          onTap: isEnabled
                                              ? () => Navigator.pushNamed(
                                                  context,
                                                  item.route,
                                                )
                                              : null,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                )
                              : Column(
                                  children: HomePage._items.map((item) {
                                    final bool isEnabled =
                                        item.route == '/profile' ||
                                        item.route == '/vehicleTracking' ||
                                        item.route == '/cvpsRequests';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: _ModernMenuCard(
                                        item: item,
                                        isEnabled: isEnabled,
                                        onTap: isEnabled
                                            ? () => Navigator.pushNamed(
                                                context,
                                                item.route,
                                              )
                                            : null,
                                      ),
                                    );
                                  }).toList(),
                                );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Enterprise System Status Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1E36).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34D399).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: Color(0xFF34D399),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Connected to HEG Enterprise Network',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sessions secured with role-based access control',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60), // Space for Chat FAB
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Redesigned Executive Drawer
      drawer: _ModernDrawer(
        user: user,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        onLogout: () => _logout(context),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HERO GREETING CARD WITH USER IDENTITY & BADGES
// ─────────────────────────────────────────────────────────────

class _HeroGreetingCard extends StatelessWidget {
  final String greeting;
  final SessionUser? user;
  final String employeeName;
  final String employeeId;

  const _HeroGreetingCard({
    required this.greeting,
    required this.user,
    required this.employeeName,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context) {
    final role = user?.role ?? 'EMPLOYEE';
    final dept = user?.department ?? 'GENERAL';
    final designation = user?.designation ?? 'Team Member';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A).withValues(alpha: 0.8),
            const Color(0xFF0F1E36).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with status ring
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        employeeName.isNotEmpty
                            ? employeeName[0].toUpperCase()
                            : 'E',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Greeting & Full Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              greeting,
                              style: TextStyle(
                                color: const Color(0xFF93C5FD).withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.waving_hand_rounded,
                              size: 14,
                              color: Color(0xFFFBBF24),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          employeeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          designation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Color(0x3360A5FA), height: 1),
              const SizedBox(height: 14),

              // Chips for EC Code, Department & Role
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(
                    icon: Icons.badge_outlined,
                    label: 'EC: $employeeId',
                    color: const Color(0xFF93C5FD),
                  ),
                  _InfoPill(
                    icon: Icons.corporate_fare_rounded,
                    label: dept,
                    color: const Color(0xFFA7F3D0),
                  ),
                  _InfoPill(
                    icon: Icons.verified_user_rounded,
                    label: role,
                    color: role == 'APPROVER'
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFE9D5FF),
                    isHighlighted: role == 'APPROVER',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isHighlighted;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: isHighlighted ? 0.6 : 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODERN MENU CARD WITH GRADIENT ACCENT & MICRO-MOTION
// ─────────────────────────────────────────────────────────────

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color accentColor;
  final String badgeText;

  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.accentColor,
    required this.badgeText,
  });
}

class _ModernMenuCard extends StatefulWidget {
  final _MenuItem item;
  final VoidCallback? onTap;
  final bool isEnabled;

  const _ModernMenuCard({
    required this.item,
    required this.onTap,
    required this.isEnabled,
  });

  @override
  State<_ModernMenuCard> createState() => _ModernMenuCardState();
}

class _ModernMenuCardState extends State<_ModernMenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isEnabled = widget.isEnabled;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1E36).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isEnabled
                ? item.accentColor.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isEnabled
                  ? item.accentColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onHighlightChanged: (val) {
              if (mounted) setState(() => _pressed = val);
            },
            onTap: isEnabled
                ? () {
                    HapticFeedback.lightImpact();
                    widget.onTap?.call();
                  }
                : null,
            splashColor: item.accentColor.withValues(alpha: 0.2),
            highlightColor: item.accentColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  // Glowing Icon Container
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          item.accentColor.withValues(alpha: 0.25),
                          item.accentColor.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.accentColor.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        item.icon,
                        color: isEnabled ? item.accentColor : Colors.white38,
                        size: 26,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: item.accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.badgeText,
                                style: TextStyle(
                                  color: item.accentColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Forward action arrow
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: item.accentColor.withValues(alpha: 0.8),
                      size: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODERN EXECUTIVE DRAWER
// ─────────────────────────────────────────────────────────────

class _ModernDrawer extends StatelessWidget {
  final SessionUser? user;
  final String currentUserId;
  final String currentUserName;
  final VoidCallback onLogout;

  const _ModernDrawer({
    required this.user,
    required this.currentUserId,
    required this.currentUserName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final role = user?.role ?? 'EMPLOYEE';
    final dept = user?.department ?? 'GENERAL';
    final designation = user?.designation ?? 'Team Member';

    return Drawer(
      backgroundColor: const Color(0xFF0B172B),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F1E36)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF2563EB),
                        child: Text(
                          currentUserName.isNotEmpty
                              ? currentUserName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUserName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              designation,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF60A5FA).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'EC: $currentUserId',
                          style: const TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dept,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(
                            color: Color(0xFFA7F3D0),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerTile(
                    icon: Icons.person_outline_rounded,
                    title: 'My Profile',
                    subtitle: 'View employee information',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                  const SizedBox(height: 6),
                  _DrawerTile(
                    icon: Icons.directions_car_outlined,
                    title: 'Pass System (VPMS)',
                    subtitle: 'Vehicle tracking & stickers',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/vehicleTracking');
                    },
                  ),
                  const SizedBox(height: 6),
                  _DrawerTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Permission System (CVPS)',
                    subtitle: 'Contractor gate permits',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/cvpsRequests');
                    },
                  ),
                ],
              ),
            ),

            // Logout Action at bottom
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                  ),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFF87171),
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Color(0xFFF87171),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Sign out of session',
                    style: TextStyle(
                      color: const Color(0xFFF87171).withValues(alpha: 0.7),
                      fontSize: 11.5,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: const Color(0xFF60A5FA), size: 22),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11.5,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white38,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AMBIENT GLOW ORB & TECH PAINTER
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
