# 反应计时器 Reaction Timer (基于 VHDL 的 FPGA 实现)

本项目是一个基于 VHDL 硬件描述语言的反应时间测试器，部署于 FPGA 平台。它通过LED、数码管、蜂鸣器以及按键交互实现对反应时间的测量与提示反馈。



## 🚀 概述

本项目主要功能包括：

1. 生成随机延迟（2-6秒）

   💡 **注**：当前随机延迟采用固定计数实现（如需，可自行改进为真随机数）

2. 通过LED亮起提供视觉提示

3. 用户按键后记录反应时间

4. 在6位数码管显示结果

5. 通过LED矩阵/蜂鸣器提供状态反馈



## ⚙️ 硬件与开发环境

- **开发板**：HEDL-2 实验箱
- **开发工具**：Quartus II
- **系统时钟**：24 MHz
- **输入设备**：start、stop按键、复位按键
- **输出设备**：
  - LED 发光管（作为刺激提示）
  - LED 阵列（用于状态显示，如“准备”“犯规”等）
  - 数码管（显示反应时间，最多999ms）
  - 蜂鸣器（区分完成与犯规状态）

------

## ⚙️ 核心组件

1. **五状态有限状态机（FSM）**:
   - `READY`：初始状态（LED矩阵显示"准备"）
   - `RANDOM_DELAY`：2-6秒随机等待（LED熄灭）
   - `TIMING`：计时中（LED亮起，计数器运行）
   - `DONE`：测试完成（显示"完成"）
   - `VIOLATION`：违规操作（显示"犯规"）
2. **外设控制**:
   - 开始/停止按键（`start`, `stop`）
   - LED指示灯（视觉刺激）
   - 16×16 LED矩阵（状态提示）
   - 6位数码管（毫秒级时间显示）
   - 蜂鸣器（成功/违规不同音效）
3. **关键模块**:
   - 时钟分频器（24MHz→1kHz）
   - 随机延迟发生器（2-6秒）
   - 毫秒计时器（0-9999ms）
   - 显示驱动（LED矩阵+数码管）
   - 蜂鸣器控制器（1.2kHz音调）

------

## 🛠️ 使用说明

1. **复位**：
   系统进入`READY`状态，LED亮起，矩阵显示"准备"
2. **开始测试**：
   按下`start` → 进入`RANDOM_DELAY`状态（LED熄灭）
3. **反应测试**：
   LED亮起时(`TIMING`状态)立即按`stop`：
   - 有效：数码管显示反应时间（如"211"ms），矩阵显示"完成"，蜂鸣器提示
   - 超时：若未按键，计时器在9999ms停止
4. **违规处理**：
   在`RANDOM_DELAY`期间误按`stop`：
   - 矩阵显示"犯规"
   - LED以1Hz闪烁
   - 蜂鸣器输出1kHz脉冲音

------

## 🔌 硬件连接

|   信号    | 方向 |      说明       |
| :-------: | :--: | :-------------: |
|   `clk`   | 输入 |  24MHz系统时钟  |
|  `reset`  | 输入 |    全局复位     |
|  `start`  | 输入 |  开始测试按键   |
|  `stop`   | 输入 |  停止计时按键   |
|   `led`   | 输出 |   视觉刺激LED   |
| `led_row` | 输出 | LED矩阵行选信号 |
| `led_col` | 输出 |  LED矩阵列数据  |
|   `seg`   | 输出 | 数码管段选信号  |
|   `dig`   | 输出 | 数码管位选信号  |
| `buzzer`  | 输出 | 蜂鸣器控制信号  |

------

## 🧩 代码结构

```vhdl
ReactionTimeTester.vhd
├── 时钟分频器（24MHz → 1ms时钟）
├── 有限状态机（5状态切换）
├── 随机延迟发生器
├── 计时器模块（0-9999ms）
├── 数码管显示驱动
│   └── 数字-段码编码器
├── LED矩阵控制器
│   └── 字符点阵（"准","始","计","完","规"）
└── 蜂鸣器控制器
    ├── 1.2kHz持续音（完成）
    └── 1kHz脉冲音（违规）
```

