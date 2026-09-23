<script setup>
import { computed, onUnmounted, ref } from 'vue'
import GameInterface from './components/GameInterface.vue'

const gameName = __APP_TITLE__

// 关于浮窗是否打开
const showAbout = ref(false)

// 原版信息（依据 CC BY-NC 4.0 需标注署名、协议与修改说明）
const originalAuthor = '谦君'
const originalRepo = 'https://github.com/setube/idle-wild-my-survival-saga'
const licenseName = '知识共享署名-非商业性使用 4.0 国际许可协议（CC BY-NC 4.0）'
const licenseUrl = 'https://creativecommons.org/licenses/by-nc/4.0/'
const modifyDate = '2026-09-24'
const aiAssistant = 'TraeCode'
const aiModel = 'DeepSeek-V4.1-Flash'

// 视口宽度，用于浮窗自适应
const viewportWidth = ref(window.innerWidth)
const onViewportResize = () => {
  viewportWidth.value = window.innerWidth
}
window.addEventListener('resize', onViewportResize)
onUnmounted(() => window.removeEventListener('resize', onViewportResize))

// 手机端占满可用宽度，桌面端固定 520px
const aboutWidth = computed(() => (viewportWidth.value < 768 ? '94%' : '520px'))

// 新标签页打开原版地址
const openOriginal = () => {
  window.open(originalRepo, '_blank', 'noopener,noreferrer')
}
</script>

<template>
  <div class="app-container">
    <header class="app-header">
      <div class="app-logo">
        <el-button class="about-button" size="small" @click="showAbout = true">
          <el-icon>
            <InfoFilled />
          </el-icon>
          <span>关于</span>
        </el-button>
        <h1>{{ gameName }}</h1>
      </div>
    </header>
    <main class="app-main">
      <GameInterface />
    </main>
    <footer class="app-footer">
      <p>{{ gameName }}（作弊器版） &copy; 2026</p>
    </footer>

    <el-dialog v-model="showAbout" title="关于" :width="aboutWidth" top="8vh" append-to-body class="about-dialog">
      <div class="about-body">
        <h3 class="about-name">{{ gameName }}</h3>
        <p class="about-line">原作者：{{ originalAuthor }}</p>
        <p class="about-line">
          原版源码：<a :href="originalRepo" target="_blank" rel="noopener noreferrer">{{ originalRepo }}</a>
        </p>
        <p class="about-line">
          本作品采用<strong>{{ licenseName }}</strong>进行许可。本版本在原作者作品的基础上作了修改，并以相同协议非商业性分发。
        </p>
        <p class="about-line">
          查看协议副本：<a :href="licenseUrl" target="_blank" rel="noopener noreferrer">{{ licenseUrl }}</a>
        </p>
        <p class="about-line">修改内容：新增游戏修改器、主动操作与时间流速双倍速控制、移动端自适应等。</p>
        <p class="about-line">修改日期：{{ modifyDate }}</p>
        <p class="about-line">修改助力：感谢 {{ aiAssistant }}（AI 编程助手）与模型 {{ aiModel }} 协助完成本次修改。</p>
      </div>
      <template #footer>
        <el-button type="primary" @click="openOriginal">原版</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style>
:root {
  --app-bg-color: #f5f7fa;
  --app-text-color: #303133;
  /* 顶部标题栏高度，与原版保持一致 */
  --app-header-height: 47px;
}

a {
  text-decoration: inherit;
}

html.dark {
  --app-bg-color: #1e1e1e;
  --app-text-color: #e5eaf3;
}

body {
  margin: 0;
  padding: 0;
  font-family: 'Helvetica Neue', Helvetica, 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', '微软雅黑', Arial, sans-serif;
  background-color: var(--app-bg-color);
  color: var(--app-text-color);
  transition: background-color 0.3s, color 0.3s;
}

::-webkit-scrollbar {
  width: 6px;
  background: transparent;
}

::-webkit-scrollbar:horizontal {
  height: 6px
}

::-webkit-scrollbar-track {
  border-radius: 10px
}

::-webkit-scrollbar-thumb {
  background-color: #0003;
  border-radius: 10px;
  transition: all .2s ease-in-out
}

::-webkit-scrollbar-thumb:hover {
  cursor: pointer;
  background-color: #0000004d;
}
</style>

<style scoped>
.app-container {
  display: flex;
  flex-direction: column;
}

.app-header {
  position: fixed;
  width: 100%;
  height: var(--app-header-height);
  z-index: 3;
  background-color: var(--el-color-primary);
  box-shadow: 0px 5px 40px 0px rgba(17, 58, 93, .1);
}

.app-logo {
  display: flex;
  justify-content: flex-start;
  align-items: center;
  gap: 12px;
  height: 100%;
  padding: 0 20px;
  box-sizing: border-box;
  color: var(--el-color-white)
}

.app-logo h1 {
  margin: 0;
  font-size: 1.5rem;
  line-height: 1.2;
}

.about-button {
  --el-button-bg-color: transparent;
  --el-button-text-color: var(--el-color-white);
  --el-button-border-color: rgba(255, 255, 255, 0.6);
  --el-button-hover-bg-color: rgba(255, 255, 255, 0.2);
  --el-button-hover-text-color: var(--el-color-white);
  --el-button-hover-border-color: var(--el-color-white);
  --el-button-active-bg-color: rgba(255, 255, 255, 0.3);
  --el-button-active-text-color: var(--el-color-white);
  --el-button-active-border-color: var(--el-color-white);
}

.about-body {
  font-size: 0.9rem;
  line-height: 1.7;
}

.about-name {
  margin: 0 0 10px;
  font-size: 1.05rem;
}

.about-line {
  margin: 0 0 8px;
  word-break: break-all;
}

.about-line a {
  color: var(--el-color-primary);
}

.app-main {
  flex: 1;
  padding: 0;
  margin-top: var(--app-header-height);
}

.app-footer {
  text-align: center;
  padding: 10px;
  font-size: 0.8rem;
  background-color: var(--el-bg-color);
  color: var(--el-text-color-secondary);
}

@media (max-width: 768px) {
  .app-logo {
    padding: 0 12px;
    gap: 8px;
  }

  .app-logo h1 {
    font-size: 1.2rem;
  }
}
</style>
