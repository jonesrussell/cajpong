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
  POINTS_TO_WIN,
  BALL_PADDLE_SEPARATION,
  WIN_DISPLAY_DELAY_MS,
  COLORS,
} from '../constants.js'

export default class Game extends Phaser.Scene {
  constructor() {
    super({ key: 'Game' })
  }

  getDimensions() {
    return { width: WIDTH, height: HEIGHT }
  }

  createWall(x, y, w, h) {
    const wall = this.add.rectangle(x, y, w, h, COLORS.WALL)
    this.physics.add.existing(wall, true)
    return wall
  }

  movePaddle(paddle, upKey, downKey, dt, height) {
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

  create() {
    const { width, height } = this.getDimensions()

    // Create paddle texture (white rectangle)
    const g = this.make.graphics({ add: false })
    g.fillStyle(COLORS.WHITE, 1)
    g.fillRect(0, 0, PADDLE_WIDTH, PADDLE_HEIGHT)
    g.generateTexture('paddle', PADDLE_WIDTH, PADDLE_HEIGHT)

    // Create ball texture (white circle)
    const bg = this.make.graphics({ add: false })
    bg.fillStyle(COLORS.WHITE, 1)
    bg.fillCircle(BALL_SIZE, BALL_SIZE, BALL_SIZE)
    bg.generateTexture('ball', BALL_SIZE * 2, BALL_SIZE * 2)

    // Top and bottom walls (ball bounces off these)
    const topWall = this.createWall(width / 2, WALL_HEIGHT / 2, width, WALL_HEIGHT)
    const bottomWall = this.createWall(width / 2, height - WALL_HEIGHT / 2, width, WALL_HEIGHT)

    // Paddles: use static bodies and move by position to avoid ball sticking
    this.leftPaddle = this.add.image(PADDLE_PADDING, height / 2, 'paddle')
    this.physics.add.existing(this.leftPaddle, true)

    this.rightPaddle = this.add.image(width - PADDLE_PADDING, height / 2, 'paddle')
    this.physics.add.existing(this.rightPaddle, true)

    // Ball
    this.ball = this.physics.add.image(width / 2, height / 2, 'ball')
    this.ball.setBounce(BALL_BOUNCE)
    this.ball.setCollideWorldBounds(false)

    // Colliders: ball vs walls and paddles
    this.physics.add.collider(this.ball, topWall)
    this.physics.add.collider(this.ball, bottomWall)
    this.physics.add.collider(this.ball, this.leftPaddle, this.onBallHitPaddle, null, this)
    this.physics.add.collider(this.ball, this.rightPaddle, this.onBallHitPaddle, null, this)

    // Score
    this.scoreLeft = 0
    this.scoreRight = 0
    this.scoreText = this.add.text(width / 2, SCORE_TEXT_Y, '0 - 0', {
      fontSize: SCORE_FONT_SIZE,
      color: COLORS.TEXT,
    })
    this.scoreText.setOrigin(0.5)

    // Input
    this.cursors = this.input.keyboard.createCursorKeys()
    this.keyW = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.W)
    this.keyS = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.S)

    // Serve state
    this.serving = false
    this.lastPaddleHitTime = 0
    this.gameOver = false

    // Initial serve (random direction)
    this.serve(Phaser.Math.RND.pick([-1, 1]))
  }

  resetBall() {
    const { width, height } = this.getDimensions()
    this.ball.setPosition(width / 2, height / 2)
    this.ball.setVelocity(0, 0)
  }

  checkWin() {
    if (this.scoreLeft === POINTS_TO_WIN) {
      this.gameOver = true
      this.onWin('left')
    } else if (this.scoreRight === POINTS_TO_WIN) {
      this.gameOver = true
      this.onWin('right')
    }
  }

  onWin(winner) {
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

  onBallHitPaddle(ball, paddle) {
    const now = this.time.now
    if (now - this.lastPaddleHitTime < PADDLE_HIT_COOLDOWN_MS) return
    this.lastPaddleHitTime = now

    // Force separation: push ball fully clear of paddle to prevent sticking
    const halfPaddle = PADDLE_WIDTH / 2
    const halfBall = BALL_SIZE
    const gap = BALL_PADDLE_SEPARATION
    const hitFromLeft = ball.x < paddle.x
    const newX = hitFromLeft
      ? paddle.x - halfPaddle - halfBall - gap
      : paddle.x + halfPaddle + halfBall + gap
    ball.setPosition(newX, ball.y)

    const { x: vx, y: vy } = ball.body.velocity
    const speed = Math.max(Math.hypot(vx, vy), BALL_SPEED) * BALL_SPEED_INCREASE
    const offset = Phaser.Math.Clamp((ball.y - paddle.y) / (PADDLE_HEIGHT / 2), -1, 1)
    const angle = offset * BALL_ANGLE_VARIATION
    const direction = hitFromLeft ? -1 : 1
    ball.setVelocity(
      direction * speed * Math.cos(angle),
      speed * Math.sin(angle)
    )
  }

  serve(direction) {
    this.resetBall()
    this.serving = true

    this.time.delayedCall(SERVE_DELAY_MS, () => {
      this.serving = false
      const angle = Phaser.Math.FloatBetween(-BALL_ANGLE_VARIATION, BALL_ANGLE_VARIATION)
      // direction: -1 = toward left, +1 = toward right (player who scored serves toward opponent)
      this.ball.setVelocity(direction * BALL_SPEED * Math.cos(angle), BALL_SPEED * Math.sin(angle))
    })
  }

  update(_, delta) {
    const { width, height } = this.getDimensions()

    if (this.gameOver) {
      this.ball.setVelocity(0, 0)
      return
    }

    const dt = delta / 1000

    this.movePaddle(this.leftPaddle, this.keyW, this.keyS, dt, height)
    this.movePaddle(this.rightPaddle, this.cursors.up, this.cursors.down, dt, height)

    // Goal detection (only when not serving)
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

  updateScore() {
    this.scoreText.setText(`${this.scoreLeft} - ${this.scoreRight}`)
  }
}
