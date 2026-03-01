# Paddle Visibility Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make paddles visible during mobile touch input by adding aim lines and offset touch.

**Architecture:** Two independent features composed together. TouchZone applies a Y offset before reporting target position. A new AimLine component renders a fading horizontal line from paddle face inward, toggled visible/hidden by touch callbacks. No physics or server changes.

**Tech Stack:** Flutter/Flame (Dart), existing component architecture.

---

### Task 1: Add touch offset constant

**Files:**
- Modify: `cajpong_flutter/lib/utils/constants.dart:28-29`

**Step 1: Add constant**

Add after `ballPaddleSeparationRef`:

```dart
const double touchOffsetYRef = 60;
```

Add to `GameDimensions` constructor body (after `buttonHeight` line):

```dart
touchOffsetY = touchOffsetYRef * scaleY;
```

Add to `GameDimensions` fields (after `buttonHeight`):

```dart
late final double touchOffsetY;
```

**Step 2: Run analyze**

Run: `cd cajpong_flutter && flutter analyze`
Expected: No issues found

**Step 3: Commit**

```
feat: add touchOffsetY constant for mobile input offset
```

---

### Task 2: Apply offset in TouchZone callbacks

**Files:**
- Modify: `cajpong_flutter/lib/game/components/touch_zone.dart`

**Step 1: Add offset parameter and apply it**

TouchZone needs to accept an offset and subtract it from the reported Y. Also needs an `onDragActive` callback to signal when touch is happening.

```dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// Invisible half-screen zone for drag input. Left or right half.
/// Reports target Y (game space) via callback; game moves paddle toward it.
/// [touchOffsetY] shifts the target upward so the paddle clears the thumb.
class TouchZone extends PositionComponent with DragCallbacks {
  TouchZone({
    required this.isLeft,
    required this.onTargetY,
    this.onDragActive,
    this.touchOffsetY = 0,
  });

  final bool isLeft;
  final void Function(double? y) onTargetY;
  final void Function(bool active)? onDragActive;
  final double touchOffsetY;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    onDragActive?.call(true);
    onTargetY(event.localPosition.y - touchOffsetY);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    onTargetY(event.localEndPosition.y - touchOffsetY);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    onDragActive?.call(false);
    onTargetY(null);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    onDragActive?.call(false);
    onTargetY(null);
  }
}
```

**Step 2: Run analyze**

Run: `cd cajpong_flutter && flutter analyze`
Expected: No issues found

**Step 3: Commit**

```
feat: add touch offset and drag-active callback to TouchZone
```

---

### Task 3: Create AimLine component

**Files:**
- Create: `cajpong_flutter/lib/game/components/aim_line.dart`

**Step 1: Create the component**

```dart
import 'dart:ui';

import 'package:flame/components.dart';

/// Horizontal aim line extending from a paddle face toward center field.
/// Shows paddle Y position when the player's thumb obscures the paddle.
class AimLine extends PositionComponent {
  AimLine({required this.isLeft});

  final bool isLeft;

  /// Call to show/hide when touch starts/ends.
  bool visible = false;

  /// Line length and thickness are set by the game via [configure].
  double lineLength = 0;
  double lineThickness = 1;

  /// Configure dimensions from GameDimensions. Called on layout.
  void configure({
    required double length,
    required double thickness,
  }) {
    lineLength = length;
    lineThickness = thickness;
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;

    final paint = Paint()
      ..strokeWidth = lineThickness;

    // Draw the line as a gradient from 20% white to fully transparent.
    final startX = isLeft ? 0.0 : lineLength;
    final endX = isLeft ? lineLength : 0.0;
    final y = size.y / 2;

    paint.shader = Gradient.linear(
      Offset(startX, y),
      Offset(endX, y),
      [const Color(0x33FFFFFF), const Color(0x00FFFFFF)],
    );

    canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
  }
}
```

**Step 2: Run analyze**

Run: `cd cajpong_flutter && flutter analyze`
Expected: No issues found

**Step 3: Commit**

```
feat: add AimLine component for paddle position indicator
```

---

### Task 4: Wire AimLine and offset into PongGame

**Files:**
- Modify: `cajpong_flutter/lib/game/pong_game.dart`

**Step 1: Add imports and fields**

Add import:

```dart
import 'package:cajpong_flutter/game/components/aim_line.dart';
```

Add fields after `rightTouchZone`:

```dart
late AimLine leftAimLine;
late AimLine rightAimLine;
```

**Step 2: Create aim lines in _createComponents**

Add after `add(rightTouchZone);`:

```dart
leftAimLine = AimLine(isLeft: true)..anchor = Anchor.centerLeft;
rightAimLine = AimLine(isLeft: false)..anchor = Anchor.centerRight;
add(leftAimLine);
add(rightAimLine);
```

**Step 3: Update TouchZone creation to pass offset and drag callback**

Replace the leftTouchZone creation block:

```dart
leftTouchZone = TouchZone(
  isLeft: true,
  touchOffsetY: d.touchOffsetY,
  onTargetY: (y) => _leftTargetY = y?.clamp(minY, maxY).toDouble(),
  onDragActive: (active) => leftAimLine.visible = active,
)
  ..anchor = Anchor.topLeft;
rightTouchZone = TouchZone(
  isLeft: false,
  touchOffsetY: d.touchOffsetY,
  onTargetY: (y) => _rightTargetY = y?.clamp(minY, maxY).toDouble(),
  onDragActive: (active) => rightAimLine.visible = active,
)
  ..anchor = Anchor.topLeft;
```

**Step 4: Layout aim lines in _layoutFromDimensions**

Add after the rightTouchZone layout block (after line setting `rightTouchZone.size`):

```dart
final aimLineLength = d.width * 0.4;
final aimLineThickness = 1.0 * d.scale;
leftAimLine.configure(length: aimLineLength, thickness: aimLineThickness);
leftAimLine.size.setValues(aimLineLength, d.paddleHeight);
leftAimLine.position.setValues(d.paddlePadding + d.halfPaddle, d.height / 2);

rightAimLine.configure(length: aimLineLength, thickness: aimLineThickness);
rightAimLine.size.setValues(aimLineLength, d.paddleHeight);
rightAimLine.position.setValues(d.width - d.paddlePadding - d.halfPaddle, d.height / 2);
```

**Step 5: Update aim line Y in _applyState**

The aim lines need to track paddle Y. Add at the end of `_applyState`, after `scoreText.text = ...`:

```dart
leftAimLine.position.y = leftPaddle.position.y;
rightAimLine.position.y = rightPaddle.position.y;
```

**Step 6: Run analyze**

Run: `cd cajpong_flutter && flutter analyze`
Expected: No issues found

**Step 7: Run tests**

Run: `cd cajpong_flutter && flutter test`
Expected: All tests passed

**Step 8: Commit**

```
feat: wire aim lines and touch offset into PongGame
```

---

### Task 5: Manual smoke test

**Step 1: Run on desktop**

Run: `cd cajpong_flutter && flutter run -d linux`

Verify:
- Keyboard play works identically (W/S, arrows) -- no aim lines visible
- Game plays normally, no visual artifacts

**Step 2: Run on web/Chrome**

Run: `cd cajpong_flutter && flutter run -d chrome`

Verify:
- Touch/click drag shows aim line extending from paddle
- Paddle position is offset above the touch point
- Aim line disappears when touch ends
- Aim line tracks paddle Y during drag
- Game over and menu transitions still work

**Step 3: Commit all if any fixups needed**

```
fix: address smoke test findings (if any)
```
