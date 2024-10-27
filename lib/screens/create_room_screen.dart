import 'package:doodle_deck/screens/drawing_screen.dart';
import 'package:doodle_deck/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _nameController = TextEditingController();
  final _roomNameController = TextEditingController();
  String? _maxRoundsValue;
  String? _roomSizeValue;
  final _formKey = GlobalKey<FormState>();

  void createRoom() {
    if (_formKey.currentState!.validate()) {
      if (_maxRoundsValue != null && _roomSizeValue != null) {
        Map<String, dynamic> data = {
          'nickname': _nameController.text,
          'name': _roomNameController.text,
          'occupancy': _roomSizeValue,
          'maxRounds': _maxRoundsValue,
        };

        // Check if the widget is still mounted before navigation
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DrawingScreen(
                data: data,
                screenFrom: 'createRoom',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select max rounds and room size.'),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent resizing when keyboard appears
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
                              'Create Room',
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
                            const SizedBox(height: 20),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.white.withOpacity(0.8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _maxRoundsValue,
                                  icon: const Icon(Icons.arrow_drop_down,
                                      color: Colors.black),
                                  dropdownColor: Colors.white,
                                  hint: const Text(
                                    'Select Max Rounds',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  items: <String>["2", "5", "10", "15"]
                                      .map<DropdownMenuItem<String>>(
                                          (String value) => DropdownMenuItem(
                                                value: value,
                                                child: Text(
                                                  value,
                                                  style: const TextStyle(
                                                      color: Colors.black),
                                                ),
                                              ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _maxRoundsValue = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.white.withOpacity(0.8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _roomSizeValue,
                                  icon: const Icon(Icons.arrow_drop_down,
                                      color: Colors.black),
                                  dropdownColor: Colors.white,
                                  hint: const Text(
                                    'Select Room Size',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  items: <String>["2", "3", "4", "5", "6", "7"]
                                      .map<DropdownMenuItem<String>>(
                                          (String value) => DropdownMenuItem(
                                                value: value,
                                                child: Text(
                                                  value,
                                                  style: const TextStyle(
                                                      color: Colors.black),
                                                ),
                                              ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _roomSizeValue = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            ElevatedButton(
                              onPressed: createRoom,
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
                                    'Create',
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
                                Navigator.pop(context);
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
