import { createServer } from 'http'
import { readFile } from 'fs/promises'
import { join, extname, resolve } from 'path'
import { fileURLToPath } from 'url'
import { Server as SocketIOServer } from 'socket.io'
import {
  createInitialState,
  step,
  type GameState,
  type Inputs,
} from '../src/gameState'

const __dirname = fileURLToPath(new URL('.', import.meta.url))
const PORT = Number(process.env.PORT) || 3000
/** Directory to serve static client from (e.g. dist/). Set STATIC_DIR or runs from repo root with ./dist. */
const STATIC_DIR = process.env.STATIC_DIR ?? join(__dirname, '..', 'dist')
const MIME: Record<string, string> = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.ico': 'image/x-icon',
  '.json': 'application/json',
}
const DT = 1 / 60
const TICK_MS = 1000 / 60

const defaultInputs: Inputs = {
  left: { up: false, down: false },
  right: { up: false, down: false },
}

type Side = 'left' | 'right'

interface Room {
  id: string
  sockets: { left: import('socket.io').Socket; right: import('socket.io').Socket }
  state: GameState
  lastInputs: { left: Inputs['left']; right: Inputs['right'] }
  prevInputs: { left: Inputs['left']; right: Inputs['right'] }
  tick: number
  intervalId: ReturnType<typeof setInterval>
}

const queue: import('socket.io').Socket[] = []
const rooms = new Map<string, Room>()
const socketToRoom = new Map<import('socket.io').Socket, { roomId: string; side: Side }>()

function generateRoomId(): string {
  return Math.random().toString(36).slice(2, 10)
}

function tryMatch(): void {
  while (queue.length >= 2) {
    const leftSocket = queue.shift()!
    const rightSocket = queue.shift()!
    const roomId = generateRoomId()
    const state = createInitialState()
    const room: Room = {
      id: roomId,
      sockets: { left: leftSocket, right: rightSocket },
      state,
      lastInputs: { left: { up: false, down: false }, right: { up: false, down: false } },
      prevInputs: { left: { up: false, down: false }, right: { up: false, down: false } },
      tick: 0,
      intervalId: null!,
    }
    rooms.set(roomId, room)
    socketToRoom.set(leftSocket, { roomId, side: 'left' })
    socketToRoom.set(rightSocket, { roomId, side: 'right' })

    leftSocket.emit('matched', { side: 'left' as const, roomId })
    rightSocket.emit('matched', { side: 'right' as const, roomId })

    room.intervalId = setInterval(() => {
      const r = rooms.get(roomId)
      if (!r) return
      const inputsForTick: Inputs = {
        left: r.lastInputs.left ?? r.prevInputs.left ?? defaultInputs.left,
        right: r.lastInputs.right ?? r.prevInputs.right ?? defaultInputs.right,
      }
      r.prevInputs = { ...r.lastInputs }
      r.state = step(r.state, inputsForTick, DT)
      r.tick++
      leftSocket.emit('game_state', { state: r.state, tick: r.tick })
      rightSocket.emit('game_state', { state: r.state, tick: r.tick })
    }, TICK_MS)
  }
}

function removeFromQueue(socket: import('socket.io').Socket): void {
  const i = queue.indexOf(socket)
  if (i !== -1) queue.splice(i, 1)
}

function cleanupRoom(roomId: string, disconnectedSocket?: import('socket.io').Socket): void {
  const room = rooms.get(roomId)
  if (!room) return
  clearInterval(room.intervalId)
  socketToRoom.delete(room.sockets.left)
  socketToRoom.delete(room.sockets.right)
  const peer = disconnectedSocket === room.sockets.left ? room.sockets.right : room.sockets.left
  peer.emit('opponent_left')
  rooms.delete(roomId)
}

async function serveStatic(
  req: import('http').IncomingMessage,
  res: import('http').ServerResponse,
  staticDir: string
): Promise<void> {
  const url = req.url === '/' || !req.url ? '/index.html' : req.url
  const pathname = url.split('?')[0]
  const relative = pathname === '/' ? 'index.html' : pathname.replace(/^\//, '')
  const path = resolve(join(staticDir, relative))
  const staticRoot = resolve(staticDir)
  if (path !== staticRoot && !path.startsWith(staticRoot + '/')) {
    res.writeHead(403)
    res.end()
    return
  }
  try {
    const data = await readFile(path)
    const ext = extname(path)
    const contentType = MIME[ext] ?? 'application/octet-stream'
    res.writeHead(200, { 'Content-Type': contentType })
    res.end(data)
  } catch {
    res.writeHead(404)
    res.end()
  }
}

const httpServer = createServer(async (req, res) => {
  if (req.url?.startsWith('/socket.io')) return
  await serveStatic(req, res, STATIC_DIR)
})
const io = new SocketIOServer(httpServer, {
  cors: {
    origin: true,
  },
})

io.on('connection', (socket) => {
  socket.on('find_match', () => {
    removeFromQueue(socket)
    queue.push(socket)
    tryMatch()
  })

  socket.on('input', (payload: { up?: boolean; down?: boolean }) => {
    const entry = socketToRoom.get(socket)
    if (!entry) return
    const room = rooms.get(entry.roomId)
    if (!room) return
    const up = payload?.up ?? false
    const down = payload?.down ?? false
    room.lastInputs[entry.side] = { up, down }
  })

  socket.on('disconnect', () => {
    const entry = socketToRoom.get(socket)
    removeFromQueue(socket)
    if (entry) {
      cleanupRoom(entry.roomId, socket)
    }
  })
})

httpServer.listen(PORT, () => {
  console.log(`CajPong server on http://localhost:${PORT}`)
})
