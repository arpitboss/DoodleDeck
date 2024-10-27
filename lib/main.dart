import 'package:doodle_deck/screens/create_room_screen.dart';
import 'package:doodle_deck/screens/join_room_screen.dart';
import 'package:doodle_deck/screens/room_selection_screen.dart';
import 'package:doodle_deck/screens/splash_screen.dart';
import 'package:doodle_deck/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DoodleDeckApp());
}

class DoodleDeckApp extends StatelessWidget {
  const DoodleDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DoodleDeck',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/roomSelection': (context) => const RoomSelectionScreen(),
        '/createRoom': (context) => const CreateRoomScreen(),
        '/joinRoom': (context) => const JoinRoomScreen(),
      },
    );
  }
}
