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
  BALL_ANGLE_VARIATION,
  WALL_HEIGHT,
  SCORE_TEXT_Y,
  SCORE_FONT_SIZE,
  SERVE_DELAY_MS,
  COLORS,
} from '../constants.js'

export default class Game extends Phaser.Scene {
  constructor() {
    super({ key: 'Game' })
  }

  getDimensions() {
    return { width: WIDTH, height: HEIGHT }
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
    const topWall = this.add.rectangle(width / 2, WALL_HEIGHT / 2, width, WALL_HEIGHT, COLORS.WALL)
    this.physics.add.existing(topWall, true)

    const bottomWall = this.add.rectangle(width / 2, height - WALL_HEIGHT / 2, width, WALL_HEIGHT, COLORS.WALL)
    this.physics.add.existing(bottomWall, true)

    // Paddles
    this.leftPaddle = this.physics.add.image(PADDLE_PADDING, height / 2, 'paddle')
    this.leftPaddle.setImmovable(true)

    this.rightPaddle = this.physics.add.image(width - PADDLE_PADDING, height / 2, 'paddle')
    this.rightPaddle.setImmovable(true)

    // Ball
    this.ball = this.physics.add.image(width / 2, height / 2, 'ball')
    this.ball.setBounce(BALL_BOUNCE)
    this.ball.setCollideWorldBounds(false)

    // Colliders: ball vs walls and paddles
    this.physics.add.collider(this.ball, topWall)
    this.physics.add.collider(this.ball, bottomWall)
    this.physics.add.collider(this.ball, this.leftPaddle)
    this.physics.add.collider(this.ball, this.rightPaddle)

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

    // Initial serve (random direction)
    this.serve(Phaser.Math.RND.pick([-1, 1]))
  }

  serve(direction) {
    const { width, height } = this.getDimensions()
    this.ball.setPosition(width / 2, height / 2)
    this.ball.setVelocity(0, 0)
    this.serving = true

    this.time.delayedCall(SERVE_DELAY_MS, () => {
      this.serving = false
      const angle = Phaser.Math.FloatBetween(-BALL_ANGLE_VARIATION, BALL_ANGLE_VARIATION)
      // direction: -1 = toward left, +1 = toward right (player who scored serves toward opponent)
      this.ball.setVelocity(direction * BALL_SPEED * Math.cos(angle), BALL_SPEED * Math.sin(angle))
    })
  }

  update() {
    const { width, height } = this.getDimensions()

    // Left paddle: W / S
    if (this.keyW.isDown) {
      this.leftPaddle.setVelocityY(-PADDLE_SPEED)
    } else if (this.keyS.isDown) {
      this.leftPaddle.setVelocityY(PADDLE_SPEED)
    } else {
      this.leftPaddle.setVelocityY(0)
    }

    // Right paddle: Arrow Up / Down
    if (this.cursors.up.isDown) {
      this.rightPaddle.setVelocityY(-PADDLE_SPEED)
    } else if (this.cursors.down.isDown) {
      this.rightPaddle.setVelocityY(PADDLE_SPEED)
    } else {
      this.rightPaddle.setVelocityY(0)
    }

    // Clamp paddles to play area (inside walls)
    const minY = PADDLE_CLAMP_MARGIN
    const maxY = height - PADDLE_CLAMP_MARGIN
    this.leftPaddle.y = Phaser.Math.Clamp(this.leftPaddle.y, minY, maxY)
    this.rightPaddle.y = Phaser.Math.Clamp(this.rightPaddle.y, minY, maxY)

    // Goal detection (only when not serving)
    if (!this.serving) {
      if (this.ball.x < 0) {
        this.scoreRight++
        this.updateScore()
        this.serve(-1) // right player scored, serves toward left
      } else if (this.ball.x > width) {
        this.scoreLeft++
        this.updateScore()
        this.serve(1) // left player scored, serves toward right
      }
    }
  }

  updateScore() {
    this.scoreText.setText(`${this.scoreLeft} - ${this.scoreRight}`)
  }
}
