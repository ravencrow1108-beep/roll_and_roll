// ═══════════════════════════════════════════════════════════════
// Roll & Roll — Cloudflare Worker + Durable Object 信令层
//
// 职责：
//   - POST /createRoom → 生成房间号
//   - WebSocket /room/{roomId} → 升级到 RoomDO
//
// 信令消息格式：
//   { "type":"auth|offer|answer|iceCandidate|heartbeat|...", ... }
//
// 部署：
//   npx wrangler deploy
// ═══════════════════════════════════════════════════════════════

export { RoomDO } from './room-do';

// ─── 房间 ID 生成 ───
function generateRoomId() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 去掉 0/O/1/I 避免混淆
  let id = '';
  for (let i = 0; i < 6; i++) {
    id += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return id;
}

// ─── CORS headers ───
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

// ─── Worker 入口 ───
export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // CORS 预检
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // ── 创建房间 ──
    if (request.method === 'POST' && url.pathname === '/createRoom') {
      const roomId = generateRoomId();

      // 可选：初始化 DO（触发 constructor）
      const doId = env.ROOM.idFromName(roomId);
      const stub = env.ROOM.get(doId);

      // 通过 stub 发送一条 init 请求来初始化 DO
      await stub.fetch(
        new Request('https://do.internal/init', {
          method: 'POST',
          body: JSON.stringify({ roomId }),
        })
      );

      return Response.json(
        { success: true, roomId },
        { headers: corsHeaders }
      );
    }

    // ── WebSocket 连接 (Host / Player) ──
    if (url.pathname.startsWith('/room/')) {
      const roomId = url.pathname.split('/')[2];
      if (!roomId) {
        return Response.json(
          { success: false, message: 'Missing roomId' },
          { status: 400, headers: corsHeaders }
        );
      }

      // 升级要求：WebSocket
      const upgrade = request.headers.get('Upgrade');
      if (!upgrade || upgrade !== 'websocket') {
        return Response.json(
          {
            success: false,
            message:
              'This endpoint requires WebSocket. Use wss:// to connect.',
          },
          { status: 426, headers: corsHeaders }
        );
      }

      // 路由到 Durable Object
      const doId = env.ROOM.idFromName(roomId);
      const stub = env.ROOM.get(doId);
      return stub.fetch(request);
    }

    // ── 健康检查 ──
    if (url.pathname === '/health') {
      return Response.json({ status: 'ok' }, { headers: corsHeaders });
    }

    return Response.json(
      { success: false, message: 'Not Found' },
      { status: 404, headers: corsHeaders }
    );
  },
};
