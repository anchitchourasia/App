import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart'; // ✅ add for offline cache (Hive)
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'data/session_store.dart'; // ✅ add this
import 'screens/login_page.dart';
import 'screens/home_page.dart';

import 'screens/profile_page.dart';

// New module screens

import 'screens/vehicle_tracking_page.dart';

import 'screens/approver/approver_menu_page.dart';
import 'screens/cvps/cvps_requests_page.dart';
import 'screens/cvps/cvps_form_page.dart';

import 'screens/cvps/cvps_pass_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'assets/.env');

  // DB init
  
  // ✅ Load saved session (remember login)
  await SessionStore.loadFromDisk();

  // ✅ Offline cache init (Hive)
  await Hive.initFlutter();
  await Hive.openBox('cache');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final startRoute = SessionStore.isLoggedIn ? '/home' : '/login';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Fix 3: Align global scaffoldBackgroundColor with the app's light canvas
      // to eliminate bright white flash during route transitions.
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF0F4F9),
        canvasColor: const Color(0xFFF0F4F9),
      ),
      initialRoute: startRoute, // ✅ dynamic initial route
      routes: <String, WidgetBuilder>{
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/profile': (_) => const ProfilePage(),
        '/cvpsRequests': (context) => const CvpsRequestsPage(),
        '/cvpsForm': (context) => const CvpsFormPage(), // to be implemented
        '/cvpsPass': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final requestNo = args as int;
          return CvpsPassPage(requestNo: requestNo);
        },

        '/vehicleTracking': (context) {
          final role = SessionStore.currentUser?.role;
          if (role == 'APPROVER') {
            return const ApproverVehicleMenuPage();
          }
          return const VehicleTrackingPage();
        },
      },
    );
  }
}
