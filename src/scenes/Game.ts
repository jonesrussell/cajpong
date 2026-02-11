import {
  WIDTH,
  HEIGHT,
  PADDLE_WIDTH,
  PADDLE_HEIGHT,
  PADDLE_PADDING,
  PADDLE_SPEED,
  PADDLE_CLAMP_MARGIN,
  BALL_SIZE,
  BALL_BOUNCE,
  BALL_SPEED,
  BALL_SPEED_INCREASE,
  PADDLE_HIT_COOLDOWN_MS,
  BALL_ANGLE_VARIATION,
  WALL_HEIGHT,
  SCORE_TEXT_Y,
  SCORE_FONT_SIZE,
  SERVE_DELAY_MS,
  BALL_PADDLE_SEPARATION,
  WIN_DISPLAY_DELAY_MS,
  COLORS,
} from '../constants'
import { getWinner } from '../gameLogic'

type PaddleWithBody = Phaser.GameObjects.Image & { body: Phaser.Physics.Arcade.StaticBody }
type WallWithBody = Phaser.GameObjects.Rectangle & { body: Phaser.Physics.Arcade.StaticBody }

export default class Game extends Phaser.Scene {
  private leftPaddle!: PaddleWithBody
  private rightPaddle!: PaddleWithBody
  private ball!: Phaser.Physics.Arcade.Image
  private scoreText!: Phaser.GameObjects.Text
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys
  private keyW!: Phaser.Input.Keyboard.Key
  private keyS!: Phaser.Input.Keyboard.Key
  private scoreLeft = 0
  private scoreRight = 0
  private serving = false
  private lastPaddleHitTime = 0
  private gameOver = false

  constructor() {
    super({ key: 'Game' })
  }

  getDimensions(): { width: number; height: number } {
    return { width: WIDTH, height: HEIGHT }
  }

  createWall(x: number, y: number, w: number, h: number): WallWithBody {
    const wall = this.add.rectangle(x, y, w, h, COLORS.WALL)
    this.physics.add.existing(wall, true)
    return wall as WallWithBody
  }

  movePaddle(
    paddle: PaddleWithBody,
    upKey: Phaser.Input.Keyboard.Key,
    downKey: Phaser.Input.Keyboard.Key,
    dt: number,
    height: number
  ): void {
    if (upKey.isDown) {
      paddle.y -= PADDLE_SPEED * dt
    } else if (downKey.isDown) {
      paddle.y += PADDLE_SPEED * dt
    }
    const minY = PADDLE_CLAMP_MARGIN
    const maxY = height - PADDLE_CLAMP_MARGIN
    paddle.y = Phaser.Math.Clamp(paddle.y, minY, maxY)
    paddle.body.updateFromGameObject()
  }

  create(): void {
    const { width, height } = this.getDimensions()

    // Create paddle texture (white rectangle)
    const g = this.make.graphics(undefined, false)
    g.fillStyle(COLORS.WHITE, 1)
    g.fillRect(0, 0, PADDLE_WIDTH, PADDLE_HEIGHT)
    g.generateTexture('paddle', PADDLE_WIDTH, PADDLE_HEIGHT)

    // Create ball texture (white circle)
    const bg = this.make.graphics(undefined, false)
    bg.fillStyle(COLORS.WHITE, 1)
    bg.fillCircle(BALL_SIZE, BALL_SIZE, BALL_SIZE)
    bg.generateTexture('ball', BALL_SIZE * 2, BALL_SIZE * 2)

    // Top and bottom walls (ball bounces off these)
    const topWall = this.createWall(width / 2, WALL_HEIGHT / 2, width, WALL_HEIGHT)
    const bottomWall = this.createWall(width / 2, height - WALL_HEIGHT / 2, width, WALL_HEIGHT)

    // Paddles: use static bodies and move by position to avoid ball sticking
    this.leftPaddle = this.add.image(PADDLE_PADDING, height / 2, 'paddle') as PaddleWithBody
    this.physics.add.existing(this.leftPaddle, true)

    this.rightPaddle = this.add.image(width - PADDLE_PADDING, height / 2, 'paddle') as PaddleWithBody
    this.physics.add.existing(this.rightPaddle, true)

    // Ball
    this.ball = this.physics.add.image(width / 2, height / 2, 'ball')
    this.ball.setBounce(BALL_BOUNCE)
    this.ball.setCollideWorldBounds(false)

    // Colliders: ball vs walls and paddles
    this.physics.add.collider(this.ball, topWall)
    this.physics.add.collider(this.ball, bottomWall)
    this.physics.add.collider(this.ball, this.leftPaddle, this.onBallHitPaddle, undefined, this)
    this.physics.add.collider(this.ball, this.rightPaddle, this.onBallHitPaddle, undefined, this)

    // Score
    this.scoreText = this.add.text(width / 2, SCORE_TEXT_Y, '0 - 0', {
      fontSize: SCORE_FONT_SIZE,
      color: COLORS.TEXT,
    })
    this.scoreText.setOrigin(0.5)

    // Input
    this.cursors = this.input.keyboard!.createCursorKeys()
    this.keyW = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.W)
    this.keyS = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.S)

    // Serve state
    this.serving = false
    this.lastPaddleHitTime = 0
    this.gameOver = false

    // Initial serve (random direction)
    this.serve(Phaser.Math.RND.pick([-1, 1]))
  }

  resetBall(): void {
    const { width, height } = this.getDimensions()
    this.ball.setPosition(width / 2, height / 2)
    this.ball.setVelocity(0, 0)
  }

  checkWin(): void {
    const winner = getWinner(this.scoreLeft, this.scoreRight)
    if (winner) {
      this.gameOver = true
      this.onWin(winner)
    }
  }

  onWin(winner: 'left' | 'right'): void {
    this.resetBall()
    const { width, height } = this.getDimensions()
    const message = winner === 'left' ? 'Left wins!' : 'Right wins!'
    this.add.text(width / 2, height / 2, message, {
      fontSize: '56px',
      color: COLORS.TEXT,
    }).setOrigin(0.5)
    this.time.delayedCall(WIN_DISPLAY_DELAY_MS, () => {
      this.scene.start('Title')
    })
  }

  onBallHitPaddle(
    ball: Phaser.Types.Physics.Arcade.GameObjectWithBody | Phaser.Physics.Arcade.Body | Phaser.Physics.Arcade.StaticBody | Phaser.Tilemaps.Tile,
    paddle: Phaser.Types.Physics.Arcade.GameObjectWithBody | Phaser.Physics.Arcade.Body | Phaser.Physics.Arcade.StaticBody | Phaser.Tilemaps.Tile
  ): void {
    const now = this.time.now
    if (now - this.lastPaddleHitTime < PADDLE_HIT_COOLDOWN_MS) return
    this.lastPaddleHitTime = now

    const paddleObj = paddle as PaddleWithBody
    const ballObj = ball as Phaser.Physics.Arcade.Image

    // Force separation: push ball fully clear of paddle to prevent sticking
    const halfPaddle = PADDLE_WIDTH / 2
    const halfBall = BALL_SIZE
    const gap = BALL_PADDLE_SEPARATION
    const hitFromLeft = ballObj.x < paddleObj.x
    const newX = hitFromLeft
      ? paddleObj.x - halfPaddle - halfBall - gap
      : paddleObj.x + halfPaddle + halfBall + gap
    ballObj.setPosition(newX, ballObj.y)

    const body = ballObj.body
    if (!body) return
    const { x: vx, y: vy } = body.velocity
    const speed = Math.max(Math.hypot(vx, vy), BALL_SPEED) * BALL_SPEED_INCREASE
    const offset = Phaser.Math.Clamp((ballObj.y - paddleObj.y) / (PADDLE_HEIGHT / 2), -1, 1)
    const angle = offset * BALL_ANGLE_VARIATION
    const direction = hitFromLeft ? -1 : 1
    ballObj.setVelocity(
      direction * speed * Math.cos(angle),
      speed * Math.sin(angle)
    )
  }

  serve(direction: number): void {
    this.resetBall()
    this.serving = true

    this.time.delayedCall(SERVE_DELAY_MS, () => {
      this.serving = false
      const angle = Phaser.Math.FloatBetween(-BALL_ANGLE_VARIATION, BALL_ANGLE_VARIATION)
      this.ball.setVelocity(direction * BALL_SPEED * Math.cos(angle), BALL_SPEED * Math.sin(angle))
    })
  }

  update(_time: number, delta: number): void {
    const { width, height } = this.getDimensions()

    if (this.gameOver) {
      this.ball.setVelocity(0, 0)
      return
    }

    const dt = delta / 1000

    this.movePaddle(this.leftPaddle, this.keyW, this.keyS, dt, height)
    this.movePaddle(this.rightPaddle, this.cursors.up!, this.cursors.down!, dt, height)

    if (!this.serving) {
      if (this.ball.x < 0) {
        this.scoreRight++
        this.updateScore()
        this.checkWin()
        if (!this.gameOver) this.serve(-1)
      } else if (this.ball.x > width) {
        this.scoreLeft++
        this.updateScore()
        this.checkWin()
        if (!this.gameOver) this.serve(1)
      }
    }
  }

  updateScore(): void {
    this.scoreText.setText(`${this.scoreLeft} - ${this.scoreRight}`)
  }
}
