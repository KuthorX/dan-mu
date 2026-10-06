# DanMu

一个使用 **Godot 4** 从空白工程实现的东方风纵版弹幕游戏原型，现已扩展为 **双关完整流程 + 标题动画 / 难度选择 / 对话演出 / Boss 立绘 Spotlight**。

## 已实现内容

- 标题动画、难度选择、暂停、失败、双关通关、最高分保存
- 关前对话演出、Boss 相位 Spotlight 与程序化立绘
- 自机高速/低速移动、射击、Bomb、擦弹、火力成长
- 道具吸附、残机与复活无敌、Bomb 清弹与压 Boss
- 两关杂兵波次、两名多阶段 Boss、阶段间转场
- 程序化背景、程序化子弹/敌机/特效绘制
- **程序化音效与 BGM**，无外部音频资源依赖

## 语言 / Language

- 支持 **简体中文** 与 **English**。首次启动按系统语言自动选择（中文系统为中文，其余为英文）。
- 在标题界面按 `L` 或点击右上角的 `中文 / EN` 按钮切换语言，选择会保存在 `user://settings.cfg`。
- 文案位于 `i18n/translations.csv`（`keys,zh,en`），脚本中通过 `tr()` 引用。
- Supports Simplified Chinese and English. Press `L` (or click `中文 / EN`) on the title screen to switch; the choice is remembered.

## 操作

- `WASD / 方向键`：移动
- `Z / Space`：射击 / 确认
- `Shift`：低速移动（Focus）
- `X`：Bomb
- `Esc / P`：暂停

## 运行方式

1. 使用 **Godot 4.x** 打开本项目目录。
2. 直接运行项目。
3. 入口场景为 `scenes/main.tscn`。

## 结构

- `docs/PLAN.md`：实现计划书
- `scenes/main.tscn`：主场景入口
- `scripts/main.gd`：主流程、状态机、碰撞、关卡切换
- `scripts/stage_director.gd`：双关卡时间轴与 Boss 配置
- `scripts/boss.gd`：Boss 与阶段弹幕
- `scripts/player.gd`：玩家控制与射击
- `scripts/bullet.gd`：玩家弹/敌弹
- `scripts/enemy.gd`：杂兵逻辑
- `scripts/hud.gd`：HUD、菜单、转场、结算
- `scripts/background.gd`：双主题程序化背景
- `scripts/effect.gd`：爆炸、冲击波、火花特效
- `scripts/audio_manager.gd`：程序化 BGM 与音效
- `scripts/pickup.gd`：点数/火力道具
- `scripts/i18n.gd`：语言选择、切换与保存
- `i18n/translations.csv`：中英文翻译表

## 说明

本项目当前不依赖外部美术与音频资源，主要目标是把手感、流程、弹幕可读性和完成度先做出来。
