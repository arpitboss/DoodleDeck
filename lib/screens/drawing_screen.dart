import 'dart:async';

import 'package:doodle_deck/enum.dart';
import 'package:doodle_deck/screens/final_leaderboard.dart';
import 'package:doodle_deck/screens/room_selection_screen.dart';
import 'package:doodle_deck/screens/scoreboard_screen.dart';
import 'package:doodle_deck/screens/waiting_lobby_screen.dart';
import 'package:doodle_deck/widgets/my_custom_painter.dart';
import 'package:doodle_deck/widgets/stroke.dart';
import 'package:doodle_deck/widgets/touch_points.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DrawingScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String screenFrom;

  const DrawingScreen(
      {super.key, required this.data, required this.screenFrom});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  late IO.Socket _socket;
  Map<String, dynamic> dataOfRoom = {};
  List<TouchPoints> points = [];
  StrokeCap strokeType = StrokeCap.round;
  Color selectedColor = Colors.black;
  double opacity = 1.0;
  double strokeWidth = 2.0;
  List<Widget> textBlankWidget = [];
  final ScrollController _scrollController = ScrollController();
  TextEditingController controller = TextEditingController();
  List<Map> messages = [];
  int guessedUserCount = 0;
  int _start = 60;
  Timer? _timer;
  var scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map> scoreboard = [];
  bool isTextInputReadOnly = false;
  int maxPoints = 0;
  String winner = "";
  bool isShowFinalLeaderboard = false;
  bool isWaitingLobby = false;
  List<Stroke> strokes = [];
  List<Stroke> undoStrokes = [];
  List<Stroke> redoStrokes = [];
  Stroke? currentStroke;
  Tool selectedTool = Tool.pencil;

  @override
  void initState() {
    super.initState();
    connect();
  }

  void undo() {
    if (strokes.isNotEmpty) {
      setState(() {
        undoStrokes.add(strokes.removeLast());
        redoStrokes.clear();
      });
    }
  }

  void redo() {
    if (undoStrokes.isNotEmpty) {
      setState(() {
        strokes.add(undoStrokes.removeLast());
      });
    }
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (time) {
      if (_start == 0) {
        _socket.emit('next-round', dataOfRoom['name'] ?? '');
        setState(() {
          _timer?.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void renderTextBlank(String text) {
    textBlankWidget.clear();
    for (int i = 0; i < text.length; i++) {
      textBlankWidget.add(const Text(
        '_',
        style: TextStyle(fontSize: 30),
      ));
    }
  }

  void connect() {
    _socket = IO.io(dotenv.env['SERVER_URL'], <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false
    });
    _socket.connect();

    if (widget.screenFrom == 'createRoom') {
      _socket.emit('create-game', widget.data);
    } else {
      _socket.emit('join-game', widget.data);
    }

    _socket.onConnect((data) {
      debugPrint('Connected');

      _socket.on('updateRoom', (roomData) {
        if (mounted) {
          debugPrint(roomData['word'] ?? 'No word');
          setState(() {
            renderTextBlank(roomData['word'] ?? '');
            dataOfRoom = roomData ?? {};
          });
          if (dataOfRoom['canJoin'] != true) {
            startTimer();
            setState(() {
              isWaitingLobby = false;
            });
          } else {
            setState(() {
              isWaitingLobby = true;
            });
          }

          scoreboard.clear();
          List players = dataOfRoom['players'] ?? [];
          for (var player in players) {
            setState(() {
              scoreboard.add({
                'username': player['nickname'] ?? 'Unknown',
                'points': player['points']?.toString() ?? '0'
              });
            });
          }
        }
      });

      _socket.on('points', (point) {
        if (mounted) {
          debugPrint('Point: $point');
          debugPrint('Point details: ${point['details']}');

          setState(() {
            if (point['details'] != null) {
              double xCoordinate =
                  (point['details']['dx'] as num?)?.toDouble() ?? 0.0;
              double yCoordinate =
                  (point['details']['dy'] as num?)?.toDouble() ?? 0.0;

              if (currentStroke == null ||
                  currentStroke!.tool != selectedTool) {
                currentStroke = Stroke(points: [], tool: selectedTool);
                strokes.add(currentStroke!);
              }

              currentStroke!.points.add(TouchPoints(
                points: Offset(xCoordinate, yCoordinate),
                paint: Paint()
                  ..strokeCap = strokeType
                  ..isAntiAlias = true
                  ..color = selectedColor.withOpacity(opacity)
                  ..strokeWidth = strokeWidth,
                tool: selectedTool,
              ));
            } else {
              currentStroke = null;
            }
          });
        }
      });

      _socket.on('msg', (messageData) {
        setState(() {
          messages.add(messageData);
          guessedUserCount = messageData['guessedUserCount'];
        });
        if (guessedUserCount == dataOfRoom['players'].length - 1) {
          _socket.emit('next-round', dataOfRoom['name']);
        }
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut);
      });

      _socket.on('next-round', (data) {
        if (mounted) {
          String oldWord = dataOfRoom['word'] ?? '';
          showDialog(
            context: context,
            builder: (context) {
              Future.delayed(const Duration(seconds: 3), () {
                setState(() {
                  renderTextBlank(data['word'] ?? '');
                  isTextInputReadOnly = false;
                  dataOfRoom = data ?? {};
                  guessedUserCount = 0;
                  _start = 60;
                  points.clear();
                });
                Navigator.of(context).pop();
                _timer?.cancel();
                startTimer();
              });
              return AlertDialog(
                title: const Text('Next Round is starting...'),
                content: Text('The word was $oldWord'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Next Round'),
                  ),
                ],
              );
            },
          );
        }
      });

      _socket.on('color-change', (color) {
        if (mounted) {
          debugPrint('Color: $color');
          setState(() {
            selectedColor = Color(int.parse(color, radix: 16));
          });
        }
      });

      _socket.on('stroke-width', (value) {
        if (mounted) {
          debugPrint('Stroke Width: $value');
          setState(() {
            strokeWidth = (value as num?)?.toDouble() ?? 2.0;
          });
        }
      });

      _socket.on('clear-screen', (data) {
        if (mounted) {
          setState(() {
            strokes.clear();
            undoStrokes.clear();
            redoStrokes.clear();
          });
        }
      });

      _socket.on('closeInput', (_) {
        _socket.emit('updateScore', widget.data['name'] ?? '');
        setState(() {
          isTextInputReadOnly = true;
        });
      });

      _socket.on('updateScore', (data) {
        if (mounted) {
          setState(() {
            scoreboard.clear();
            List players = data['players'] ?? [];
            for (var player in players) {
              setState(() {
                scoreboard.add({
                  'username': player['nickname'] ?? 'Unknown',
                  'points': player['points']?.toString() ?? '0'
                });
              });
            }
          });
        }
      });

      _socket.on("show-leaderboard", (roomPlayers) {
        scoreboard.clear();
        List players = roomPlayers ?? [];
        for (var player in players) {
          setState(() {
            scoreboard.add({
              'username': player['nickname'] ?? 'Unknown',
              'points': player['points']?.toString() ?? '0'
            });
            if (maxPoints < int.parse(scoreboard.last['points'] ?? '0')) {
              winner = scoreboard.last['username'] ?? '';
              maxPoints = int.parse(scoreboard.last['points'] ?? '0');
            }
          });
        }
        setState(() {
          _timer?.cancel();
          isShowFinalLeaderboard = true;
          disconnect();
        });
      });

      _socket.on('user-disconnected', (data) {
        List players = data['players'] ?? [];
        scoreboard.clear();
        for (var player in players) {
          setState(() {
            scoreboard.add({
              'username': player['nickname'] ?? 'Unknown',
              'points': player['points']?.toString() ?? '0'
            });
          });
        }
      });

      _socket.on(
        'notCorrectGame',
        (data) => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RoomSelectionScreen()),
          (route) => false,
        ),
      );
    });

    _socket.onDisconnect((_) => debugPrint('Connection Disconnection'));
    _socket.onError((error) {
      debugPrint('Socket Error: $error');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: $error'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    });
  }

  void disconnect() {
    _socket.disconnect();
  }

  @override
  void dispose() {
    _socket.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    void selectColor() {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Select Color'),
                content: SingleChildScrollView(
                  child: BlockPicker(
                      pickerColor: selectedColor,
                      onColorChanged: (color) {
                        String colorString = color.toString();
                        String valueString =
                            colorString.split('(0x')[1].split(')')[0];
                        debugPrint(colorString);
                        debugPrint(valueString);
                        Map<String, dynamic> map = {
                          'color': valueString,
                          'roomName': dataOfRoom['name']
                        };
                        _socket.emit('color-change', map);
                      }),
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Close'))
                ],
              ));
    }

    return Scaffold(
        resizeToAvoidBottomInset: false,
        key: scaffoldKey,
        drawer: PlayerScore(scoreboard),
        backgroundColor: Colors.white,
        body: dataOfRoom['canJoin'] != true
            ? !isShowFinalLeaderboard
                ? Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: height * 0.50,
                            width: width,
                            child: GestureDetector(
                              onPanUpdate: dataOfRoom['turn']['nickname'] ==
                                      widget.data['nickname']
                                  ? (details) {
                                      _socket.emit('paint', {
                                        'details': {
                                          'dx': details.localPosition.dx,
                                          'dy': details.localPosition.dy,
                                        },
                                        'roomName': widget.data['name'],
                                        'tool': selectedTool
                                            .toString()
                                            .split('.')
                                            .last,
                                      });
                                    }
                                  : null,
                              onPanStart: dataOfRoom['turn']['nickname'] ==
                                      widget.data['nickname']
                                  ? (details) {
                                      setState(() {
                                        currentStroke = Stroke(
                                            points: [], tool: selectedTool);
                                        strokes.add(currentStroke!);
                                      });
                                      _socket.emit('paint', {
                                        'details': {
                                          'dx': details.localPosition.dx,
                                          'dy': details.localPosition.dy,
                                        },
                                        'roomName': widget.data['name'],
                                        'tool': selectedTool
                                            .toString()
                                            .split('.')
                                            .last,
                                      });
                                    }
                                  : null,
                              onPanEnd: dataOfRoom['turn']['nickname'] ==
                                      widget.data['nickname']
                                  ? (details) {
                                      _socket.emit('paint', {
                                        'details': null,
                                        'roomName': widget.data['name'],
                                      });
                                      setState(() {
                                        currentStroke = null;
                                      });
                                    }
                                  : null,
                              child: SizedBox.expand(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      size: Size.infinite,
                                      painter: MyCustomPainter(
                                        pointsList: strokes
                                            .expand((s) => s.points)
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              if (dataOfRoom['turn']['nickname'] ==
                                  widget.data['nickname'])
                                IconButton(
                                  icon: Icon(
                                    Icons.color_lens,
                                    color: selectedColor,
                                  ),
                                  onPressed: () {
                                    selectColor();
                                  },
                                ),
                              if (dataOfRoom['turn']['nickname'] ==
                                  widget.data['nickname'])
                                Expanded(
                                  child: Slider(
                                    label: 'Strokewidth $strokeWidth',
                                    activeColor: selectedColor,
                                    min: 1.0,
                                    max: 10,
                                    value: strokeWidth,
                                    onChanged: (double value) {
                                      Map<String, dynamic> map = {
                                        'value': value,
                                        'roomName': dataOfRoom['name']
                                      };
                                      _socket.emit('stroke-width', map);
                                    },
                                  ),
                                ),
                              if (dataOfRoom['turn']['nickname'] ==
                                  widget.data['nickname'])
                                IconButton(
                                  onPressed: () {
                                    _socket.emit(
                                        'clean-screen', dataOfRoom['name']);
                                  },
                                  icon: Icon(
                                    Icons.layers_clear_rounded,
                                    color: selectedColor,
                                  ),
                                ),
                            ],
                          ),
                          dataOfRoom['turn']['nickname'] !=
                                  widget.data['nickname']
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: textBlankWidget,
                                )
                              : Center(
                                  child: Text(
                                    dataOfRoom['word'],
                                    style: const TextStyle(fontSize: 30),
                                  ),
                                ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.32,
                            child: ListView.builder(
                              shrinkWrap: true,
                              controller: _scrollController,
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                var msg = messages[index].values;
                                bool isCurrentUser =
                                    msg.elementAt(0) == widget.data['nickname'];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 10),
                                  child: Align(
                                    alignment: isCurrentUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Card(
                                      color: isCurrentUser
                                          ? Colors.blueAccent
                                          : Colors.grey[200],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(
                                              isCurrentUser ? 16 : 0),
                                          topRight: Radius.circular(
                                              isCurrentUser ? 0 : 16),
                                          bottomLeft: const Radius.circular(16),
                                          bottomRight:
                                              const Radius.circular(16),
                                        ),
                                      ),
                                      elevation: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Message content
                                            Text(
                                              msg.elementAt(0).toString(),
                                              style: TextStyle(
                                                color: isCurrentUser
                                                    ? Colors.white70
                                                    : Colors.black54,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              msg.elementAt(1).toString(),
                                              style: TextStyle(
                                                color: isCurrentUser
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      if (dataOfRoom['turn']['nickname'] ==
                          widget.data['nickname'])
                        Positioned(
                          top: 125,
                          right: 0,
                          child: Column(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.create,
                                  color: selectedTool == Tool.pencil
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedTool = Tool.pencil;
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.format_paint,
                                  color: selectedTool == Tool.paintBucket
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedTool = Tool.paintBucket;
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.cleaning_services_rounded,
                                  color: selectedTool == Tool.eraser
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedTool = Tool.eraser;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.undo,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  undo();
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.redo,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  redo();
                                },
                              ),
                            ],
                          ),
                        ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          child: TextField(
                            readOnly: isTextInputReadOnly,
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                Map<String, dynamic> map = {
                                  'msg': value.trim(),
                                  'username': widget.data['nickname'],
                                  'roomName': widget.data['name'],
                                  'word': dataOfRoom['word'],
                                  'guessedUserCount': guessedUserCount,
                                  'totalTime': 60,
                                  'timeTaken': 60 - _start
                                };
                                _socket.emit('msg', map);
                                controller.clear();
                              }
                            },
                            autocorrect: false,
                            onTapOutside: (event) =>
                                FocusManager.instance.primaryFocus!.unfocus(),
                            controller: controller,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Colors.transparent),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.transparent),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              fillColor: const Color(0xffF5F6FA),
                              filled: true,
                              hintText: 'Guess the word...',
                              hintStyle: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w400),
                            ),
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                      ),
                      SafeArea(
                        child: IconButton(
                          icon: const Icon(Icons.menu, color: Colors.black),
                          onPressed: () =>
                              scaffoldKey.currentState!.openDrawer(),
                        ),
                      ),
                    ],
                  )
                : FinalLeaderboard(scoreboard, winner)
            : WaitingLobbyScreen(
                occupancy: dataOfRoom['occupancy'],
                noOfPlayers: dataOfRoom['players'].length,
                lobbyName: dataOfRoom['name'],
                players: dataOfRoom['players'],
              ),
        floatingActionButtonLocation: !isWaitingLobby
            ? FloatingActionButtonLocation.miniEndTop
            : FloatingActionButtonLocation.endFloat,
        floatingActionButton: !isShowFinalLeaderboard
            ? Container(
                margin: const EdgeInsets.only(bottom: 40),
                child: FloatingActionButton(
                  tooltip: 'Timer',
                  onPressed: () {},
                  elevation: 7,
                  backgroundColor: Colors.white,
                  child: Text(
                    '$_start',
                    style: const TextStyle(color: Colors.black, fontSize: 22),
                  ),
                ),
              )
            : Container());
  }
}
