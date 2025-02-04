import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';

import 'components/button.dart';
import 'components/empy_board.dart';
import 'components/score_board.dart';
import 'components/tile_board.dart';
import 'managers/board.dart';

class Game extends ConsumerStatefulWidget {
  const Game({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GameState();
}

class _GameState extends ConsumerState<Game>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  // The controller used to move the tiles
  late final AnimationController _moveController = AnimationController(
    duration: const Duration(milliseconds: 100),
    vsync: this,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(boardManager.notifier).merge();
        _scaleController.forward(from: 0.0);
      }
    });

  // The curve animation for the move animation controller
  late final CurvedAnimation _moveAnimation = CurvedAnimation(
    parent: _moveController,
    curve: Curves.easeInOut,
  );

  // The controller used to show a popup effect when the tiles get merged
  late final AnimationController _scaleController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (ref.read(boardManager.notifier).endRound()) {
          _moveController.forward(from: 0.0);
        }
      }
    });

  // The curve animation for the scale animation controller
  late final CurvedAnimation _scaleAnimation = CurvedAnimation(
    parent: _scaleController,
    curve: Curves.easeInOut,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;

    return RawKeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKey: (RawKeyEvent event) {
        if (ref.read(boardManager.notifier).onKey(event)) {
          _moveController.forward(from: 0.0);
        }
      },
      child: SwipeDetector(
        onSwipe: (direction, offset) {
          if (ref.read(boardManager.notifier).move(direction)) {
            _moveController.forward(from: 0.0);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 156, 155, 136),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.numbers, // Number icon
                  size: 32.0,
                  color: Colors.white,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Add numbers',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isPortrait ? 32.0 : 28.0, // Dynamic font size based on orientation
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.read(boardManager.notifier).newGame();
                },
              ),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 255, 236, 153),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ScoreBoard(),
                    Row(
                      children: [
                        ButtonWidget(
                          icon: Icons.undo,
                          onPressed: () {
                            ref.read(boardManager.notifier).undo();
                          },
                        ),
                        const SizedBox(width: 16.0),
                        ButtonWidget(
                          icon: Icons.refresh,
                          onPressed: () {
                            ref.read(boardManager.notifier).newGame();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32.0),
              Expanded(  // Expanded to take up available space between the app bar and footer
                child: Center(
                  child: Stack(
                    children: [
                      const EmptyBoardWidget(),
                      TileBoardWidget(
                        moveAnimation: _moveAnimation,
                        scaleAnimation: _scaleAnimation,
                      ),
                    ],
                  ),
                ),
              ),
              // Footer with Spacer to keep it at the bottom
              Container(
                padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.05, vertical: 12.0), // Adaptive padding based on screen width
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 156, 155, 136),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.filter_9_plus,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8.0),
                    const Text(
                      'Game Instructions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // Handle settings
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      ref.read(boardManager.notifier).save();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _moveAnimation.dispose();
    _scaleAnimation.dispose();
    _moveController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}
