import 'package:flutter/material.dart';
import 'package:cajpong_flutter/game/pong_game.dart';
import 'package:cajpong_flutter/models/game_state.dart';
import 'package:cajpong_flutter/screens/pong_button.dart';
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
    if (!widget.game.lastGameWasOnline) {
      Future.delayed(
        const Duration(milliseconds: winDisplayDelayMs),
        () => widget.game.showMenu(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final winner = game.winner;
    final message = winner == null
        ? 'Opponent disconnected'
        : winner == Side.left
            ? 'Left wins!'
            : 'Right wins!';
    final d = game.dimensions;
    final fontSize = d.scale * 56;

    if (game.lastGameWasOnline) {
      return Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: TextStyle(color: Colors.white, fontSize: fontSize),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: d.scale * 32),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PongButton(
                    label: 'Find new match',
                    onTap: () => game.showMatchmaking(),
                    width: d.buttonWidth,
                    height: d.buttonHeight,
                  ),
                  SizedBox(width: d.scale * 24),
                  PongButton(
                    label: 'Menu',
                    onTap: () => game.showMenu(),
                    width: d.buttonWidth,
                    height: d.buttonHeight,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black54,
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.white, fontSize: fontSize),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}