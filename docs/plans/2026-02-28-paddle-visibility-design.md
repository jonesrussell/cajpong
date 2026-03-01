# Paddle Visibility on Mobile: Aim Lines + Offset Touch

## Problem

On mobile, the player's thumb covers the paddle during touch input, making it impossible to see paddle position in both local and online modes.

## Solution

Combine two techniques: aim lines (visual indicator) and offset touch (input adjustment).

### Aim Lines

Each paddle gets a thin horizontal line extending from its face toward the center of the field.

- 1px (scaled) solid line at the paddle's vertical center, extending ~40% of field width inward
- White at ~20% opacity, fading out via gradient alpha at the far end
- Only shown during active touch input (appears on drag start, disappears on drag end)
- Not shown during keyboard input
- Pure visual aid, no collision or physics changes

### Offset Touch

The paddle is positioned 60px above (in reference 600px space) the actual finger position during drag input.

- Offset is always upward in screen space (thumbs approach from bottom edge)
- Applied before clamping to paddle bounds, so paddle stops at walls as usual
- Only affects touch drag input; keyboard input unchanged
- Server-side physics unchanged; client input mapping adjustment only

## Files Changed

- `cajpong_flutter/lib/game/components/touch_zone.dart` -- apply -60px offset to onTargetY callbacks
- `cajpong_flutter/lib/utils/constants.dart` -- add touchOffsetYRef = 60
- `cajpong_flutter/lib/game/components/aim_line.dart` -- new component, renders horizontal indicator line per paddle
- `cajpong_flutter/lib/game/pong_game.dart` -- add aim line components, toggle visibility on touch start/end

## Files Not Changed

- `game_loop.dart`, server game logic, online protocol -- zero physics/gameplay changes
- Keyboard input -- unaffected
