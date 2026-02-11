import { describe, it, expect } from 'vitest'
import {
  createInitialState,
  step,
  type GameState,
  type Inputs,
} from './gameState'
import { WIDTH, HEIGHT, POINTS_TO_WIN, BALL_SPEED, PADDLE_PADDING, PADDLE_WIDTH } from './constants'

const DT = 1 / 60
const defaultInputs: Inputs = { left: { up: false, down: false }, right: { up: false, down: false } }

describe('createInitialState', () => {
  it('centers ball and paddles, zero score, serving', () => {
    const s = createInitialState(1)
    expect(s.ballX).toBe(WIDTH / 2)
    expect(s.ballY).toBe(HEIGHT / 2)
    expect(s.ballVx).toBe(0)
    expect(s.ballVy).toBe(0)
    expect(s.leftPaddleY).toBe(HEIGHT / 2)
    expect(s.rightPaddleY).toBe(HEIGHT / 2)
    expect(s.scoreLeft).toBe(0)
    expect(s.scoreRight).toBe(0)
    expect(s.serving).toBe(true)
    expect(s.serveDirection).toBe(1)
    expect(s.gameOver).toBe(false)
    expect(s.winner).toBeNull()
  })

  it('accepts serve direction -1', () => {
    const s = createInitialState(-1)
    expect(s.serveDirection).toBe(-1)
  })
})

describe('step — serve timing', () => {
  it('keeps ball stationary until serve countdown expires', () => {
    let s = createInitialState(1)
    const angle = 0
    for (let i = 0; i < 35; i++) {
      s = step(s, defaultInputs, DT, angle)
      if (s.serving) {
        expect(s.ballX).toBe(WIDTH / 2)
        expect(s.ballY).toBe(HEIGHT / 2)
      } else break
    }
    expect(s.serving).toBe(false)
    expect(s.ballVx).toBeGreaterThan(0)
    expect(s.ballVy).toBe(0)
  })

  it('launches ball in serve direction with given angle', () => {
    let s = createInitialState(-1)
    const angle = 0.1
    while (s.serving) s = step(s, defaultInputs, DT, angle)
    expect(s.ballVx).toBeLessThan(0)
    expect(Math.abs(s.ballVy) - BALL_SPEED * Math.sin(angle)).toBeLessThan(0.01)
  })
})

describe('step — paddle movement', () => {
  it('moves left paddle up with input', () => {
    let s = createInitialState(1)
    while (s.serving) s = step(s, defaultInputs, DT, 0)
    const yBefore = s.leftPaddleY
    s = step(s, { ...defaultInputs, left: { up: true, down: false } }, DT)
    expect(s.leftPaddleY).toBeLessThan(yBefore)
  })

  it('moves left paddle down with input', () => {
    let s = createInitialState(1)
    while (s.serving) s = step(s, defaultInputs, DT, 0)
    const yBefore = s.leftPaddleY
    s = step(s, { ...defaultInputs, left: { up: false, down: true } }, DT)
    expect(s.leftPaddleY).toBeGreaterThan(yBefore)
  })

  it('clamps paddle to bounds', () => {
    let s = createInitialState(1)
    s.leftPaddleY = 100
    for (let i = 0; i < 200; i++) {
      s = step(s, { ...defaultInputs, left: { up: true, down: false } }, DT)
    }
    expect(s.leftPaddleY).toBeGreaterThanOrEqual(70)
  })
})

describe('step — walls', () => {
  it('bounces ball off top wall', () => {
    let s = createInitialState(1)
    while (s.serving) s = step(s, defaultInputs, DT, 0)
    s.ballY = 20
    s.ballVy = -200
    s = step(s, defaultInputs, DT)
    expect(s.ballVy).toBeGreaterThan(0)
  })

  it('bounces ball off bottom wall', () => {
    let s = createInitialState(1)
    while (s.serving) s = step(s, defaultInputs, DT, 0)
    s.ballY = HEIGHT - 25
    s.ballVy = 200
    s = step(s, defaultInputs, DT)
    expect(s.ballVy).toBeLessThan(0)
  })
})

describe('step — goals and win condition', () => {
  it('scores for right when ball goes past left', () => {
    let s = createInitialState(1)
    while (s.serving) s = step(s, defaultInputs, DT, 0)
    s.ballX = -5
    s.ballVx = -100
    s = step(s, defaultInputs, DT)
    expect(s.scoreRight).toBe(1)
    expect(s.ballX).toBe(WIDTH / 2)
    expect(s.serving).toBe(true)
    expect(s.serveDirection).toBe(-1)
  })

  it('scores for left when ball goes past right', () => {
    let s = createInitialState(-1)
    while (s.serving) s = step(s, defaultInputs, DT, 0)
    s.ballX = WIDTH + 5
    s.ballVx = 100
    s = step(s, defaultInputs, DT)
    expect(s.scoreLeft).toBe(1)
    expect(s.serving).toBe(true)
    expect(s.serveDirection).toBe(1)
  })

  it('sets game over and winner when left reaches points to win', () => {
    let s = createInitialState(1)
    s.scoreLeft = POINTS_TO_WIN - 1
    s.serving = false
    s.serveDirection = null
    s.serveCountdownRemaining = 0
    s.ballX = WIDTH + 5
    s.ballVx = 100
    s = step(s, defaultInputs, DT)
    expect(s.scoreLeft).toBe(POINTS_TO_WIN)
    expect(s.gameOver).toBe(true)
    expect(s.winner).toBe('left')
  })

  it('sets game over and winner when right reaches points to win', () => {
    let s = createInitialState(-1)
    s.scoreRight = POINTS_TO_WIN - 1
    s.serving = false
    s.serveDirection = null
    s.serveCountdownRemaining = 0
    s.ballX = -5
    s.ballVx = -100
    s = step(s, defaultInputs, DT)
    expect(s.scoreRight).toBe(POINTS_TO_WIN)
    expect(s.gameOver).toBe(true)
    expect(s.winner).toBe('right')
  })
})

describe('step — paddle collision', () => {
  function stateAfterServe(): GameState {
    let s = createInitialState(1)
    while (s.serving) s = step(s, defaultInputs, DT, 0)
    return s
  }

  it('bounces ball off left paddle and reverses direction', () => {
    let s = stateAfterServe()
    s.ballX = PADDLE_PADDING + PADDLE_WIDTH / 2 + BALL_SPEED * DT * 2
    s.ballVx = -BALL_SPEED
    s.ballVy = 0
    s.leftPaddleY = HEIGHT / 2
    s = step(s, defaultInputs, DT)
    expect(s.ballVx).toBeGreaterThan(0)
  })

  it('bounces ball off right paddle and reverses direction', () => {
    let s = stateAfterServe()
    s.ballX = WIDTH - PADDLE_PADDING - PADDLE_WIDTH / 2 - BALL_SPEED * DT * 2
    s.ballVx = BALL_SPEED
    s.ballVy = 0
    s.rightPaddleY = HEIGHT / 2
    s = step(s, defaultInputs, DT)
    expect(s.ballVx).toBeLessThan(0)
  })

  it('respects paddle hit cooldown (no double hit)', () => {
    let s = stateAfterServe()
    s.ballX = PADDLE_PADDING + PADDLE_WIDTH / 2 + 5
    s.ballVx = -BALL_SPEED
    s.ballVy = 0
    s.leftPaddleY = HEIGHT / 2
    s = step(s, defaultInputs, DT)
    const vxAfterFirst = s.ballVx
    s = step(s, defaultInputs, DT)
    s = step(s, defaultInputs, DT)
    expect(s.ballVx).toBe(vxAfterFirst)
  })
})
