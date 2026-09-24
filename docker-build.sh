#!/usr/bin/env bash
# 本地 Docker 构建脚本
# 用法：
#   ./docker-build.sh              # 构建镜像（latest + 版本号 双 tag）
#   ./docker-build.sh --push       # 构建并推送到 Docker Hub
#   ./docker-build.sh --run        # 构建并启动容器（端口 2543）
#   ./docker-build.sh --push --run # 构建、推送并启动
set -euo pipefail

cd "$(dirname "$0")"

IMAGE_NAME="temp2580/iwms"
HOST_PORT=2543
CONTAINER_NAME="idle-wild-my-survival-saga"

DO_PUSH=false
DO_RUN=false
for arg in "$@"; do
  case "$arg" in
    --push) DO_PUSH=true ;;
    --run)  DO_RUN=true ;;
    -h|--help)
      sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "未知参数: $arg（可用: --push --run）" >&2; exit 1 ;;
  esac
done

# 从 package.json 读取版本号，生成 vX.Y.Z 形式 tag
VERSION="$(node -p "require('./package.json').version")"
VERSION_TAG="v${VERSION}"

echo "==> 镜像: ${IMAGE_NAME}"
echo "==> 标签: latest, ${VERSION_TAG}"

echo "==> 构建镜像..."
docker build \
  -t "${IMAGE_NAME}:latest" \
  -t "${IMAGE_NAME}:${VERSION_TAG}" \
  .

if [ "$DO_PUSH" = true ]; then
  echo "==> 推送到 Docker Hub..."
  docker push "${IMAGE_NAME}:latest"
  docker push "${IMAGE_NAME}:${VERSION_TAG}"
fi

if [ "$DO_RUN" = true ]; then
  echo "==> 停止并移除旧容器（若存在）..."
  docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

  echo "==> 启动容器，端口 ${HOST_PORT}..."
  docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    -p "${HOST_PORT}:2543" \
    "${IMAGE_NAME}:latest"

  echo "==> 已启动，访问 http://localhost:${HOST_PORT}"
fi

echo "==> 完成。"
