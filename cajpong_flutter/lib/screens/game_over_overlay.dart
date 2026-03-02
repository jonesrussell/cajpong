import 'package:flutter/material.dart';
import 'package:cajpong_flutter/game/pong_game.dart';
import 'package:cajpong_flutter/models/game_state.dart';
import 'package:cajpong_flutter/screens/pong_button.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final winner = game.winner;
    final message = game.lastGameWasOnline
        ? (winner == null
            ? 'Opponent disconnected'
            : winner == Side.left
                ? 'Left wins!'
                : 'Right wins!')
        : 'Campaign over';
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
              if (!game.lastGameWasOnline) ...[
                SizedBox(height: d.scale * 14),
                Text(
                  '${game.campaignStageName}  |  Score ${game.campaignScore}  |  Best ${game.campaignBestScore}  |  Level ${game.campaignLevel}',
                  style: TextStyle(
                      color: const Color(0xFFC8D2E4), fontSize: d.scale * 20),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: d.scale * 32),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PongButton(
                    label: game.lastGameWasOnline
                        ? 'Find new match'
                        : 'Retry campaign',
                    onTap: () => game.lastGameWasOnline
                        ? game.showMatchmaking()
                        : game.startLocal(),
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
