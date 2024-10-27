import 'dart:convert';

import 'package:doodle_deck/screens/drawing_screen.dart';
import 'package:doodle_deck/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _nameController = TextEditingController();
  final _roomNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<Map<String, dynamic>> _checkRoomExists(String roomName) async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['SERVER_URL']}/check-room?name=$roomName'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'exists': data['exists'] == true,
          'full': data['full'] == true,
        };
      } else {
        print('Error checking room existence: ${response.statusCode}');
        return {'exists': false, 'full': false};
      }
    } catch (e) {
      print('Error checking room existence: $e');
      return {'exists': false, 'full': false};
    }
  }

  void joinRoom() async {
    if (_formKey.currentState!.validate()) {
      if (_nameController.text.isNotEmpty &&
          _roomNameController.text.isNotEmpty) {
        final roomName = _roomNameController.text;
        final roomStatus = await _checkRoomExists(roomName);

        // Check if the widget is mounted before proceeding
        if (!mounted) return;

        if (roomStatus['exists']) {
          if (roomStatus['full']) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('The room is full.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            Map<String, dynamic> data = {
              'nickname': _nameController.text,
              'name': roomName,
            };
            print('Joining room with data: $data'); // Debug log
            if (mounted) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    DrawingScreen(data: data, screenFrom: 'joinRoom'),
              ));
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('The room name does not exist.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        print('Form validation failed'); // Debug log
      }
    } else {
      print('Form key current state is null'); // Debug log
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/background_doodle_deck.png',
              fit: BoxFit.cover,
            ),
          ),
          // Form Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 50),
                            const Text(
                              'Join Room',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.black54,
                                    offset: Offset(2.0, 2.0),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 50),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: CustomTextField(
                                hintText: 'Enter your name',
                                controller: _nameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: CustomTextField(
                                hintText: 'Enter room name',
                                controller: _roomNameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter room name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 40),
                            ElevatedButton(
                              onPressed: joinRoom,
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(
                                    MediaQuery.of(context).size.width / 2.5,
                                    60),
                                backgroundColor: Colors.blueAccent,
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                shadowColor: Colors.black.withOpacity(0.3),
                                elevation: 10,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Join',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(
                                    Icons.arrow_forward_outlined,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pop(
                                    context); // Go back to previous screen
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(
                                    MediaQuery.of(context).size.width / 3, 60),
                                side: const BorderSide(
                                    color: Colors.white, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text(
                                    'Back',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18),
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
          ),
        ],
      ),
    );
  }
}
