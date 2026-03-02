import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:cajpong_flutter/game/pong_game.dart';
import 'package:cajpong_flutter/screens/game_over_overlay.dart';
import 'package:cajpong_flutter/screens/matchmaking_overlay.dart';
import 'package:cajpong_flutter/screens/menu_overlay.dart';
import 'package:cajpong_flutter/services/pong_socket_service.dart';

const _serverUrl = String.fromEnvironment(
  'SERVER_URL',
  defaultValue: 'http://localhost:3000',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  runApp(const CajPongApp());
}

class CajPongApp extends StatelessWidget {
  const CajPongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CajPong',
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: GameWidget(
          game: PongGame(
            socketService: PongSocketService(serverUrl: _serverUrl),
          ),
          overlayBuilderMap: {
            'menu': (context, game) =>
                buildMenuOverlay(context, game as PongGame),
            'matchmaking': (context, game) =>
                buildMatchmakingOverlay(context, game as PongGame),
            'game_over': (context, game) =>
                buildGameOverOverlay(context, game as PongGame),
          },
        ),
      ),
    );
  }
}
