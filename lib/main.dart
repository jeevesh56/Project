import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'finance_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Enable authentication persistence on web only
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mo-Mo (Money Monitor)',
      theme: ThemeData(fontFamily: 'Poppins'),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            // User is logged in, show dashboard
            return FinanceDashboard(
              userId: snapshot.data!.uid,
              userName: snapshot.data!.displayName ?? snapshot.data!.email ?? 'User',
            );
          }
          
          // User is not logged in, show login page
          return const LoginPage();
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => FinanceDashboard(
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
          userName: FirebaseAuth.instance.currentUser?.displayName ?? 
                   FirebaseAuth.instance.currentUser?.email ?? 'User',
        ),
      },
    );
  }
}

