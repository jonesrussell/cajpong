import { describe, it, expect } from 'vitest'
import { getWinner } from './gameLogic'
import { POINTS_TO_WIN } from './constants'

describe('getWinner', () => {
  it('returns null when neither side has reached points to win', () => {
    expect(getWinner(0, 0)).toBeNull()
    expect(getWinner(5, 5)).toBeNull()
    expect(getWinner(POINTS_TO_WIN - 1, POINTS_TO_WIN - 1)).toBeNull()
  })

  it('returns "left" when left reaches points to win', () => {
    expect(getWinner(POINTS_TO_WIN, 0)).toBe('left')
    expect(getWinner(POINTS_TO_WIN, 5)).toBe('left')
    expect(getWinner(POINTS_TO_WIN + 1, POINTS_TO_WIN)).toBe('left')
  })

  it('returns "right" when right reaches points to win (and left has not)', () => {
    expect(getWinner(0, POINTS_TO_WIN)).toBe('right')
    expect(getWinner(5, POINTS_TO_WIN)).toBe('right')
  })

  it('prefers left when both have reached points to win (left checked first)', () => {
    expect(getWinner(POINTS_TO_WIN, POINTS_TO_WIN)).toBe('left')
  })
})
