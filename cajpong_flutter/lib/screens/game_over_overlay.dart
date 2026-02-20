import 'package:flutter/material.dart';
import 'package:cajpong_flutter/game/pong_game.dart';
import 'package:cajpong_flutter/models/game_state.dart';
import 'package:cajpong_flutter/utils/constants.dart';

Widget buildGameOverOverlay(BuildContext context, PongGame game) {
  return _GameOverOverlay(game: game);
}

class _GameOverOverlay extends StatefulWidget {
  const _GameOverOverlay({required this.game});

  final PongGame game;

  @override
  State<_GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<_GameOverOverlay> {
  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration(milliseconds: winDisplayDelayMs),
      () => widget.game.showMenu(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.game.winner;
    final message = winner == null
        ? 'Opponent disconnected'
        : winner == Side.left
            ? 'Left wins!'
            : 'Right wins!';
    return Container(
      color: Colors.black54,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 56),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
