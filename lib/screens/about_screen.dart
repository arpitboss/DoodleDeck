import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About DoodleDeck'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About DoodleDeck',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'DoodleDeck is the most fun and interactive drawing game you\'ll ever play! '
              'Join public games or create private rooms to play with friends. '
              'Draw and guess in real-time with players around the world.',
              style: TextStyle(fontSize: 18),
            ),
            // Add more content as needed
          ],
        ),
      ),
    );
  }
}
