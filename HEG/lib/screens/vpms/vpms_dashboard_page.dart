// lib/screens/vpms/vpms_dashboard_page.dart

import 'package:flutter/material.dart';
import '../../widgets/notification_bell.dart';
import 'vehicles/vehicles_list_page.dart';

class VpmsDashboardPage extends StatelessWidget {
  const VpmsDashboardPage({super.key});

  // ── Module definitions ─────────────────────────────────────
  // To ADD a new module later: just append one entry here.
  // To REMOVE: delete its entry. Nothing else changes.
  static const List<_VpmsModule> _modules = [
    _VpmsModule(
      title: 'Vehicles Master',
      subtitle: 'All registered vehicles',
      icon: Icons.directions_car,
      color: Color(0xFF1565C0),
      isReady: true, // ← flip to false to show "coming soon"
    ),
    _VpmsModule(
      title: 'Pass Registry',
      subtitle: 'Active & inactive passes',
      icon: Icons.badge_outlined,
      color: Color(0xFF2E7D32),
      isReady: false,
    ),
    _VpmsModule(
      title: 'Documents',
      subtitle: 'PUC, Insurance, Fitness',
      icon: Icons.description_outlined,
      color: Color(0xFFE65100),
      isReady: false,
    ),
    _VpmsModule(
      title: 'History',
      subtitle: 'Pass action audit trail',
      icon: Icons.history,
      color: Color(0xFF6A1B9A),
      isReady: false,
    ),
  ];

  // ── Route to page ──────────────────────────────────────────
  // When a new module is ready, add its page here.
  Widget _pageFor(int index) {
    switch (index) {
      case 0:
        return const VehiclesListPage();
      // case 1: return const PassesListPage();
      // case 2: return const DocumentsListPage();
      // case 3: return const HistoryListPage();
      default:
        return const VehiclesListPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Vehicle Pass Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [NotificationBell(), SizedBox(width: 8)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Module',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF37474F),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap a module to view data',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: _modules.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (ctx, i) {
                  final m = _modules[i];
                  final color = m.isReady ? m.color : Colors.grey;
                  return GestureDetector(
                    onTap: () {
                      if (!m.isReady) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Module coming soon'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(builder: (_) => _pageFor(i)),
                      );
                    },
                    child: Opacity(
                      opacity: m.isReady ? 1.0 : 0.5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(m.icon, color: color, size: 28),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    m.isReady ? m.subtitle : 'Coming soon',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data class for module config ───────────────────────────────
class _VpmsModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isReady;
  const _VpmsModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isReady,
  });
}
