<script setup>
import { useGameStore } from '../stores/gameStore'

const gameStore = useGameStore()
</script>

<template>
  <div class="event-log-panel">
    <h3>事件日志</h3>
    <el-scrollbar max-height="500" class="event-log">
      <div v-for="(entry, index) in gameStore.eventLog" :key="index" class="log-entry">
        <span class="log-timestamp">{{ entry.timestamp }}：</span>
        <span class="log-message" :title="entry.message">{{ entry.message }}</span>
      </div>
    </el-scrollbar>
  </div>
</template>

<style scoped>
.event-log-panel {
  background-color: var(--el-bg-color-overlay);
  border-radius: 4px;
  padding: 15px;
}

.event-log-panel h3 {
  margin: 0 0 10px;
  font-size: 1em;
}

/* 一条日志一行：时间：<日志信息> */
.log-entry {
  display: flex;
  align-items: baseline;
  padding: 6px 0;
  border-bottom: 1px solid var(--el-border-color-lighter);
  font-size: 0.9em;
}

.log-entry:last-child {
  border-bottom: none;
}

.log-timestamp {
  flex: none;
  color: var(--el-text-color-secondary);
}

.log-message {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}

@media (max-width: 768px) {
  /* 移动端压缩日志面板高度 */
  .event-log-panel {
    padding: 8px 10px;
  }

  .event-log-panel h3 {
    margin: 0 0 6px;
    font-size: 0.9em;
  }

  .log-entry {
    padding: 4px 0;
    font-size: 0.8em;
  }

  .event-log :deep(.el-scrollbar__wrap) {
    max-height: 132px !important;
  }
}
</style>
