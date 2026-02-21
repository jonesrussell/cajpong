import 'package:flutter_test/flutter_test.dart';
import 'package:cajpong_flutter/game/game_loop.dart';
import 'package:cajpong_flutter/models/game_state.dart';
import 'package:cajpong_flutter/utils/constants.dart';

void main() {
  test('getWinner and createInitialState', () {
    expect(getWinner(11, 5), equals(Side.left));
    expect(getWinner(5, 11), equals(Side.right));
    expect(getWinner(10, 10), isNull);
    final d = GameDimensions(refWidth, refHeight);
    final state = createInitialState(d, 1);
    expect(state.serving, isTrue);
    expect(state.scoreLeft, 0);
    expect(state.ballX, 400.0);
  });
}
