<script setup>
import { computed, onUnmounted, ref, watch } from 'vue'
import { useGameStore } from '../stores/gameStore'
import { ElMessage } from 'element-plus'

const gameStore = useGameStore()

// 修改器是否打开
const visible = ref(false)
// 当前标签页
const activeTab = ref('player')

// 视口宽度，用于浮窗自适应
const viewportWidth = ref(window.innerWidth)
const onViewportResize = () => {
	viewportWidth.value = window.innerWidth
}
window.addEventListener('resize', onViewportResize)

// 手机端浮窗占满可用宽度，桌面端固定 640px
const dialogWidth = computed(() => (viewportWidth.value < 768 ? '94%' : '640px'))

// 编辑草稿：打开浮窗时从当前存档快照，改动只落在草稿上，点「应用修改」才写回游戏
const createDraft = () => ({
	player: { ...gameStore.player },
	resources: { ...gameStore.resources },
	resourceLimits: { ...gameStore.resourceLimits },
	skills: Object.fromEntries(
		Object.entries(gameStore.newSkills).map(([key, skill]) => [key, { ...skill }])
	),
	gameTime: {
		day: gameStore.gameTime.day,
		hour: gameStore.gameTime.hour,
		minute: gameStore.gameTime.minute,
		activitySpeed: gameStore.gameTime.activitySpeed,
		timeScale: gameStore.gameTime.timeScale,
		activitySpeedGlobal: gameStore.gameTime.activitySpeedGlobal,
		timeScaleGlobal: gameStore.gameTime.timeScaleGlobal
	},
	gameState: gameStore.gameState
})

// 打开浮窗时的原始快照，用于判断哪些字段真的被改动过
const baseline = ref(createDraft())
const draft = ref(createDraft())

// 浮窗打开期间强制全局 1 倍速，同时重置快照与草稿
watch(visible, (open) => {
	gameStore.gameTime.modifierOpen = open
	if (open) {
		baseline.value = createDraft()
		draft.value = createDraft()
	}
})

onUnmounted(() => {
	window.removeEventListener('resize', onViewportResize)
	// 组件卸载时解除 1 倍速强制
	gameStore.gameTime.modifierOpen = false
})

// 所有资源键
const resourceKeys = computed(() => Object.keys(draft.value.resources))

// 所有技能（过滤掉异常数据）
const skillEntries = computed(() =>
	Object.entries(draft.value.skills).filter(([, skill]) => skill && typeof skill === 'object')
)

// 时间流速选项
const timeScaleOptions = [
	{ label: '正常 (1x)', value: 1 },
	{ label: '快速 (2x)', value: 2 },
	{ label: '极速 (5x)', value: 5 },
	{ label: '超速 (10x)', value: 10 },
	{ label: '闪电 (20x)', value: 20 }
]

// 一键回满健康与体力（只改草稿）
const fullHealth = () => {
	draft.value.player.health = draft.value.player.maxHealth
	draft.value.player.energy = draft.value.player.maxEnergy
	ElMessage.success('健康与体力已填好，点「应用修改」生效')
}

// 一键补满所有资源（只改草稿）
const fillResources = () => {
	const { resources, resourceLimits } = draft.value
	for (const key of Object.keys(resources)) {
		resources[key] = resourceLimits[key] ?? resources[key]
	}
	ElMessage.success('资源已补满，点「应用修改」生效')
}

// 一键技能满级（只改草稿）
const maxSkills = () => {
	for (const [, skill] of skillEntries.value) {
		skill.level = 10
		skill.exp = 0
	}
	ElMessage.success('技能已设为 10 级，点「应用修改」生效')
}

// 草稿里的倍速联动：任一联动开启时两项保持同步
const setDraftActivitySpeed = (value) => {
	const gameTime = draft.value.gameTime
	gameTime.activitySpeed = value
	if (gameTime.activitySpeedGlobal || gameTime.timeScaleGlobal) gameTime.timeScale = value
}

const setDraftClockSpeed = (value) => {
	const gameTime = draft.value.gameTime
	gameTime.timeScale = value
	if (gameTime.timeScaleGlobal || gameTime.activitySpeedGlobal) gameTime.activitySpeed = value
}

const toggleDraftActivityGlobal = () => {
	const gameTime = draft.value.gameTime
	gameTime.activitySpeedGlobal = !gameTime.activitySpeedGlobal
	if (gameTime.activitySpeedGlobal) gameTime.timeScale = gameTime.activitySpeed
}

const toggleDraftTimeScaleGlobal = () => {
	const gameTime = draft.value.gameTime
	gameTime.timeScaleGlobal = !gameTime.timeScaleGlobal
	if (gameTime.timeScaleGlobal) gameTime.activitySpeed = gameTime.timeScale
}

// 应用修改：把草稿写回游戏并存档
const applyAndSave = () => {
	const d = draft.value
	Object.assign(gameStore.player, d.player)
	Object.assign(gameStore.resources, d.resources)
	Object.assign(gameStore.resourceLimits, d.resourceLimits)
	for (const [key, skill] of Object.entries(d.skills)) {
		if (gameStore.newSkills[key]) Object.assign(gameStore.newSkills[key], skill)
	}
	Object.assign(gameStore.gameTime, {
		day: d.gameTime.day,
		hour: d.gameTime.hour,
		minute: d.gameTime.minute,
		activitySpeed: d.gameTime.activitySpeed,
		timeScale: d.gameTime.timeScale,
		activitySpeedGlobal: d.gameTime.activitySpeedGlobal,
		timeScaleGlobal: d.gameTime.timeScaleGlobal
	})
	gameStore.gameState = d.gameState
	gameStore.saveGame()
	ElMessage.success('修改已应用并保存')
	visible.value = false
}
</script>

<template>
	<div class="modifier">
		<el-tooltip content="游戏修改器" placement="left">
			<el-button class="modifier-fab" type="warning" circle size="large" @click="visible = true">
				<el-icon>
					<MagicStick />
				</el-icon>
			</el-button>
		</el-tooltip>
		<el-dialog v-model="visible" :width="dialogWidth" top="6vh" append-to-body class="modifier-dialog">
			<template #header>
				<div class="modifier-header">
					<span class="modifier-title">游戏修改器</span>
					<span class="modifier-header-tip">浮窗打开期间游戏按全局 1 倍速运行，点「应用修改」后按新设定执行，点「关闭」放弃本次修改</span>
				</div>
			</template>
			<div class="modifier-tip">改动不会立即生效，点「应用修改」后写入游戏并存档；点「关闭」放弃本次修改。</div>
			<el-tabs v-model="activeTab">
				<el-tab-pane label="玩家" name="player">
					<el-form label-width="110px" size="small">
						<el-form-item label="幸存者等级">
							<el-input-number v-model="draft.player.level" :min="1" :max="99999" controls-position="right" />
						</el-form-item>
						<el-form-item label="当前经验">
							<el-input-number v-model="draft.player.exp" :min="0" :max="99999999" controls-position="right" />
						</el-form-item>
						<el-form-item label="升级所需经验">
							<el-input-number v-model="draft.player.expToNextLevel" :min="1" :max="99999999" controls-position="right" />
						</el-form-item>
						<el-form-item label="健康">
							<el-input-number v-model="draft.player.health" :min="0" :max="999999" controls-position="right" />
						</el-form-item>
						<el-form-item label="最大健康">
							<el-input-number v-model="draft.player.maxHealth" :min="1" :max="999999" controls-position="right" />
						</el-form-item>
						<el-form-item label="体力">
							<el-input-number v-model="draft.player.energy" :min="0" :max="999999" controls-position="right" />
						</el-form-item>
						<el-form-item label="最大体力">
							<el-input-number v-model="draft.player.maxEnergy" :min="1" :max="999999" controls-position="right" />
						</el-form-item>
						<el-form-item label="生存天数">
							<el-input-number v-model="draft.player.days" :min="0" :max="99999" controls-position="right" />
						</el-form-item>
						<el-form-item label="探索次数">
							<el-input-number v-model="draft.player.explorationCount" :min="0" :max="999999" controls-position="right" />
						</el-form-item>
					</el-form>
					<div class="quick-actions">
						<el-button type="primary" size="small" @click="fullHealth">回满健康与体力</el-button>
					</div>
				</el-tab-pane>

				<el-tab-pane label="资源" name="resource">
					<div class="row row-head">
						<span class="row-name">资源</span>
						<span class="row-label">数量</span>
						<span class="row-label">上限</span>
						<span class="row-label"></span>
					</div>
					<div class="scroll-area">
						<div class="row" v-for="key in resourceKeys" :key="key">
							<span class="row-name">{{ gameStore.getResourceName(key) }}</span>
							<el-input-number v-model="draft.resources[key]" :min="0" :max="999999" size="small"
								controls-position="right" />
							<el-input-number v-model="draft.resourceLimits[key]" :min="0" :max="999999" size="small"
								controls-position="right" />
							<el-button size="small" @click="draft.resources[key] = draft.resourceLimits[key]">满</el-button>
						</div>
					</div>
					<div class="quick-actions">
						<el-button type="primary" size="small" @click="fillResources">补满全部资源</el-button>
					</div>
				</el-tab-pane>

				<el-tab-pane label="技能" name="skill">
					<div class="row row-head">
						<span class="row-name">技能</span>
						<span class="row-label">等级</span>
						<span class="row-label">经验</span>
						<span class="row-label">升级需</span>
					</div>
					<div class="row" v-for="[key, skill] in skillEntries" :key="key">
						<span class="row-name">{{ gameStore.getResourceName(skill.name || key) }}</span>
						<el-input-number v-model="skill.level" :min="0" :max="99999" size="small" controls-position="right" />
						<el-input-number v-model="skill.exp" :min="0" :max="99999999" size="small" controls-position="right" />
						<el-input-number v-model="skill.expToNextLevel" :min="1" :max="99999999" size="small"
							controls-position="right" />
					</div>
					<div class="quick-actions">
						<el-button type="primary" size="small" @click="maxSkills">全部技能满级</el-button>
					</div>
				</el-tab-pane>

				<el-tab-pane label="时间与状态" name="time">
					<el-form label-width="110px" size="small">
						<el-form-item label="天数">
							<el-input-number v-model="draft.gameTime.day" :min="1" :max="99999" controls-position="right" />
						</el-form-item>
						<el-form-item label="小时">
							<el-input-number v-model="draft.gameTime.hour" :min="0" :max="23" controls-position="right" />
						</el-form-item>
						<el-form-item label="分钟">
							<el-input-number v-model="draft.gameTime.minute" :min="0" :max="59" controls-position="right" />
						</el-form-item>
						<el-form-item label="主动操作">
							<div class="speed-row">
								<el-select :model-value="draft.gameTime.activitySpeed"
									@update:model-value="setDraftActivitySpeed"
									:disabled="draft.gameTime.timeScaleGlobal && !draft.gameTime.activitySpeedGlobal">
									<el-option v-for="option in timeScaleOptions" :key="option.value" :label="option.label"
										:value="option.value" />
								</el-select>
								<el-tooltip
									:content="draft.gameTime.activitySpeedGlobal ? '已联动全局：另一项同步为相同倍速' : '仅作用于主动操作，点击可与时间流速联动'"
									placement="top">
									<el-button :type="draft.gameTime.activitySpeedGlobal ? 'primary' : 'default'"
										@click="toggleDraftActivityGlobal">
										<el-icon>
											<Link />
										</el-icon>
									</el-button>
								</el-tooltip>
							</div>
						</el-form-item>
						<el-form-item label="时间流速">
							<div class="speed-row">
								<el-select :model-value="draft.gameTime.timeScale"
									@update:model-value="setDraftClockSpeed"
									:disabled="draft.gameTime.activitySpeedGlobal && !draft.gameTime.timeScaleGlobal">
									<el-option v-for="option in timeScaleOptions" :key="option.value" :label="option.label"
										:value="option.value" />
								</el-select>
								<el-tooltip
									:content="draft.gameTime.timeScaleGlobal ? '已联动全局：另一项同步为相同倍速' : '仅作用于时间流速，点击可与主动操作联动'"
									placement="top">
									<el-button :type="draft.gameTime.timeScaleGlobal ? 'primary' : 'default'"
										@click="toggleDraftTimeScaleGlobal">
										<el-icon>
											<Link />
										</el-icon>
									</el-button>
								</el-tooltip>
							</div>
						</el-form-item>
						<el-form-item label="游戏状态">
							<el-select v-model="draft.gameState">
								<el-option label="进行中" value="playing" />
								<el-option label="已暂停" value="paused" />
							</el-select>
						</el-form-item>
					</el-form>
					<div class="modifier-tip">
						「主动操作」加速采集/收集、建造、研究、探索、技能学习等由你主动发起的操作；「时间流速」按原模式加速时钟、生存消耗、天气与随机事件等。点击右侧的联动按钮（链条图标，变蓝即已联动）可把该倍速应用到全局，另一项会自动同步。已在进行的操作不会中途变速。
					</div>
				</el-tab-pane>
			</el-tabs>
			<template #footer>
				<el-button @click="visible = false">关闭</el-button>
				<el-button type="primary" @click="applyAndSave">应用修改</el-button>
			</template>
		</el-dialog>
	</div>
</template>

<style scoped>
.modifier-fab {
	position: fixed;
	right: 24px;
	bottom: 24px;
	z-index: 2000;
	box-shadow: 0 4px 12px rgba(0, 0, 0, 0.25);
}

.modifier-tip {
	margin-bottom: 8px;
	font-size: 0.85em;
	color: var(--el-text-color-secondary);
}

.row {
	display: flex;
	align-items: center;
	gap: 8px;
	padding: 4px 0;
}

.row-head {
	font-size: 0.8em;
	color: var(--el-text-color-secondary);
	border-bottom: 1px solid var(--el-border-color-lighter);
	margin-bottom: 4px;
}

.row-name {
	flex: 1;
	min-width: 80px;
	font-size: 0.9em;
}

.row-label {
	width: 120px;
	text-align: center;
	font-size: 0.85em;
}

.scroll-area {
	max-height: 380px;
	overflow-y: auto;
}

.quick-actions {
	margin-top: 12px;
	display: flex;
	gap: 10px;
}

.speed-row {
	display: flex;
	align-items: center;
	gap: 8px;
	width: 100%;
}

.speed-row .el-select {
	flex: 1;
}

.modifier-header {
	display: flex;
	flex-direction: column;
	gap: 2px;
	padding-right: 24px;
}

.modifier-title {
	font-size: 1.05em;
	font-weight: 600;
}

.modifier-header-tip {
	font-size: 0.78em;
	font-weight: 400;
	color: var(--el-text-color-secondary);
	line-height: 1.4;
}

/* 手机端自适应：浮窗内容与行内控件改为可收缩布局 */
@media (max-width: 768px) {
	.modifier-fab {
		right: 16px;
		bottom: 16px;
	}

	.modifier-dialog :deep(.el-dialog__body) {
		max-height: 68vh;
		overflow-y: auto;
		padding: 12px;
	}

	.row {
		gap: 4px;
	}

	.row-name {
		min-width: 48px;
		font-size: 0.85em;
	}

	.row-label {
		width: auto;
		flex: 1;
		min-width: 0;
		font-size: 0.78em;
	}

	.row :deep(.el-input-number) {
		flex: 1;
		width: 100%;
		min-width: 0;
	}

	.row :deep(.el-button) {
		flex: none;
		padding: 4px 8px;
	}

	.quick-actions {
		flex-wrap: wrap;
	}

	.scroll-area {
		max-height: 46vh;
	}
}
</style>
