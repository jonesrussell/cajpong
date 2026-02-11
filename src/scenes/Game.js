export default class Game extends Phaser.Scene {
  constructor() {
    super({ key: 'Game' })
  }

  create() {
    const width = 800
    const height = 600

    // Create paddle texture (white rectangle)
    const paddleW = 20
    const paddleH = 100
    const g = this.make.graphics({ add: false })
    g.fillStyle(0xffffff, 1)
    g.fillRect(0, 0, paddleW, paddleH)
    g.generateTexture('paddle', paddleW, paddleH)

    // Create ball texture (white circle)
    const ballSize = 16
    const bg = this.make.graphics({ add: false })
    bg.fillStyle(0xffffff, 1)
    bg.fillCircle(ballSize, ballSize, ballSize)
    bg.generateTexture('ball', ballSize * 2, ballSize * 2)

    // Top and bottom walls (ball bounces off these)
    const wallHeight = 20
    const topWall = this.add.rectangle(width / 2, wallHeight / 2, width, wallHeight, 0x444444)
    this.physics.add.existing(topWall, true)

    const bottomWall = this.add.rectangle(width / 2, height - wallHeight / 2, width, wallHeight, 0x444444)
    this.physics.add.existing(bottomWall, true)

    // Paddles
    const padding = 40
    this.leftPaddle = this.physics.add.image(padding, height / 2, 'paddle')
    this.leftPaddle.setImmovable(true)

    this.rightPaddle = this.physics.add.image(width - padding, height / 2, 'paddle')
    this.rightPaddle.setImmovable(true)

    // Ball
    this.ball = this.physics.add.image(width / 2, height / 2, 'ball')
    this.ball.setBounce(1)
    this.ball.setCollideWorldBounds(false)

    // Colliders: ball vs walls and paddles
    this.physics.add.collider(this.ball, topWall)
    this.physics.add.collider(this.ball, bottomWall)
    this.physics.add.collider(this.ball, this.leftPaddle)
    this.physics.add.collider(this.ball, this.rightPaddle)

    // Score
    this.scoreLeft = 0
    this.scoreRight = 0
    this.scoreText = this.add.text(width / 2, 50, '0 - 0', {
      fontSize: '48px',
      color: '#ffffff',
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
    this.ball.setPosition(400, 300)
    this.ball.setVelocity(0, 0)
    this.serving = true

    this.time.delayedCall(500, () => {
      this.serving = false
      const speed = 350
      const angle = Phaser.Math.FloatBetween(-0.3, 0.3)
      // direction: -1 = toward left, +1 = toward right (player who scored serves toward opponent)
      this.ball.setVelocity(direction * speed * Math.cos(angle), speed * Math.sin(angle))
    })
  }

  update() {
    const height = 600
    const paddleSpeed = 400
    const paddleHalfHeight = 50

    // Left paddle: W / S
    if (this.keyW.isDown) {
      this.leftPaddle.setVelocityY(-paddleSpeed)
    } else if (this.keyS.isDown) {
      this.leftPaddle.setVelocityY(paddleSpeed)
    } else {
      this.leftPaddle.setVelocityY(0)
    }

    // Right paddle: Arrow Up / Down
    if (this.cursors.up.isDown) {
      this.rightPaddle.setVelocityY(-paddleSpeed)
    } else if (this.cursors.down.isDown) {
      this.rightPaddle.setVelocityY(paddleSpeed)
    } else {
      this.rightPaddle.setVelocityY(0)
    }

    // Clamp paddles to play area (inside walls)
    const minY = 70
    const maxY = height - 70
    this.leftPaddle.y = Phaser.Math.Clamp(this.leftPaddle.y, minY, maxY)
    this.rightPaddle.y = Phaser.Math.Clamp(this.rightPaddle.y, minY, maxY)

    // Goal detection (only when not serving)
    if (!this.serving) {
      if (this.ball.x < 0) {
        this.scoreRight++
        this.updateScore()
        this.serve(-1) // right player scored, serves toward left
      } else if (this.ball.x > 800) {
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
