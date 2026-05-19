# NoMachine 极简部署指南

## ⚠️ 必须满足的条件（缺一不可）

1. ✅ **Mac、机器人、平板在同一个 WiFi 热点**（最重要！）
2. ✅ **知道机器人 IP 地址**（如 `192.168.43.100`）
3. ✅ **知道平板 IP 地址**（如 `192.168.43.224`）
4. ✅ **平板 App 的 Config.java 中 ROBOT_IP 改为机器人 IP**

---

## 🚀 5 步完成（15 分钟）

### 步骤 1：Mac 安装 NoMachine
- 下载：https://www.nomachine.com/download
- 选择 macOS → 安装

### 步骤 2：获取机器人和平板 IP
```bash
# SSH 登录机器人（替换成你的 IP）
ssh ubuntu@192.168.43.100

# 查看机器人 IP
ip addr show wlan0
# 记录：192.168.43.100

# 在平板上查看 IP（设置 → WiFi → 当前网络详情）
# 记录：192.168.43.224
```

### 步骤 3：机器人安装 NoMachine
```bash
# 在机器人上执行（SSH 登录后）

# ARM64（树莓派）
wget https://download.nomachine.com/download/8.12/Arm/nomachine_8.12.1_1_arm64.deb

# 或 x86_64（Intel）
# wget https://download.nomachine.com/download/8.12/Intel/nomachine_8.12.1_1_amd64.deb

sudo dpkg -i nomachine_8.12.1_1_*.deb
sudo /etc/NX/nxserver --start
```

### 步骤 4：Mac 连接机器人
1. 打开 NoMachine
2. Add → Host: `192.168.43.100` → Save
3. 双击连接 → 输入用户名密码
4. **成功看到机器人桌面**

### 步骤 5：复制并运行脚本
```bash
# 在 Mac 终端执行（根据测试需求选择脚本）

# 场景 A：接收平板发来的手柄数据（生产环境）
scp /Users/syy/AndroidStudioProjects/RobotController/tools/receive_gamepad.py ubuntu@192.168.43.100:~/robot/

# 场景 B：模拟机器人向平板发送 MAVLink 测试数据（调试环境）
scp /Users/syy/AndroidStudioProjects/RobotController/tools/send_mavlink_test.py ubuntu@192.168.43.100:~/robot/

# 设置执行权限
ssh ubuntu@192.168.43.100 "chmod +x ~/robot/*.py"
```

---

## ✅ 测试场景

### 场景 A：接收平板手柄数据（生产环境）

**拓扑**: 手柄 → 平板App → 机器人

```bash
# 在 NoMachine 的机器人终端执行
python3 ~/robot/receive_gamepad.py 192.168.43.100 8888
```

**验证步骤**:
1. 保持机器人终端窗口打开
2. 平板操作手柄（摇杆、按键、十字键）
3. 看到数据输出 = 成功！

---

### 场景 B：机器人向平板发送 MAVLink 测试数据（调试环境）

**拓扑**: 机器人(模拟) → 平板App

#### 第一步：修改发送脚本目标 IP

```bash
# 在 NoMachine 的机器人终端编辑脚本
nano ~/robot/send_mavlink_test.py
```

修改第 25 行：
```python
TARGET_IP = "192.168.43.224"  # 改为平板的 IP 地址
```

#### 第二步：启动平板 App 监听

确保平板 App 已启动并绑定 UDP 端口 8888（默认监听所有网卡 `0.0.0.0:8888`）

#### 第三步：发送测试数据

```bash
# 在 NoMachine 的机器人终端执行

# 发送 ID 200 - 机器人状态消息
python3 ~/robot/send_mavlink_test.py --msg 200

# 发送 ID 202 - 参数配置消息
python3 ~/robot/send_mavlink_test.py --msg 202

# 发送 ID 203 - 手柄状态消息
python3 ~/robot/send_mavlink_test.py --msg 203

# 发送 ID 204 - 障碍物信息
python3 ~/robot/send_mavlink_test.py --msg 204
```

**预期结果**:
- 平板 App 收到对应的 MAVLink 消息
- 如果开启了测试模式，会弹出对话框显示解析后的数据
- 日志中显示十六进制数据和结构化字段值

---

## 📊 消息类型说明

| 消息ID | 名称 | CRC_EXTRA | 用途 | 负载大小 |
|--------|------|-----------|------|----------|
| 200 | WINDOW_ROBOT_STATUS | 67 | 机器人状态（电压、电流、姿态等） | 25 字节 |
| 202 | WINDOW_ROBOT_PARAM | 23 | 参数配置（清洗时长、低电量阈值等） | 4 字节 |
| 203 | GAMEPAD_STATE | 59 | 手柄状态（摇杆、按键、十字键） | 25 字节 |
| 204 | OBSTACLE_INFO | 119 | 障碍物信息（位置、尺寸） | 11 字节 |

---

## ❌ 常见问题

### 连接问题

**Q: NoMachine 连不上？**  
A: 检查 Mac 和机器人是否在同一 WiFi，ping 测试：`ping 192.168.43.100`

**Q: SSH 连不上？**  
A: 首次可能需要 HDMI 连接一次，启用 SSH：`sudo systemctl enable ssh && sudo systemctl start ssh`

### 通信问题

**Q: 场景 A 收不到手柄数据？**  
A: 确认平板 App 的 `Config.java` 中 `ROBOT_IP` 是机器人 IP（不是电脑 IP）

**Q: 场景 B 平板收不到测试数据？**  
A: 
1. 确认 `send_mavlink_test.py` 中 `TARGET_IP` 是平板 IP
2. 确认平板 App 已启动并监听 8888 端口
3. 确认防火墙未拦截 UDP 8888 端口

**Q: 如何查看平板当前监听的端口？**  
A: 在平板终端执行：`netstat -tuln | grep 8888` 或 `ss -tuln | grep 8888`

**Q: 消息解析失败？**  
A: 检查 CRC_EXTRA 值是否与消息定义一致，参考 [msg_gamepad_state.java](../app/src/main/java/window_robot/msg_gamepad_state.java) 中的 pack() 方法

---

## 🔧 高级调试

### 使用 demo 版本查看详细调试信息

```bash
# 复制详细调试脚本
scp /Users/syy/AndroidStudioProjects/RobotController/tools/demo_receive_gamepad.py ubuntu@192.168.43.100:~/robot/

# 运行（显示 CRC 校验、十六进制数据等）
python3 ~/robot/demo_receive_gamepad.py 192.168.43.100 8888
```

### 抓包分析

```bash
# 在机器人上安装 tcpdump
sudo apt install tcpdump

# 抓取 UDP 8888 端口的数据包
sudo tcpdump -i wlan0 udp port 8888 -X -vv
```

---

**完成！** 🎉
