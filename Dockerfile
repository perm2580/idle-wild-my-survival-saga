FROM node:latest

WORKDIR /app

# 安装 dumb-init：作为 PID 1 处理 SIGTERM/SIGINT，转发给 vite preview
# 否则 npx/vite 不处理信号，docker stop 会等到 10 秒超时后被 SIGKILL → 退出码 137
RUN apt-get update \
 && apt-get install -y --no-install-recommends dumb-init \
 && rm -rf /var/lib/apt/lists/*

RUN npm config set registry https://registry.npmmirror.com

# 先安装依赖，利用 Docker 层缓存
COPY package.json pnpm-lock.yaml ./
# 固定 pnpm 9：新版 pnpm 默认禁止依赖执行构建脚本（esbuild 等）会导致安装失败
RUN npm install -g pnpm@9 && pnpm install

# 复制本地源码（含修改器改动）
COPY . .

RUN npx vite build

ENTRYPOINT ["dumb-init", "--"]
CMD ["npx", "vite", "preview", "--host", "0.0.0.0", "--port", "2543"]
