# Roll & Roll — Cloudflare Worker 信令层

## 架构

```
Flutter App
    │
    │ WebSocket (wss://)
    │
    ▼
Worker (fetch)
    │ 路由到 Durable Object
    ▼
RoomDO (per-room 内存实例)
    ├── Host   (role="host")
    └── Player (role="player")
```

## 文件结构

```
worker/
  src/
    index.js       — 单文件 Worker + RoomDO（可直接粘贴 Dashboard 或 wrangler deploy）
  wrangler.toml.example  — 配置模板
  README.md
```

## 部署

### 方式 A：Wrangler CLI（推荐）

```bash
cd worker
cp wrangler.toml.example wrangler.toml
# 编辑 wrangler.toml，填你的 account_id
npx wrangler deploy
```

### 方式 B：Cloudflare Dashboard

1. 复制 `src/index.js` 全部内容
2. 粘贴到 Worker 编辑器
3. Settings → Variables → Durable Objects → 添加绑定：

| Binding name | Class name |
|-------------|------------|
| ROOM | RoomDO |

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

连接后先发 `auth`：

**Host:** `{"type":"auth","role":"host","name":"GM"}`
**Player:** `{"type":"auth","role":"player","name":"玩家名"}`

收到 `auth_ok` 后开始 WebRTC 信令交换。
