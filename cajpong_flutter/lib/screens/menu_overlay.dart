import 'package:flutter/material.dart';
import 'package:cajpong_flutter/game/pong_game.dart';
import 'package:cajpong_flutter/screens/pong_button.dart';

Widget buildMenuOverlay(BuildContext context, PongGame game) {
  final d = game.dimensions;
  final paddleLabel = game.paddleSkin.name;
  final ballLabel = game.ballSkin.name;
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF101621), Color(0xFF18112C), Color(0xFF10282A)],
      ),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CajPong',
            style: TextStyle(
              color: Colors.white,
              fontSize: d.scale * 64,
            ),
          ),
          SizedBox(height: d.scale * 24),
          Text(
            'Campaign (2-thumb survival)  |  Online duel',
            style: TextStyle(color: Colors.white, fontSize: d.scale * 24),
          ),
          SizedBox(height: d.scale * 12),
          Text(
            'Best campaign score: ${game.campaignBestScore}',
            style: TextStyle(
                color: const Color(0xFFD0D7E2), fontSize: d.scale * 18),
          ),
          SizedBox(height: d.scale * 48),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PongButton(
                label: 'Campaign',
                onTap: () => game.startLocal(),
                width: d.buttonWidth,
                height: d.buttonHeight,
              ),
              SizedBox(width: d.scale * 40),
              PongButton(
                label: 'Online',
                onTap: () => game.showMatchmaking(),
                width: d.buttonWidth,
                height: d.buttonHeight,
              ),
            ],
          ),
          SizedBox(height: d.scale * 32),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PongButton(
                label: 'Paddle: $paddleLabel',
                onTap: () => game.cyclePaddleSkin(),
                width: d.buttonWidth * 1.35,
                height: d.buttonHeight,
              ),
              SizedBox(width: d.scale * 16),
              PongButton(
                label: 'Ball: $ballLabel',
                onTap: () => game.cycleBallSkin(),
                width: d.buttonWidth * 1.15,
                height: d.buttonHeight,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
