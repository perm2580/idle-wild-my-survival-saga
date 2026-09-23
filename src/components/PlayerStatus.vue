<script setup>
import { computed } from 'vue'
import { useGameStore } from '../stores/gameStore'
import { skills } from '../plugins/skillTree'

const gameStore = useGameStore()

// 计算玩家属性百分比
const healthPercentage = computed(() => {
	return Math.min(100, (gameStore.player.health / gameStore.player.maxHealth) * 100)
})

const energyPercentage = computed(() => {
	return Math.min(100, (gameStore.player.energy / gameStore.player.maxEnergy) * 100)
})

// 计算健康状态文本和颜色
const healthStatus = computed(() => {
	if (healthPercentage.value > 70) return { text: '健康', color: '#67C23A' }
	if (healthPercentage.value > 30) return { text: '受伤', color: '#E6A23C' }
	return { text: '危险', color: '#F56C6C' }
})

// 计算体力状态文本和颜色
const energyStatus = computed(() => {
	if (energyPercentage.value > 70) return { text: '精力充沛', color: '#67C23A' }
	if (energyPercentage.value > 30) return { text: '有些疲惫', color: '#E6A23C' }
	return { text: '精疲力尽', color: '#F56C6C' }
})

// 计算玩家技能总和
const totalSkillLevel = computed(() => {
  const validSkills = Object.values(gameStore.newSkills).map((item, index) => {
    if (typeof item === 'string') {
      return Object.values(skills)[index]
    }
    return item
  })
  return validSkills.reduce((sum, skill) => sum + skill.level, 0)
})

const plusPlayerHealth = () => {
	if (!gameStore.resources.medicine) {
		ElMessage.error('药品不足')
		return
	}
	if (gameStore.player.health === gameStore.player.maxHealth) {
		ElMessage.error('暂时不需要药品恢复健康')
		return
	}
	const healAmount = Math.min(Math.floor(gameStore.player.maxHealth * 0.1), gameStore.player.maxHealth)
	gameStore.player.health += healAmount
	gameStore.resources.medicine -= 1
	gameStore.addToEventLog('你使用了药品，恢复了10%健康')
}

// 提升人口
const checkLevelUp = () => {
	while (gameStore.player.exp >= gameStore.player.expToNextLevel) {
		gameStore.player.exp -= gameStore.player.expToNextLevel
		gameStore.player.level += 1
		// 增加下一级所需经验
		gameStore.player.expToNextLevel = Math.floor(gameStore.player.expToNextLevel * 1.5)
		// 升级奖励
		gameStore.player.maxHealth += gameStore.player.maxHealth * 0.05
		gameStore.player.health = gameStore.player.maxHealth
		gameStore.player.maxEnergy += gameStore.player.maxEnergy * 0.05
		gameStore.player.energy = gameStore.player.maxEnergy
		gameStore.addToEventLog(`幸存者增加了！当前幸存者: ${gameStore.player.level}人`)
	}
}
</script>

<template>
	<div class="player-status">
		<div class="stat-item">
			<div class="stat-label">
				<span class="stat-icon">👨‍🔧</span>
				<span>幸存者</span>
				<span class="stat-icon-plus" @click="checkLevelUp"
					v-if="gameStore.player.exp >= gameStore.player.expToNextLevel">
					<el-icon>
						<Plus />
					</el-icon>
				</span>
				<span class="stat-value">{{ gameStore.player.level }}人</span>
			</div>
			<el-progress :percentage="Math.min(100, (gameStore.player.exp / gameStore.player.expToNextLevel) * 100)" :show-text="false"
				:stroke-width="10" color="#8e44ad" />
		</div>
		<div class="player-stats">
			<div class="stat-item">
				<div class="stat-label">
					<span class="stat-icon">❤️</span>
					<span>健康</span>
					<span class="stat-icon-plus" @click="plusPlayerHealth"
						v-if="gameStore.player.health !== gameStore.player.maxHealth">
						<el-icon>
							<Plus />
						</el-icon>
					</span>
					<span class="stat-value">{{ Math.floor(gameStore.player.health) }}/{{ Math.floor(gameStore.player.maxHealth)
					}}</span>
				</div>
				<el-progress :percentage="healthPercentage" :color="healthStatus.color" :stroke-width="15" :show-text="false" />
				<div class="stat-status" :style="{ color: healthStatus.color }">
					{{ healthStatus.text }}
				</div>
			</div>
			<div class="stat-item">
				<div class="stat-label">
					<span class="stat-icon">⚡</span>
					<span>体力</span>
					<span class="stat-value">{{ Math.floor(gameStore.player.energy) }}/{{ Math.floor(gameStore.player.maxEnergy)
					}}</span>
				</div>
				<el-progress :percentage="energyPercentage" :color="energyStatus.color" :stroke-width="15" :show-text="false" />
				<div class="stat-status" :style="{ color: energyStatus.color }">
					{{ energyStatus.text }}
				</div>
			</div>
		</div>
		<div class="player-skills">
			<h4>技能 <span class="skill-total">(总等级: {{ totalSkillLevel }})</span></h4>
			<div class="skill-grid">
				<div v-for="(item, index) in Object.values(gameStore.newSkills)" :key="index" class="skill-item">
					<div class="skill-name">{{ gameStore.getResourceName(item.name) }}</div>
					<div class="skill-level">Lv.{{ item.level }}</div>
					<div class="skill-progress-bar">
						<div class="progress-fill" :style="{ width: (item.exp / item.expToNextLevel) * 100 + '%' }"></div>
					</div>
				</div>
			</div>
		</div>
		<div class="survival-info">
			<div class="survival-item">
				<span class="survival-icon">📅</span>
				<span>生存天数: {{ gameStore.player.days }}</span>
			</div>
			<div class="survival-item">
				<span class="survival-icon">🔄</span>
				<span>四季循环: {{ Math.floor(gameStore.player.days / 120) }}</span>
			</div>
		</div>
	</div>
</template>

<style scoped>
.player-status {
	background-color: var(--el-bg-color-overlay);
	border-radius: 4px;
	padding: 15px;
}

.player-stats {
	margin-bottom: 20px;
}

.stat-item {
	margin-bottom: 12px;
}

.stat-label {
	display: flex;
	align-items: center;
	margin-bottom: 5px;
}

.stat-icon {
	margin-right: 8px;
	font-size: 1.2em;
}

.stat-value {
	margin-left: auto;
	font-size: 0.9em;
	color: var(--el-text-color-secondary);
}

.stat-status {
	font-size: 0.8em;
	text-align: right;
	margin-top: 2px;
	font-weight: bold;
}

.stat-icon-plus {
	display: flex;
	align-items: center;
	margin-left: 10px;
}

.player-skills h4 {
	margin-top: 0;
	margin-bottom: 10px;
	display: flex;
	align-items: center;
}

.skill-total {
	font-size: 0.8em;
	color: var(--el-text-color-secondary);
	margin-left: 10px;
	font-weight: normal;
}

.skill-grid {
	display: grid;
	grid-template-columns: repeat(3, 1fr);
	gap: 10px;
}

.skill-item {
	background-color: var(--el-bg-color);
	padding: 8px;
	border-radius: 4px;
	display: flex;
	flex-wrap: wrap;
	justify-content: space-between;
	align-items: center;
}

.skill-name {
	font-size: 0.9em;
}

.skill-level {
	font-weight: bold;
	color: #409EFF;
}

.skill-progress-bar {
	height: 4px;
	width: 100%;
	background-color: var(--el-border-color-lighter);
	border-radius: 2px;
	overflow: hidden;
	margin: 2px 0;
}

.progress-fill {
	height: 100%;
	background-color: var(--el-color-primary);
	border-radius: 2px;
}

.survival-info {
	margin-top: 20px;
	display: flex;
	justify-content: space-between;
}

.survival-item {
	display: flex;
	align-items: center;
}

.survival-icon {
	margin-right: 8px;
}

@media (max-width: 768px) {
	.player-status {
		padding: 10px;
	}

	/* 窄列下健康/体力改为上下两行，各占满左列宽，避免文字换行 */
	.player-stats {
		margin-bottom: 12px;
	}

	.stat-item {
		margin-bottom: 10px;
	}

	.stat-icon {
		margin-right: 4px;
		font-size: 1em;
	}

	.stat-value {
		font-size: 0.8em;
	}

	.stat-status {
		font-size: 0.72em;
	}

	.skill-grid {
		grid-template-columns: repeat(2, minmax(0, 1fr));
		gap: 6px;
	}

	.skill-item {
		padding: 6px;
	}

	/* 窄列下生存信息改为上下排列，避免文字被拆行 */
	.survival-info {
		margin-top: 12px;
		flex-direction: column;
		gap: 6px;
	}
}
</style>