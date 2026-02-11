import { describe, it, expect } from 'vitest'
import {
  WIDTH,
  HEIGHT,
  PADDLE_WIDTH,
  PADDLE_HEIGHT,
  PADDLE_PADDING,
  PADDLE_SPEED,
  PADDLE_CLAMP_MARGIN,
  BALL_SIZE,
  BALL_SPEED,
  BALL_SPEED_INCREASE,
  PADDLE_HIT_COOLDOWN_MS,
  BALL_BOUNCE,
  BALL_ANGLE_VARIATION,
  WALL_HEIGHT,
  SCORE_TEXT_Y,
  SCORE_FONT_SIZE,
  SERVE_DELAY_MS,
  POINTS_TO_WIN,
  BALL_PADDLE_SEPARATION,
  WIN_DISPLAY_DELAY_MS,
  COLORS,
} from './constants'

describe('constants', () => {
  it('exports arena dimensions', () => {
    expect(WIDTH).toBe(800)
    expect(HEIGHT).toBe(600)
  })

  it('exports paddle constants', () => {
    expect(PADDLE_WIDTH).toBe(20)
    expect(PADDLE_HEIGHT).toBe(100)
    expect(PADDLE_PADDING).toBe(40)
    expect(PADDLE_SPEED).toBe(400)
    expect(PADDLE_CLAMP_MARGIN).toBe(70)
  })

  it('exports ball constants', () => {
    expect(BALL_SIZE).toBe(16)
    expect(BALL_SPEED).toBe(500)
    expect(BALL_SPEED_INCREASE).toBe(1.1)
    expect(PADDLE_HIT_COOLDOWN_MS).toBe(100)
    expect(BALL_BOUNCE).toBe(1)
    expect(BALL_ANGLE_VARIATION).toBe(0.3)
  })

  it('exports wall and UI constants', () => {
    expect(WALL_HEIGHT).toBe(20)
    expect(SCORE_TEXT_Y).toBe(50)
    expect(SCORE_FONT_SIZE).toBe('48px')
    expect(SERVE_DELAY_MS).toBe(500)
    expect(WIN_DISPLAY_DELAY_MS).toBe(2500)
  })

  it('exports game rules', () => {
    expect(POINTS_TO_WIN).toBe(11)
    expect(BALL_PADDLE_SEPARATION).toBe(2)
  })

  it('exports COLORS with expected values', () => {
    expect(COLORS.WHITE).toBe(0xffffff)
    expect(COLORS.WALL).toBe(0x444444)
    expect(COLORS.TEXT).toBe('#ffffff')
  })
})
