import 'package:flutter/material.dart';
import 'package:cajpong_flutter/game/pong_game.dart';
import 'package:cajpong_flutter/screens/pong_button.dart';

Widget buildMenuOverlay(BuildContext context, PongGame game) {
  final d = game.dimensions;
  return Container(
    color: const Color(0xFF111111),
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
            'Local  |  Online',
            style: TextStyle(color: Colors.white, fontSize: d.scale * 24),
          ),
          SizedBox(height: d.scale * 48),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PongButton(
                label: 'Local',
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
        ],
      ),
    ),
  );
}