import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/session_store.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // Fix 2: Keep tab state alive to prevent disposing and rebuilding on tab switch
  @override
  bool get wantKeepAlive => true;
  static const List<String> _dummyAvatars = [
    'assets/images/avatar_1.jpg',
    'assets/images/avatar_2.jpg',
    'assets/images/avatar_3.jpg',
  ];

  String? _selectedAvatar;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _cardSlide;

  String _avatarKey(String ec) => 'selected_avatar_$ec';

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
    _loadAvatar();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    final user = SessionStore.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final savedAvatar = prefs.getString(_avatarKey(user.ec));

    final isValid = savedAvatar != null && _dummyAvatars.contains(savedAvatar);

    if (!isValid && savedAvatar != null) {
      await prefs.remove(_avatarKey(user.ec));
    }

    if (!mounted) return;
    setState(() {
      _selectedAvatar = isValid ? savedAvatar : null;
    });
  }

  String? _avatarFor(SessionUser user) => _selectedAvatar;

  Future<void> _saveAvatar(SessionUser user, String avatarPath) async {
    if (!_dummyAvatars.contains(avatarPath)) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarKey(user.ec), avatarPath);

    if (!mounted) return;
    setState(() {
      _selectedAvatar = avatarPath;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF34D399), size: 18),
            SizedBox(width: 8),
            Text('Profile photo updated successfully'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _removeAvatar(SessionUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_avatarKey(user.ec));

    if (!mounted) return;
    setState(() {
      _selectedAvatar = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.restore_outlined, color: Color(0xFF93C5FD), size: 18),
            SizedBox(width: 8),
            Text('Reset to default profile photo'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _openEditPhoto(SessionUser user) async {
    HapticFeedback.lightImpact();
    final result = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      isScrollControlled: true,
      builder: (_) => _EditAvatarSheet(
        avatars: _dummyAvatars,
        initial: _avatarFor(user),
        initialsFallback: user.name.isNotEmpty ? user.name[0] : '?',
      ),
    );

    if (!mounted || result == null) return;

    if (result.isEmpty) {
      await _removeAvatar(user);
      return;
    }

    await _saveAvatar(user, result);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final user = SessionStore.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF070D1B),
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        backgroundColor: const Color(0xFF070D1B).withValues(alpha: 0.75),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Gradient Base
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
                  stops: [0.0, 0.35, 0.7, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Ambient Glow
          Positioned(
            top: -40,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: user == null
                ? const Center(
                    child: Text(
                      'No user logged in',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                      child: SlideTransition(
                        position: _cardSlide,
                        child: Column(
                          children: [
                            // ── Digital Employee ID Card ──
                            _buildIdCard(user),

                            const SizedBox(height: 20),

                            // ── Detailed Enterprise Profile Fields ──
                            _buildDetailsCard(user),

                            const SizedBox(height: 20),

                            // ── Security Verification Footer ──
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 15,
                                    color: const Color(0xFF60A5FA).withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Verified Corporate Identity • Authorized Session',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.55),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdCard(SessionUser user) {
    final avatar = _avatarFor(user);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A).withValues(alpha: 0.85),
            const Color(0xFF0F1E36).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            children: [
              // Top Corporate Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.corporate_fare_rounded,
                          color: Color(0xFF60A5FA),
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'HEG LIMITED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF34D399).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 12,
                          color: Color(0xFF34D399),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Color(0xFFA7F3D0),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Avatar with Glowing Ring & Quick Edit Overlay
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: const Color(0xFF1E293B),
                      backgroundImage: avatar == null ? null : AssetImage(avatar),
                      child: avatar == null
                          ? Text(
                              user.name.isNotEmpty ? user.name[0] : '?',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Material(
                      color: const Color(0xFF2563EB),
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _openEditPhoto(user),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Employee Name
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 4),

              // Designation & Department
              Text(
                '${user.designation} • ${user.department}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),

              const SizedBox(height: 16),

              // Action button to change photo
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openEditPhoto(user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF93C5FD),
                    side: BorderSide(
                      color: const Color(0xFF60A5FA).withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text(
                    'Change Profile Photo',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(SessionUser user) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E36).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.badge_outlined,
              accentColor: const Color(0xFF38BDF8),
              label: 'Employee Code (EC)',
              value: user.ec,
            ),
            const Divider(color: Color(0x22FFFFFF), height: 22),
            _InfoRow(
              icon: Icons.apartment_rounded,
              accentColor: const Color(0xFF818CF8),
              label: 'Department',
              value: user.department,
            ),
            const Divider(color: Color(0x22FFFFFF), height: 22),
            _InfoRow(
              icon: Icons.work_outline_rounded,
              accentColor: const Color(0xFFFBBF24),
              label: 'Designation',
              value: user.designation,
            ),
            const Divider(color: Color(0x22FFFFFF), height: 22),
            _InfoRow(
              icon: Icons.category_outlined,
              accentColor: const Color(0xFF34D399),
              label: 'Category',
              value: user.category.isEmpty ? '-' : user.category,
            ),
            const Divider(color: Color(0x22FFFFFF), height: 22),
            _InfoRow(
              icon: Icons.verified_user_outlined,
              accentColor: const Color(0xFFA78BFA),
              label: 'System Role',
              value: user.role,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODERN INFO ROW
// ─────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.accentColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(icon, color: accentColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.5,
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODERN AVATAR SELECTION BOTTOM SHEET
// ─────────────────────────────────────────────────────────────

class _EditAvatarSheet extends StatefulWidget {
  final List<String> avatars;
  final String? initial;
  final String initialsFallback;

  const _EditAvatarSheet({
    required this.avatars,
    required this.initial,
    required this.initialsFallback,
  });

  @override
  State<_EditAvatarSheet> createState() => _EditAvatarSheetState();
}

class _EditAvatarSheetState extends State<_EditAvatarSheet> {
  String? _temp;

  @override
  void initState() {
    super.initState();
    _temp = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E36),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 32,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(height: 16),

          // Sheet Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Select Profile Avatar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context, null),
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Current Preview
          Container(
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF38BDF8),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: const Color(0xFF1E293B),
              backgroundImage: (_temp == null) ? null : AssetImage(_temp!),
              child: (_temp == null)
                  ? Text(
                      widget.initialsFallback,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 20),

          // Preset Avatars list
          Wrap(
            spacing: 16,
            runSpacing: 14,
            children: widget.avatars.map((a) {
              final selected = _temp == a;
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _temp = a);
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF38BDF8)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage(a),
                    backgroundColor: const Color(0xFF1E293B),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Default Photo Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, ''),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Reset to Default Avatar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, _temp ?? ''),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text(
                'Save Changes',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
