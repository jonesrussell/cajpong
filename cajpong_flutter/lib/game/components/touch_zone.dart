import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// Invisible half-screen zone for drag input. Left or right half.
/// Reports target Y (game space) via callback; game moves paddle toward it.
class TouchZone extends PositionComponent with DragCallbacks {
  TouchZone({required this.isLeft, required this.onTargetY});

  final bool isLeft;
  final void Function(double? y) onTargetY;

  @override
  void onDragStart(DragStartEvent event) {
    onTargetY(event.localPosition.y);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    onTargetY(event.localEndPosition.y);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    onTargetY(null);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    onTargetY(null);
  }
}
