import Phaser from 'phaser'
import Title from './scenes/Title.js'
import Game from './scenes/Game.js'
import { WIDTH, HEIGHT } from './constants.js'

const config = {
  type: Phaser.AUTO,
  width: WIDTH,
  height: HEIGHT,
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
  scene: [Title, Game],
}

new Phaser.Game(config)
