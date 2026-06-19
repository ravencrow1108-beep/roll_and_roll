// ═══════════════════════════════════════════════════════════════
// Roll & Roll — Cloudflare Worker + Durable Object 信令层
//
// 单文件版本，可直接粘贴到 Cloudflare Dashboard 或
// 通过 `npx wrangler deploy` 部署。
//
// 信令消息：
//   Client→DO:  auth, offer, answer, iceCandidate, heartbeat, playerReady, leave
//   DO→Client:  auth_ok, playerJoined, playerLeft, offer, answer,
//               iceCandidate, error, roomClosing, heartbeat_ack
// ═══════════════════════════════════════════════════════════════

// ─── 常量 ───
const HEARTBEAT_TIMEOUT_MS = 30_000;
const ROOM_IDLE_TIMEOUT_MS = 10 * 60_000;

// ─── 工具 ───
function generateRoomId() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 去掉 0/O/1/I
  let id = '';
  for (let i = 0; i < 6; i++) {
    id += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return id;
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

// ═══════════════════════════════════════════════════════════════
// RoomDO — Durable Object 房间实例
// ═══════════════════════════════════════════════════════════════

export class RoomDO {
  constructor(state, env) {
    this.state = state;
    this.env = env;

    /** @type {Map<WebSocket, {ws:WebSocket, role:string|null, playerId:string, name:string, lastHeartbeat:number}>} */
    this.sessions = new Map();
    this.hostWs = null;
    this.roomId = '';
    this.createdAt = Date.now();
    this.lastActivity = Date.now();
    this.heartbeatTimer = null;
  }

  async fetch(request) {
    const url = new URL(request.url);

    // DO 内部初始化
    if (url.pathname === '/init' && request.method === 'POST') {
      const body = await request.json();
      this.roomId = body.roomId || '';
      this._startHeartbeat();
      return new Response('ok');
    }

    // WebSocket 升级
    const upgrade = request.headers.get('Upgrade');
    if (upgrade === 'websocket') {
      const pair = new WebSocketPair();
      const [client, server] = Object.values(pair);
      this._handleSession(server);
      return new Response(null, { status: 101, webSocket: client });
    }

    return new Response('Not Found', { status: 404 });
  }

  // ━━━━━━━ 会话 ━━━━━━━

  _handleSession(ws) {
    ws.accept();

    const session = {
      ws,
      role: null,
      playerId: '',
      name: '',
      lastHeartbeat: Date.now(),
    };
    this.sessions.set(ws, session);

    ws.addEventListener('message', (event) => {
      try {
        const msg = JSON.parse(event.data);
        this._onMessage(ws, session, msg);
      } catch (_) {
        this._send(ws, { type: 'error', message: 'Invalid JSON' });
      }
    });

    ws.addEventListener('close', () => this._onDisconnect(ws, session));
    ws.addEventListener('error', () => this._onDisconnect(ws, session));
  }

  // ━━━━━━━ 消息路由 ━━━━━━━

  _onMessage(ws, session, msg) {
    this.lastActivity = Date.now();
    session.lastHeartbeat = Date.now();

    switch (msg.type) {
      case 'auth':
        this._handleAuth(ws, session, msg);
        break;
      case 'offer':
        this._relayToPlayer(msg);
        break;
      case 'answer':
        this._relayToHost(msg);
        break;
      case 'iceCandidate':
        this._relayIce(msg);
        break;
      case 'heartbeat':
        this._send(ws, { type: 'heartbeat_ack' });
        break;
      case 'playerReady':
        this._relayToHost(msg);
        break;
      case 'leave':
        this._handleLeave(ws, session);
        break;
      default:
        this._send(ws, { type: 'error', message: `Unknown type: ${msg.type}` });
    }
  }

  // ━━━━━━━ 鉴权 ━━━━━━━

  _handleAuth(ws, session, msg) {
    const { role, name, playerId } = msg;

    if (role === 'host') {
      if (this.hostWs && this.hostWs !== ws) {
        this._send(ws, { type: 'error', message: 'Room already has a host' });
        this._removeSession(ws);
        return;
      }
      session.role = 'host';
      session.name = name || 'GM';
      session.playerId = 'host';
      this.hostWs = ws;
      this._send(ws, { type: 'auth_ok', role: 'host', roomId: this.roomId });
      console.log(`[Room ${this.roomId}] Host: ${session.name}`);

    } else if (role === 'player') {
      if (!this.hostWs) {
        this._send(ws, { type: 'error', message: 'No host in room — host must join first' });
        this._removeSession(ws);
        return;
      }
      // 检查重名：同名的旧连接视为重连，踢掉旧 session
      for (const [oldWs, s] of this.sessions) {
        if (s.role === 'player' && s.name === name) {
          console.log(`[Room ${this.roomId}] Reconnect: ${name} (kicking old session ${s.playerId})`);
          this._sendToHost({
            type: 'player_left',
            playerId: s.playerId,
            name: s.name,
          });
          this._removeSession(oldWs);
          break;
        }
      }
      session.role = 'player';
      session.name = name || 'Player';
      session.playerId = playerId || `p_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
      this._send(ws, {
        type: 'auth_ok',
        role: 'player',
        playerId: session.playerId,
        roomId: this.roomId,
      });
      this._sendToHost({
        type: 'player_joined',
        playerId: session.playerId,
        name: session.name,
      });
      console.log(`[Room ${this.roomId}] Player: ${session.name} (${session.playerId})`);

    } else {
      this._send(ws, { type: 'error', message: `Invalid role: ${role}` });
      this._removeSession(ws);
      return;
    }
  }

  // ━━━━━━━ 信令转发 ━━━━━━━

  _relayToPlayer(msg) {
    const targetId = msg.playerId || msg.targetPlayerId;
    if (!targetId) return;
    for (const [ws, session] of this.sessions) {
      if (session.playerId === targetId && session.role === 'player') {
        this._send(ws, msg);
        return;
      }
    }
  }

  _relayToHost(msg) {
    if (this.hostWs) this._send(this.hostWs, msg);
  }

  _relayIce(msg) {
    if (msg.from === 'host') {
      this._relayToPlayer(msg);
    } else {
      this._relayToHost(msg);
    }
  }

  // ━━━━━━━ 离开 / 断开 ━━━━━━━

  _handleLeave(ws, session) {
    if (session.role === 'host') {
      this._broadcast({ type: 'room_closing', reason: 'Host left' });
      this._closeAll(4000, 'Host left');
    } else {
      this._sendToHost({
        type: 'player_left',
        playerId: session.playerId,
        name: session.name,
      });
    }
    this._removeSession(ws);
  }

  _onDisconnect(ws, session) {
    this._handleLeave(ws, session);
  }

  // ━━━━━━━ 心跳 & 存活 ━━━━━━━

  _startHeartbeat() {
    this.heartbeatTimer = setInterval(() => {
      const now = Date.now();
      const dead = [];

      for (const [ws, session] of this.sessions) {
        if (now - session.lastHeartbeat > HEARTBEAT_TIMEOUT_MS) {
          dead.push({ ws, session });
        }
      }

      for (const { ws, session } of dead) {
        console.log(`[Room ${this.roomId}] Timeout: ${session.name || session.playerId}`);
        this._removeSession(ws);
        try { ws.close(4005, 'Heartbeat timeout'); } catch (_) {}
      }

      if (this.sessions.size === 0 && now - this.lastActivity > ROOM_IDLE_TIMEOUT_MS) {
        console.log(`[Room ${this.roomId}] Idle destroy`);
        this._destroy();
      }
    }, 10_000);
  }

  _destroy() {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
    this._closeAll(4006, 'Room destroyed');
  }

  // ━━━━━━━ 内部工具 ━━━━━━━

  _send(ws, data) {
    try { ws.send(JSON.stringify(data)); } catch (_) {}
  }

  _sendToHost(data) {
    if (this.hostWs) this._send(this.hostWs, data);
  }

  _broadcast(data) {
    for (const [ws] of this.sessions) this._send(ws, data);
  }

  _removeSession(ws) {
    this.sessions.delete(ws);
    if (this.hostWs === ws) this.hostWs = null;
    try { ws.close(); } catch (_) {}
  }

  _closeAll(code, reason) {
    for (const [ws] of this.sessions) {
      try { ws.close(code, reason); } catch (_) {}
    }
    this.sessions.clear();
    this.hostWs = null;
  }
}

// ═══════════════════════════════════════════════════════════════
// Worker 入口
// ═══════════════════════════════════════════════════════════════

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // POST /createRoom
    if (request.method === 'POST' && url.pathname === '/createRoom') {
      const roomId = generateRoomId();
      const doId = env.ROOM.idFromName(roomId);
      const stub = env.ROOM.get(doId);
      await stub.fetch(
        new Request('https://do.internal/init', {
          method: 'POST',
          body: JSON.stringify({ roomId }),
        })
      );
      return Response.json({ success: true, roomId }, { headers: corsHeaders });
    }

    // WebSocket /room/:id
    if (url.pathname.startsWith('/room/')) {
      const roomId = url.pathname.split('/')[2];
      if (!roomId) {
        return Response.json(
          { success: false, message: 'Missing roomId' },
          { status: 400, headers: corsHeaders }
        );
      }

      const upgrade = request.headers.get('Upgrade');
      if (!upgrade || upgrade !== 'websocket') {
        return Response.json(
          { success: false, message: 'Use wss:// to connect' },
          { status: 426, headers: corsHeaders }
        );
      }

      const doId = env.ROOM.idFromName(roomId);
      const stub = env.ROOM.get(doId);
      return stub.fetch(request);
    }

    // GET /health
    if (url.pathname === '/health') {
      return Response.json({ status: 'ok' }, { headers: corsHeaders });
    }

    return Response.json(
      { success: false, message: 'Not Found' },
      { status: 404, headers: corsHeaders }
    );
  },
};
