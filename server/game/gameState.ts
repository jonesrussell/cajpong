/**
 * Pure game state and step for CajPong. Used by the server as the authoritative
 * simulation. All time is in seconds (dt, gameTime, etc.).
 */

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
  BALL_ANGLE_VARIATION,
  WALL_HEIGHT,
  BALL_PADDLE_SEPARATION,
  PADDLE_HIT_COOLDOWN_MS,
  SERVE_DELAY_MS,
} from './constants'
import { getWinner } from './gameLogic'

export interface GameState {
  ballX: number
  ballY: number
  ballVx: number
  ballVy: number
  leftPaddleY: number
  rightPaddleY: number
  scoreLeft: number
  scoreRight: number
  serving: boolean
  serveDirection: number | null
  serveCountdownRemaining: number
  gameOver: boolean
  winner: 'left' | 'right' | null
  gameTime: number
  lastPaddleHitTime: number
}

export interface Inputs {
  left: { up: boolean; down: boolean }
  right: { up: boolean; down: boolean }
}

const PADDLE_HIT_COOLDOWN_S = PADDLE_HIT_COOLDOWN_MS / 1000
const SERVE_DELAY_S = SERVE_DELAY_MS / 1000
const HALF_PADDLE = PADDLE_WIDTH / 2
const HALF_PADDLE_H = PADDLE_HEIGHT / 2
const MAX_Y = HEIGHT - PADDLE_CLAMP_MARGIN
const TOP_WALL = WALL_HEIGHT / 2
const BOTTOM_WALL = HEIGHT - WALL_HEIGHT / 2

const DEFAULT_INPUTS: Inputs = {
  left: { up: false, down: false },
  right: { up: false, down: false },
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value))
}

function movePaddleFromInput(y: number, up: boolean, down: boolean, dt: number): number {
  if (up) y -= PADDLE_SPEED * dt
  else if (down) y += PADDLE_SPEED * dt
  return clamp(y, PADDLE_CLAMP_MARGIN, MAX_Y)
}

function randomServeAngle(): number {
  return (Math.random() * 2 - 1) * BALL_ANGLE_VARIATION
}

export function createInitialState(serveDirection?: 1 | -1): GameState {
  const direction = serveDirection ?? (Math.random() < 0.5 ? -1 : 1)
  return {
    ballX: WIDTH / 2,
    ballY: HEIGHT / 2,
    ballVx: 0,
    ballVy: 0,
    leftPaddleY: HEIGHT / 2,
    rightPaddleY: HEIGHT / 2,
    scoreLeft: 0,
    scoreRight: 0,
    serving: true,
    serveDirection: direction,
    serveCountdownRemaining: SERVE_DELAY_S,
    gameOver: false,
    winner: null,
    gameTime: 0,
    lastPaddleHitTime: -1,
  }
}

export function step(
  state: GameState,
  inputs: Inputs,
  dt: number,
  nextServeAngle?: number
): GameState {
  const left = inputs.left ?? DEFAULT_INPUTS.left
  const right = inputs.right ?? DEFAULT_INPUTS.right
  const s: GameState = { ...state }

  s.gameTime = s.gameTime + dt
  s.leftPaddleY = movePaddleFromInput(s.leftPaddleY, left.up, left.down, dt)
  s.rightPaddleY = movePaddleFromInput(s.rightPaddleY, right.up, right.down, dt)

  if (s.gameOver) return s

  if (s.serving) {
    s.serveCountdownRemaining = s.serveCountdownRemaining - dt
    if (s.serveCountdownRemaining <= 0) {
      const angle = nextServeAngle ?? randomServeAngle()
      const dir = s.serveDirection ?? 1
      s.ballVx = dir * BALL_SPEED * Math.cos(angle)
      s.ballVy = BALL_SPEED * Math.sin(angle)
      s.serving = false
      s.serveDirection = null
      s.serveCountdownRemaining = 0
    } else {
      s.ballX = WIDTH / 2
      s.ballY = HEIGHT / 2
      s.ballVx = 0
      s.ballVy = 0
      return s
    }
  }

  s.ballX = s.ballX + s.ballVx * dt
  s.ballY = s.ballY + s.ballVy * dt

  if (s.ballX < 0) {
    s.scoreRight++
    s.ballX = WIDTH / 2
    s.ballY = HEIGHT / 2
    s.ballVx = 0
    s.ballVy = 0
    const winner = getWinner(s.scoreLeft, s.scoreRight)
    if (winner) {
      s.gameOver = true
      s.winner = winner
      return s
    }
    s.serving = true
    s.serveDirection = -1
    s.serveCountdownRemaining = SERVE_DELAY_S
    return s
  }
  if (s.ballX > WIDTH) {
    s.scoreLeft++
    s.ballX = WIDTH / 2
    s.ballY = HEIGHT / 2
    s.ballVx = 0
    s.ballVy = 0
    const winner = getWinner(s.scoreLeft, s.scoreRight)
    if (winner) {
      s.gameOver = true
      s.winner = winner
      return s
    }
    s.serving = true
    s.serveDirection = 1
    s.serveCountdownRemaining = SERVE_DELAY_S
    return s
  }

  if (s.ballY - BALL_SIZE <= TOP_WALL) {
    s.ballY = TOP_WALL + BALL_SIZE
    s.ballVy = Math.abs(s.ballVy)
  }
  if (s.ballY + BALL_SIZE >= BOTTOM_WALL) {
    s.ballY = BOTTOM_WALL - BALL_SIZE
    s.ballVy = -Math.abs(s.ballVy)
  }

  const cooldownOk = s.gameTime - s.lastPaddleHitTime >= PADDLE_HIT_COOLDOWN_S
  const leftPaddleRight = PADDLE_PADDING + HALF_PADDLE
  const leftPaddleLeft = PADDLE_PADDING - HALF_PADDLE
  const rightPaddleLeft = WIDTH - PADDLE_PADDING - HALF_PADDLE
  const rightPaddleRight = WIDTH - PADDLE_PADDING + HALF_PADDLE

  const hitLeftPaddle =
    cooldownOk &&
    s.ballVx < 0 &&
    s.ballX - BALL_SIZE <= leftPaddleRight &&
    s.ballX + BALL_SIZE >= leftPaddleLeft &&
    s.ballY >= s.leftPaddleY - HALF_PADDLE_H &&
    s.ballY <= s.leftPaddleY + HALF_PADDLE_H

  if (hitLeftPaddle) {
    s.lastPaddleHitTime = s.gameTime
    s.ballX = leftPaddleLeft - BALL_SIZE - BALL_PADDLE_SEPARATION
    const speed = Math.max(Math.hypot(s.ballVx, s.ballVy), BALL_SPEED) * BALL_SPEED_INCREASE
    const offset = clamp((s.ballY - s.leftPaddleY) / HALF_PADDLE_H, -1, 1)
    const angle = offset * BALL_ANGLE_VARIATION
    s.ballVx = speed * Math.cos(angle)
    s.ballVy = speed * Math.sin(angle)
    return s
  }

  const hitRightPaddle =
    cooldownOk &&
    s.ballVx > 0 &&
    s.ballX - BALL_SIZE <= rightPaddleRight &&
    s.ballX + BALL_SIZE >= rightPaddleLeft &&
    s.ballY >= s.rightPaddleY - HALF_PADDLE_H &&
    s.ballY <= s.rightPaddleY + HALF_PADDLE_H

  if (hitRightPaddle) {
    s.lastPaddleHitTime = s.gameTime
    s.ballX = rightPaddleRight + BALL_SIZE + BALL_PADDLE_SEPARATION
    const speed = Math.max(Math.hypot(s.ballVx, s.ballVy), BALL_SPEED) * BALL_SPEED_INCREASE
    const offset = clamp((s.ballY - s.rightPaddleY) / HALF_PADDLE_H, -1, 1)
    const angle = offset * BALL_ANGLE_VARIATION
    s.ballVx = -speed * Math.cos(angle)
    s.ballVy = speed * Math.sin(angle)
    return s
  }

  return s
}
