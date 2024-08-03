import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class GameScreen extends StatefulWidget {
  final int initialLevel;
  const GameScreen({Key? key, required this.initialLevel}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late int numRows;
  late int numColumns;
  late int totalPieces;
  List<List<int>> grid = [];
  Offset? selectedPiece;

  final AudioPlayer _audioPlayer = AudioPlayer();

  int currentLevel = 1;
  bool showingCongratulationDialog = false;

  late AnimationController _controller;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    currentLevel = widget.initialLevel;
    setupLevel();
    initializeGrid();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _sizeAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
    _audioPlayer.dispose();
  }

  void moveToNextLevel() {
    setState(() {
      currentLevel++;
      setupLevel();
      initializeGrid();
      showingCongratulationDialog = false;
    });
  }

  void setupLevel() {
    switch (currentLevel) {
      case 1:
        numRows = 4;
        numColumns = 4;
        totalPieces = numRows * numColumns;
        break;
      case 2:
        numRows = 8;
        numColumns = 4;
        totalPieces = numRows * numColumns;
        break;
      case 3:
        numRows = 8;
        numColumns = 6;
        totalPieces = numRows * numColumns;
        break;
      case 4:
        numRows = 12;
        numColumns = 6;
        totalPieces = numRows * numColumns;
        break;
      case 5:
        numRows = 14;
        numColumns = 6;
        totalPieces = numRows * numColumns;
        break;
      default:
        numRows = 16;
        numColumns = 6;
        totalPieces = numRows * numColumns;
        break;
    }
  }

  void initializeGrid() {
    List<int> pieces = [];

    // Number of colors is equal to the number of columns
    int numColors = numColumns;
    int piecesPerColor = totalPieces ~/ numColors;

    // Generate pieces with balanced colors
    for (int color = 0; color < numColors; color++) {
      pieces.addAll(List.generate(piecesPerColor, (index) => color));
    }

    // Shuffle the pieces randomly
    pieces.shuffle(Random());

    // Populate the grid with shuffled pieces
    grid = List.generate(numRows, (row) {
      return List.generate(numColumns, (col) {
        return pieces[row * numColumns + col];
      });
    });
  }

  void swapPieces(int row1, int col1, int row2, int col2) {
    _playSound('sounds/tone.mp3');
    setState(() {
      int temp = grid[row1][col1];
      grid[row1][col1] = grid[row2][col2];
      grid[row2][col2] = temp;
    });
  }

  bool checkArrangement() {
    for (int col = 0; col < numColumns; col++) {
      int color = grid[0][col];
      for (int row = 1; row < numRows; row++) {
        if (grid[row][col] != color) {
          return false;
        }
      }
    }

    if (!showingCongratulationDialog) {
      showingCongratulationDialog = true;
      showCustomDialog(context, currentLevel, moveToNextLevel, initializeGrid);
    }

    return true;
  }

  void onPieceTap(int row, int col) {
    _playSound('sounds/Zap.mp3');

    _controller.forward(from: 0); // Start the size animation
    if (selectedPiece == null) {
      setState(() {
        selectedPiece = Offset(row.toDouble(), col.toDouble());
      });
    } else {
      int selectedRow = selectedPiece!.dx.toInt();
      int selectedCol = selectedPiece!.dy.toInt();

      // Allow only adjacent swaps
      if ((selectedRow - row).abs() + (selectedCol - col).abs() == 1) {
        swapPieces(selectedRow, selectedCol, row, col);
        checkArrangement();
      }
      setState(() {
        selectedPiece = null;
      });
    }
  }

  void showCustomDialog(BuildContext context, int currentLevel, Function moveToNextLevel, Function initializeGrid) {
    _playSound('win.mp3');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Column(
            children: [
              Image.asset(
                'assets/con.png',
                height: 50,
              ),
              const SizedBox(height: 10),
              const Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          content: const Text(
            'You have arranged all pieces correctly!',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      initializeGrid(); // Reset the grid
                      selectedPiece = null; // Clear the selected piece
                      showingCongratulationDialog = false; // Reset dialog state
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.red,
                    minimumSize: const Size(100, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      if (currentLevel < 7) {
                        moveToNextLevel();
                      } else {
                        // Handle game completion or next steps
                      }
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.green,
                    minimumSize: const Size(100, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Next Level',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/game2.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              // Top level indicator positioned slightly below the top
              Container(
                padding: const EdgeInsets.only(top: 50, left: 8, right: 8),
                child: Column(
                  children: [
                    Text(
                      'Level $currentLevel',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // Progress bar indicating the level
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: currentLevel / 7,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              // Centered box containing the game pieces
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.cyan.withOpacity(0.3),
                    child: GridView.builder(
                      shrinkWrap: true,
                      itemCount: totalPieces,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: numColumns,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        int row = index ~/ numColumns;
                        int col = index % numColumns;
                        int piece = grid[row][col];
                        bool isSelected = selectedPiece != null &&
                            selectedPiece!.dx.toInt() == row &&
                            selectedPiece!.dy.toInt() == col;

                        return AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            double scale = isSelected ? _sizeAnimation.value : 1.0;
                            return Transform.scale(
                              scale: scale,
                              child: GestureDetector(
                                onTap: () => onPieceTap(row, col),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.primaries[piece % Colors.primaries.length],
                                    border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: isSelected ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.8),
                                        spreadRadius: 3,
                                        blurRadius: 10,
                                      ),
                                    ] : [
                                      const BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _playSound(String soundFile) async {
    try {
      await _audioPlayer.play(AssetSource(soundFile));
    } catch (e) {
      if (kDebugMode) {
        print("Error playing sound: $e");
      }
    }
  }
}
