import { POINTS_TO_WIN } from './constants'

export function getWinner(
  scoreLeft: number,
  scoreRight: number
): 'left' | 'right' | null {
  if (scoreLeft >= POINTS_TO_WIN) return 'left'
  if (scoreRight >= POINTS_TO_WIN) return 'right'
  return null
}
