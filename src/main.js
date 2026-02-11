import Phaser from 'phaser'
import Game from './scenes/Game.js'

const config = {
  type: Phaser.AUTO,
  width: 800,
  height: 600,
  parent: 'body',
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { x: 0, y: 0 },
    },
  },
  scale: {
    mode: Phaser.Scale.FIT,
  },
  scene: [Game],
}

new Phaser.Game(config)
