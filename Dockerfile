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
# vite preview 收到 SIGTERM 会返回 143（Node 默认把退出码设成 128+signal_number）
# 旧写法 sh -c "... || case $? in 143|0) exit 0..." 无效：
# dumb-init 是按「进程组」群发 SIGTERM，sh 自己也会被信号打死（退出 143），`|| case` 分支根本没机会执行。
# 正确做法：sh 显式捕获 TERM/INT 并直接 exit 0；vite 放后台用 wait 等。进程崩溃时错误码仍原样透出。
CMD ["sh", "-c", "trap 'exit 0' TERM INT; npx vite preview --host 0.0.0.0 --port 2543 & wait"]
