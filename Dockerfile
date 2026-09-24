FROM node:latest

WORKDIR /app

RUN npm config set registry https://registry.npmmirror.com

# 先安装依赖，利用 Docker 层缓存
COPY package.json pnpm-lock.yaml ./
# 固定 pnpm 9：新版 pnpm 默认禁止依赖执行构建脚本（esbuild 等）会导致安装失败
RUN npm install -g pnpm@9 && pnpm install

# 复制本地源码（含修改器改动）
COPY . .

RUN npx vite build

CMD ["npx", "vite", "preview", "--host", "0.0.0.0", "--port", "2543"]
