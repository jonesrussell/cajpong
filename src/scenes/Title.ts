import { io, type Socket } from 'socket.io-client'
import { WIDTH, HEIGHT, COLORS, BUTTON_WIDTH, BUTTON_HEIGHT, BUTTON_COLOR } from '../constants'

const FADE_DURATION_MS = 280
const SERVER_URL = import.meta.env.VITE_SERVER_URL ?? 'http://localhost:3000'

export default class Title extends Phaser.Scene {
  private statusText!: Phaser.GameObjects.Text
  private subText!: Phaser.GameObjects.Text

  constructor() {
    super({ key: 'Title' })
  }

  create(): void {
    this.add.rectangle(WIDTH / 2, HEIGHT / 2, WIDTH, HEIGHT, 0x111111)

    this.add.text(WIDTH / 2, HEIGHT / 2 - 60, 'CajPong', {
      fontSize: '64px',
      color: COLORS.TEXT,
    }).setOrigin(0.5)

    this.statusText = this.add.text(WIDTH / 2, HEIGHT / 2, 'SPACE - Local  |  ENTER - Online', {
      fontSize: '24px',
      color: COLORS.TEXT,
    }).setOrigin(0.5)

    this.subText = this.add.text(WIDTH / 2, HEIGHT / 2 + 36, '', {
      fontSize: '18px',
      color: COLORS.TEXT,
    }).setOrigin(0.5)

    // Tappable buttons for mobile
    this.createButton(WIDTH / 2 - 110, HEIGHT / 2 + 90, 'Local', () => this.startLocal())
    this.createButton(WIDTH / 2 + 110, HEIGHT / 2 + 90, 'Online', () => this.findMatch())

    this.input.keyboard!.once('keydown-SPACE', () => this.startLocal())
    this.input.keyboard!.once('keydown-ENTER', () => this.findMatch())
  }

  private createButton(x: number, y: number, label: string, onTap: () => void): void {
    const rect = this.add.rectangle(x, y, BUTTON_WIDTH, BUTTON_HEIGHT, BUTTON_COLOR).setInteractive()
    this.add.text(x, y, label, { fontSize: '24px', color: COLORS.TEXT }).setOrigin(0.5)
    rect.once('pointerdown', () => {
      this.input.removeAllListeners()
      onTap()
    })
  }

  private startLocal(): void {
    this.cameras.main.fadeOut(FADE_DURATION_MS)
    this.time.delayedCall(FADE_DURATION_MS, () => {
      this.scene.start('Game', { side: undefined, socket: undefined })
    })
  }

  private findMatch(): void {
    this.statusText.setText('Finding opponent…')
    this.subText.setText('')
    this.input.keyboard!.off('keydown-ENTER')

    const socket: Socket = io(SERVER_URL, { autoConnect: true })

    const cleanup = () => {
      socket.off('matched')
      socket.off('connect_error')
      socket.off('disconnect')
    }

    const onRetry = () => {
      const doRetry = () => {
        this.input.keyboard!.off('keydown-ENTER')
        this.subText.disableInteractive()
        this.findMatch()
      }
      this.input.keyboard!.once('keydown-ENTER', doRetry)
      this.subText.setText('Tap here or press ENTER to retry')
      this.subText.setInteractive().once('pointerdown', doRetry)
    }

    socket.on('connect_error', () => {
      cleanup()
      this.statusText.setText('Connection failed')
      onRetry()
    })

    socket.on('disconnect', () => {
      if (socket.recovered) return
      cleanup()
      this.statusText.setText('Disconnected')
      onRetry()
    })

    socket.on('matched', (payload: { side: 'left' | 'right'; roomId: string }) => {
      cleanup()
      this.cameras.main.fadeOut(FADE_DURATION_MS)
      this.time.delayedCall(FADE_DURATION_MS, () => {
        this.scene.start('Game', { side: payload.side, socket })
      })
    })

    if (socket.connected) {
      socket.emit('find_match')
    } else {
      socket.once('connect', () => socket.emit('find_match'))
    }
  }
}
