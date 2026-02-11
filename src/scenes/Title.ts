import { io, type Socket } from 'socket.io-client'
import { WIDTH, HEIGHT, COLORS } from '../constants'

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

    this.input.keyboard!.once('keydown-SPACE', () => this.startLocal())
    this.input.keyboard!.once('keydown-ENTER', () => this.findMatch())
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

    socket.on('connect_error', () => {
      cleanup()
      this.statusText.setText('Connection failed')
      this.subText.setText('Press ENTER to retry')
      this.input.keyboard!.once('keydown-ENTER', () => this.findMatch())
    })

    socket.on('disconnect', () => {
      if (socket.recovered) return
      cleanup()
      this.statusText.setText('Disconnected')
      this.subText.setText('Press ENTER to retry')
      this.input.keyboard!.once('keydown-ENTER', () => this.findMatch())
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
