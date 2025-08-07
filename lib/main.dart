import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const LaunchPadApp());
}

const int numRows = 7;
const List<Color> activeCube = [Colors.white, Color(0xFFE8E8E8)];

class CubeColumn {
  final String name;
  final List<Color> defaultGradient;
  final List<Color> shadowColors;
  final int soundOffset;

  CubeColumn({
    required this.name,
    required this.defaultGradient,
    required this.shadowColors,
    required this.soundOffset,
  });
}

class LaunchPadApp extends StatefulWidget {
  const LaunchPadApp({super.key});

  @override
  State<LaunchPadApp> createState() => _LaunchPadAppState();
}

class _LaunchPadAppState extends State<LaunchPadApp>
    with TickerProviderStateMixin {
  final AudioPlayer player = AudioPlayer();
  late List<List<AnimationController>> animationControllers;
  late List<List<Animation<double>>> scaleAnimations;
  late List<List<Animation<double>>> glowAnimations;

  final List<CubeColumn> columns = [
    CubeColumn(
      name: 'BASS',
      defaultGradient: [Color(0xFF9C27B0), Color(0xFF673AB7)],
      shadowColors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
      soundOffset: 1,
    ),
    CubeColumn(
      name: 'LEAD',
      defaultGradient: [Color(0xFFFF9800), Color(0xFFE91E63)],
      shadowColors: [Color(0xFFFF9800), Color(0xFFE91E63)],
      soundOffset: 15,
    ),
    CubeColumn(
      name: 'SYNTH',
      defaultGradient: [Color(0xFF00BCD4), Color(0xFF2196F3)],
      shadowColors: [Color(0xFF00BCD4), Color(0xFF2196F3)],
      soundOffset: 18,
    ),
    CubeColumn(
      name: 'DRUMS',
      defaultGradient: [Color(0xFF8BC34A), Color(0xFF4CAF50)],
      shadowColors: [Color(0xFF8BC34A), Color(0xFF4CAF50)],
      soundOffset: 22,
    ),
  ];

  late List<List<List<Color>>> cubeColors;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    cubeColors = columns
        .map((col) => List.generate(numRows, (_) => col.defaultGradient))
        .toList();

    // Initialize animation controllers
    animationControllers = List.generate(
      columns.length,
      (col) => List.generate(
        numRows,
        (row) => AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: this,
        ),
      ),
    );

    // Initialize animations
    scaleAnimations = List.generate(
      columns.length,
      (col) => List.generate(
        numRows,
        (row) => Tween<double>(begin: 1.0, end: 0.95).animate(
          CurvedAnimation(
            parent: animationControllers[col][row],
            curve: Curves.elasticOut,
          ),
        ),
      ),
    );

    glowAnimations = List.generate(
      columns.length,
      (col) => List.generate(
        numRows,
        (row) => Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationControllers[col][row],
            curve: Curves.easeInOut,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    player.dispose();
    for (var columnControllers in animationControllers) {
      for (var controller in columnControllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> playSound(int soundIndex) async {
    try {
      await player.stop();
      await player.play(AssetSource('$soundIndex.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> handleTap(int columnIndex, int rowIndex) async {
    // Haptic feedback
    HapticFeedback.lightImpact();

    final defaultGradient = columns[columnIndex].defaultGradient;
    final soundIndex = columns[columnIndex].soundOffset + rowIndex;

    // Start animation
    animationControllers[columnIndex][rowIndex].forward();

    // Play sound
    await playSound(soundIndex);

    setState(() {
      cubeColors[columnIndex][rowIndex] = activeCube;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      cubeColors[columnIndex][rowIndex] = defaultGradient;
    });

    // Reset animation
    animationControllers[columnIndex][rowIndex].reverse();
  }

  Widget buildColumn(int columnIndex, double tileWidth, double tileHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Column label
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            columns[columnIndex].name,
            style: GoogleFonts.jetBrainsMono(
              color: columns[columnIndex].defaultGradient[0],
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        // Sound pads
        ...List.generate(numRows, (rowIndex) {
          return AnimatedBuilder(
            animation: Listenable.merge([
              scaleAnimations[columnIndex][rowIndex],
              glowAnimations[columnIndex][rowIndex],
            ]),
            builder: (context, child) {
              return Transform.scale(
                scale: scaleAnimations[columnIndex][rowIndex].value,
                child: GestureDetector(
                  onTap: () => handleTap(columnIndex, rowIndex),
                  child: Container(
                    width: tileWidth,
                    height: tileHeight,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: cubeColors[columnIndex][rowIndex],
                        stops: const [0.3, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: columns[columnIndex]
                              .shadowColors[0]
                              .withOpacity(0.3 +
                                  (glowAnimations[columnIndex][rowIndex].value *
                                      0.4)),
                          blurRadius: 8 +
                              (glowAnimations[columnIndex][rowIndex].value *
                                  12),
                          spreadRadius: 1 +
                              (glowAnimations[columnIndex][rowIndex].value * 2),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${rowIndex + 1}',
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double tileWidth = (screenSize.width - 40) / (columns.length + 1);
    final double tileHeight = (screenSize.height - 200) / (numRows + 2);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.music_note, color: Colors.blue, size: 28),
              const SizedBox(width: 8),
              Text(
                'LaunchPad Studio',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A0A0A),
                  const Color(0xFF1A1A1A).withOpacity(0.8),
                  const Color(0xFF0A0A0A),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  columns.length,
                  (index) => buildColumn(index, tileWidth, tileHeight),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🎵 Tap the pads to create music',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
