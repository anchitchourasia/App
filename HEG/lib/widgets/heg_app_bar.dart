import 'package:flutter/material.dart';
import 'notification_bell.dart';

class HegAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;

  const HegAppBar({super.key, required this.title, this.showBack = true});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBack,
      title: Text(title),
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      actions: const [_BellPill(), SizedBox(width: 8)],
    );
  }
}

class _BellPill extends StatelessWidget {
  const _BellPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: const NotificationBell(),
    );
  }
}
