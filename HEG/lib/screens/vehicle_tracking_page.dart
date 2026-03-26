import 'package:flutter/material.dart';
import '../widgets/notification_bell.dart';

class VehicleTrackingPage extends StatelessWidget {
  const VehicleTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Tracking'),
        actions: const [NotificationBell(), SizedBox(width: 8)],
      ),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
