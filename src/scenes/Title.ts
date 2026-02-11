import { WIDTH, HEIGHT, COLORS } from '../constants'

const FADE_DURATION_MS = 280

export default class Title extends Phaser.Scene {
  constructor() {
    super({ key: 'Title' })
  }

  create(): void {
    this.add.rectangle(WIDTH / 2, HEIGHT / 2, WIDTH, HEIGHT, 0x111111)

    this.add.text(WIDTH / 2, HEIGHT / 2 - 40, 'CajPong', {
      fontSize: '64px',
      color: COLORS.TEXT,
    }).setOrigin(0.5)

    this.add.text(WIDTH / 2, HEIGHT / 2 + 40, 'Press SPACE to start', {
      fontSize: '24px',
      color: COLORS.TEXT,
    }).setOrigin(0.5)

    this.input.keyboard!.once('keydown-SPACE', () => {
      this.cameras.main.fadeOut(FADE_DURATION_MS)
      this.time.delayedCall(FADE_DURATION_MS, () => {
        this.scene.start('Game')
      })
    })
  }
}
