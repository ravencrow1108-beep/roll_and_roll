# Roll & Roll — Cloudflare Worker 信令层

## 架构

```
Flutter App
    │
    │ WebSocket (wss://)
    │
    ▼
Cloudflare Worker (fetch)
    │
    │ 路由到 Durable Object
    │
    ▼
RoomDO (per-room instance)
    │
    ├── Host WebSocket   (role="host")
    └── Player WebSocket (role="player")
```

## 文件结构

```
worker/
  src/
    index.js       — Worker 入口（HTTP 路由 + WebSocket 升级）
    room-do.js     — Durable Object（房间信令中继）
  wrangler.toml.example  — 配置模板
  README.md
```

## 部署

### 1. 安装 Wrangler

```bash
npm install -g wrangler
```

### 2. 创建 wrangler.toml

```bash
cp wrangler.toml.example wrangler.toml
```

编辑 `wrangler.toml`，填入你的 `account_id`：

```toml
account_id = "你的Cloudflare账号ID"
```

### 3. 部署

```bash
cd worker
npx wrangler deploy
```

### 4. 验证

```bash
# 创建房间
curl -X POST https://你的域名.workers.dev/createRoom

# 返回: {"success":true,"roomId":"ABC123"}
```

## API

### HTTP

| Method | Path | 说明 |
|--------|------|------|
| POST | `/createRoom` | 创建房间，返回 `{roomId}` |
| GET | `/health` | 健康检查 |

### WebSocket

| 地址 | 说明 |
|------|------|
| `wss://域名/room/{roomId}` | 连接房间 |

### 信令消息

连接后先发送 `auth` 鉴权：

**Host:**
```json
{"type":"auth","role":"host","name":"GM"}
```

**Player:**
```json
{"type":"auth","role":"player","name":"玩家名"}
```

收到确认后即可交换 WebRTC 信令：

```json
{"type":"offer","sdp":"...","targetPlayerId":"p_xxx"}
{"type":"answer","sdp":"..."}
{"type":"iceCandidate","candidate":"...","sdpMid":"0","sdpMLineIndex":0}
```

## 安全注意

以下文件不应提交到 git（已在 .gitignore 中）：

- `worker/wrangler.toml`（含 account_id）
- `worker/.dev.vars`
- `worker/.env`
