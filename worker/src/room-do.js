// ═══════════════════════════════════════════════════════════════
// RoomDO — 单个房间的 Durable Object 实例。
//
// 每个房间一个 DO 实例，在内存中维护：
//   - host WebSocket
//   - player WebSocket(s)
//   - 房间元数据
//
// 信令消息类型（与 Flutter SignalMessage 对齐）：
//   Client→DO:  auth, offer, answer, iceCandidate, heartbeat, playerReady, leave
//   DO→Client:  auth_ok, playerJoined, playerLeft, offer, answer,
//               iceCandidate, error, roomClosing, heartbeat_ack
// ═══════════════════════════════════════════════════════════════

// ─── 会话角色 ───
const ROLE_HOST = 'host';
const ROLE_PLAYER = 'player';

// ─── 心跳超时（30 秒无心跳 → 断开）───
const HEARTBEAT_TIMEOUT_MS = 30_000;

// ─── 房间空闲超时（10 分钟无活动 → 销毁）───
const ROOM_IDLE_TIMEOUT_MS = 10 * 60_000;

export class RoomDO {
  constructor(state, env) {
    this.state = state;
    this.env = env;

    // 会话：Map<WebSocket, { role, playerId, name, lastHeartbeat }>
    this.sessions = new Map();

    // Host 的 WebSocket（最多一个）
    this.hostWs = null;

    // 房间元数据
    this.roomId = '';
    this.createdAt = Date.now();
    this.lastActivity = Date.now();

    // 心跳定时器
    this.heartbeatTimer = null;

    // Hibernation API：如果 DO 支持，可以从存储恢复
    // 当前实现使用内存状态（适合活跃房间数 < 1000 的场景）
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // fetch() — 处理 HTTP 请求（WebSocket 升级或内部操作）
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  async fetch(request) {
    const url = new URL(request.url);

    // 内部初始化请求
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // WebSocket 会话管理
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  _handleSession(ws) {
    ws.accept();

    // 暂存：等 auth 消息到达后分配角色
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
      } catch (e) {
        this._send(ws, {
          type: 'error',
          message: 'Invalid JSON',
        });
      }
    });

    ws.addEventListener('close', () => {
      this._onClose(ws, session);
    });

    ws.addEventListener('error', () => {
      this._onClose(ws, session);
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 消息路由
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  _onMessage(ws, session, msg) {
    this.lastActivity = Date.now();
    session.lastHeartbeat = Date.now();

    const { type } = msg;

    switch (type) {
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
        this._send(ws, {
          type: 'error',
          message: `Unknown message type: ${type}`,
        });
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 鉴权（分配 Host/Player 角色）
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  _handleAuth(ws, session, msg) {
    const { role, name, playerId } = msg;

    if (role === ROLE_HOST) {
      // Host 连接
      if (this.hostWs && this.hostWs !== ws) {
        this._send(ws, {
          type: 'error',
          message: 'Room already has a host',
        });
        ws.close(4001, 'Host already connected');
        return;
      }
      session.role = ROLE_HOST;
      session.name = name || 'GM';
      session.playerId = 'host';
      this.hostWs = ws;

      this._send(ws, {
        type: 'auth_ok',
        role: ROLE_HOST,
        roomId: this.roomId,
      });

      console.log(`[Room ${this.roomId}] Host connected: ${session.name}`);
    } else if (role === ROLE_PLAYER) {
      // Player 连接
      if (!this.hostWs) {
        this._send(ws, {
          type: 'error',
          message: 'Room has no host yet',
        });
        ws.close(4002, 'No host in room');
        return;
      }

      // 检查重名
      for (const [, s] of this.sessions) {
        if (s.role === ROLE_PLAYER && s.name === name) {
          this._send(ws, {
            type: 'error',
            message: 'Name already taken',
            code: 'name_taken',
          });
          ws.close(4003, 'Name taken');
          return;
        }
      }

      session.role = ROLE_PLAYER;
      session.name = name || 'Player';
      session.playerId = playerId || this._generatePlayerId();

      this._send(ws, {
        type: 'auth_ok',
        role: ROLE_PLAYER,
        playerId: session.playerId,
        roomId: this.roomId,
      });

      // 通知 Host 新玩家加入
      this._sendToHost({
        type: 'player_joined',
        playerId: session.playerId,
        name: session.name,
      });

      console.log(
        `[Room ${this.roomId}] Player connected: ${session.name} (${session.playerId})`
      );
    } else {
      this._send(ws, {
        type: 'error',
        message: `Invalid role: ${role}. Must be 'host' or 'player'.`,
      });
      ws.close(4004, 'Invalid role');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 信令转发
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  // Host → 指定 Player
  _relayToPlayer(msg) {
    const targetId = msg.playerId || msg.targetPlayerId;
    if (!targetId) return;

    for (const [ws, session] of this.sessions) {
      if (session.playerId === targetId && session.role === ROLE_PLAYER) {
        this._send(ws, msg);
        return;
      }
    }
  }

  // Player → Host
  _relayToHost(msg) {
    if (this.hostWs) {
      this._send(this.hostWs, msg);
    }
  }

  // ICE candidate：根据方向转发
  _relayIce(msg) {
    const { from } = msg;
    if (from === 'host') {
      this._relayToPlayer(msg);
    } else {
      this._relayToHost(msg);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 离开 / 房间关闭
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  _handleLeave(ws, session) {
    if (session.role === ROLE_HOST) {
      // Host 离开 → 通知所有 Player，关闭房间
      this._broadcast({
        type: 'room_closing',
        reason: 'Host left the room',
      });
      this._closeAll(4000, 'Host left');
    } else {
      // Player 离开 → 通知 Host
      this._sendToHost({
        type: 'player_left',
        playerId: session.playerId,
        name: session.name,
      });
    }
    this._removeSession(ws, session);
  }

  _onClose(ws, session) {
    this._handleLeave(ws, session);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 心跳 & 存活
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
        console.log(
          `[Room ${this.roomId}] Heartbeat timeout: ${session.name || session.playerId}`
        );
        this._removeSession(ws, session);
        try {
          ws.close(4005, 'Heartbeat timeout');
        } catch (_) {}
      }

      // 空闲房间清理
      if (
        this.sessions.size === 0 &&
        now - this.lastActivity > ROOM_IDLE_TIMEOUT_MS
      ) {
        console.log(`[Room ${this.roomId}] Idle timeout, destroying`);
        this._destroy();
      }
    }, 10_000); // 每 10 秒检查一次
  }

  _destroy() {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
    this._closeAll(4006, 'Room destroyed');
    this.sessions.clear();
    this.hostWs = null;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 工具
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  _send(ws, data) {
    try {
      ws.send(JSON.stringify(data));
    } catch (_) {
      // WebSocket 可能已关闭
    }
  }

  _sendToHost(data) {
    if (this.hostWs) {
      this._send(this.hostWs, data);
    }
  }

  _broadcast(data) {
    for (const [ws] of this.sessions) {
      this._send(ws, data);
    }
  }

  _removeSession(ws, session) {
    this.sessions.delete(ws);
    if (this.hostWs === ws) {
      this.hostWs = null;
    }
    try {
      ws.close();
    } catch (_) {}
  }

  _closeAll(code, reason) {
    for (const [ws] of this.sessions) {
      try {
        ws.close(code, reason);
      } catch (_) {}
    }
    this.sessions.clear();
    this.hostWs = null;
  }

  _generatePlayerId() {
    return `p_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
  }
}
