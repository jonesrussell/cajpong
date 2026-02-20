import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:cajpong_flutter/models/game_state.dart';

/// Wraps Socket.IO client for CajPong multiplayer. No networking inside game components.
class PongSocketService {
  PongSocketService({required this.serverUrl});

  final String serverUrl;
  io.Socket? _socket;
  final StreamController<GameState> _gameStateController =
      StreamController<GameState>.broadcast();
  final StreamController<void> _disconnectController =
      StreamController<void>.broadcast();

  Stream<GameState> get gameStateStream => _gameStateController.stream;
  Stream<void> get onDisconnect => _disconnectController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null) return;
    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .build(),
    );
    _socket!.onConnect((_) {});
    _socket!.onConnectError((err) => _disconnectController.add(null));
    _socket!.onDisconnect((_) => _disconnectController.add(null));
    _socket!.on('opponent_left', (_) => _disconnectController.add(null));
  }

  /// Emit find_match and return a Future that completes with MatchedPayload when matched.
  Future<MatchedPayload> findMatch() {
    connect();
    final completer = Completer<MatchedPayload>();
    void onMatched(dynamic data) {
      _socket!.off('matched', onMatched);
      if (!completer.isCompleted) {
        final map = Map<String, dynamic>.from(data as Map);
        completer.complete(MatchedPayload.fromJson(map));
      }
    }
    _socket!.on('matched', onMatched);
    _socket!.emit('find_match');
    if (_socket!.connected) {
      // already connected
    } else {
      _socket!.once('connect', (_) {});
    }
    return completer.future;
  }

  /// Call after findMatch() completes to start receiving game state.
  void startGameStateListener() {
    _socket?.off('game_state');
    _socket?.on('game_state', (dynamic data) {
      final map = data as Map;
      final stateMap = map['state'] as Map<String, dynamic>?;
      if (stateMap != null) {
        _gameStateController.add(GameState.fromJson(stateMap));
      }
    });
  }

  void sendInput({required bool up, required bool down}) {
    _socket?.emit('input', {'up': up, 'down': down});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _gameStateController.close();
    _disconnectController.close();
  }
}
