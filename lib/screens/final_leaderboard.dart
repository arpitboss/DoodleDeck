import 'package:flutter/material.dart';

class FinalLeaderboard extends StatelessWidget {
  final List<Map> scoreboard;
  final String winner;

  const FinalLeaderboard(this.scoreboard, this.winner, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
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
          Container(
            padding: const EdgeInsets.all(8),
            height: double.maxFinite,
            child: Column(
              children: [
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 50.0),
                      child: Text(
                        "Final Leaderboard",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: IconButton(
                        icon: const Icon(
                          Icons.home_filled,
                          color: Colors.white70,
                          size: 24,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/roomSelection');
                        },
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    color: Colors.white.withOpacity(0.8),
                    child: ListView.separated(
                      primary: true,
                      shrinkWrap: true,
                      itemCount: scoreboard.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey[300]),
                      itemBuilder: (context, index) {
                        var data = scoreboard[index].values;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          leading: const Icon(Icons.person, color: Colors.blueAccent),
                          title: Text(
                            data.elementAt(0),
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w600),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              data.elementAt(1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "$winner has won the game! 🎉",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
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
