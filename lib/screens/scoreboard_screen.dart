import 'package:flutter/material.dart';

class PlayerScore extends StatelessWidget {
  final List<Map> userData;
  const PlayerScore(this.userData, {super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 250,
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/background_doodle_deck.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content
          Column(
            children: [
              // Header Section
              Container(
                height: 100,
                color: Colors.blueAccent.withOpacity(0.8),
                padding: const EdgeInsets.only(top: 16.0, right: 70.0),
                child: const Column(
                  children: [
                    SizedBox(height: 34,),
                    Center(
                      child: Text(
                        'Player Scores',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Scores List
              Expanded(
                child: Container(
                  color: Colors.white.withOpacity(0.8),
                  child: ListView.separated(
                    itemCount: userData.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                    itemBuilder: (context, index) {
                      var data = userData[index].values;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        leading: const Icon(Icons.person, color: Colors.blueAccent),
                        title: Text(
                          data.elementAt(0),
                          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(6.0),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            data.elementAt(1),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
