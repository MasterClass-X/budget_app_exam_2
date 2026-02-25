import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/transaction_controller.dart'; // Ajout de l'import
import 'views/auth/login_screen.dart';
import 'views/auth/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => TransactionController()), // Ajout
      ],
      child: MaterialApp(
        title: 'Gestion Budget',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: Consumer<AuthController>(
          builder: (context, auth, child) {
            if (auth.user != null) {
              return const HomeScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
