# 多阶段构建：最终镜像只含静态产物，彻底剔除 node_modules / 源码 / 构建工具链
# 解决「实例装进 Docker 后产生巨量小文件」问题（运行期仅需 docs/ 下数个静态文件）

# ---- builder：完整安装依赖并构建，产物在 /app/docs ----
FROM node:22-bookworm-slim AS builder
WORKDIR /app
RUN npm config set registry https://registry.npmmirror.com
# 固定 pnpm 9：新版 pnpm 默认禁止依赖执行构建脚本（esbuild 等）会导致安装失败
RUN npm install -g pnpm@9
# 仅复制清单，利用 Docker 层缓存；frozen 保证 lockfile 与 package.json 一致
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
# 复制本地源码（.dockerignore 已排除 node_modules/.git/docs/.github）
COPY . .
RUN npx vite build                      # 输出到 docs/（outDir 见 vite.config.js）

# ---- runtime：极简静态服务器，文件数较旧版降约 99% ----
FROM nginx:1.27-alpine AS runtime
# dumb-init 作 PID1 转发 SIGTERM，nginx 优雅停止并 exit 0（无 143 红字）
RUN apk add --no-cache dumb-init
# 用项目构建产物覆盖默认站点
COPY --from=builder /app/docs /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
ENTRYPOINT ["dumb-init", "--"]
CMD ["nginx", "-g", "daemon off;"]
