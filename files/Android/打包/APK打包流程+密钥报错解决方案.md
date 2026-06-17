# APK打包流程\+密钥报错解决方案

---

## 一、文档用途

专门记录：Android Studio 正式签名打包全套流程、复用密钥快速打包流程、固定报错 \(BadPaddingException\) 根因 \+ 解决方法。

- **适用版本**：Android Studio Ladybug 2024\.2\.2

- **适用项目**：LoRa 机器人手柄控制 APP（全安卓手机 / 平板通用）

---

## 二、第一次打包（新建密钥，一生只做一次）

### 1\. 打包入口

`Build` → `Generate Signed Bundle/APK` → 选择 `APK` → `Next`

### 2\. 新建密钥 Create new

**固定配置（永久不变）：**

- 保存位置：桌面 `robot_key.jks`

- 密钥库密码：`123456`

- 密钥密码：`123456`

- 别名：`robot_key`

- 有效期：25 年

- 证书信息随意填写：Robot / Tech / MyCompany / Changsha / Hunan / CN

### 3\. 打包配置

- 打包类型：`release` 正式版

- 签名版本：勾选 `V2`、`V3`

- 点击 `Create/Finish` 等待打包

- 成功后 `locate` 打开目录，获取：`app-release.apk`

---

## 三、第二次及以后【快速打包流程】（重点！不用新建密钥）

> **核心规则：密钥一生只新建一次，后续全部复用！**
> 后续修改代码、更新版本、重新打包，全程不用新建密钥！
> 
> 

### 快速打包步骤

1. `Build` → `Generate Signed Bundle/APK` → 选 `APK` → `Next`

2. 不再点 `Create new`，直接选择桌面已有：`robot_key.jks`

3. Key store password 输入：`123456`

4. Key password 输入：`123456`

5. `Next` → 勾选 `release`、`V2/V3`

6. 直接打包完成，获取新版 APK

---

## 四、固定报错：BadPaddingException 终极解决方案

### 1\. 报错完整日志

```Plain Text
Cause: failed to decrypt safe contents entry: javax.crypto.BadPaddingException: Given final block not properly padded.
```

### 2\. 唯一根因（100% 确定）

**不是代码问题、不是项目问题！**

只有两种可能：

- ① 本次输入的 **密钥密码和创建时密码不一致**

- ② 选错了 jks 文件（用了别的密钥文件）

> 通俗解释：钥匙和锁不匹配，解密失败。
> 
> 

### 3\. 三种解决方法（从快到稳）

**方法一：核对密码（优先）**
两个密码必须全部是：`123456`，多一位、少一位、大小写错了都会报错。

**方法二：核对密钥文件路径**
必须选中你自己创建的：`robot_key.jks`（桌面），不能选其他密钥文件。

**方法三：终极解决（推荐，零风险）**
直接删除旧的 `robot_key.jks`，重新新建一次密钥

> **适用场景**：忘记密码、密码错乱、密钥损坏
> 当前项目未发布上线，重建密钥完全无任何影响！
> 
> 

---

## 五、密钥终身使用规则（重中之重）

> **密钥一生只需要新建 1 次**
> 
> 

- ✅ 后续所有更新打包 **全部复用旧密钥**

- ❌ 不要频繁新建密钥

- ❌ 不要修改密钥密码

- ✅ **必须备份 jks 文件**（网盘 \+ U 盘双备份）

---

## 六、个人固定密钥信息（专属存档，永不更改）

|项目|配置|
|---|---|
|密钥文件名称|`robot_key.jks`|
|存放路径|电脑桌面|
|统一密码|`123456`（双密码一致）|
|签名版本|`V2 + V3`|
|打包类型|`Release` 正式版|

---

---

# 🔍 APK 文件定位方法：在 Android Studio 中直接定位

别担心，这是非常常见的情况！打包完成后，APK 文件通常默认生成在项目的特定目录下。你可以通过以下两种主要方法来找到它。

---

## 方法一：在 Android Studio 中直接定位

这是最快的方法。打包成功后，Android Studio 通常会在右下角弹出一个通知，直接告诉你 APK 的路径。

1. 查看 Android Studio 右下角的通知区域，看是否有类似 "APK \(s\) generated successfully" 的通知

2. 点击通知中的 **"locate"** 链接，系统会自动打开文件夹并选中生成的 APK 文件

### 如果错过了通知，你也可以通过菜单手动查找：

- 点击顶部菜单栏的 `Build`

- 选择 `Build Bundle(s) / APK(s)`

- 点击 `Deliver APK(s)` 或 `Build APK(s)`，这通常会再次触发构建并弹出包含路径的通知

---

## 方法二：手动在项目文件夹中查找

如果方法一不可用，你可以手动在项目目录中查找。APK 文件默认存放在 `app` 模块下的 `build/outputs/apk/` 路径中。

### 具体路径取决于你打包的版本：

#### Debug 版本（用于调试）

- **路径**：`你的项目路径/app/build/outputs/apk/debug/`

- **文件名**：`app-debug.apk`

#### Release 版本（用于发布）

- **路径**：`你的项目路径/app/build/outputs/apk/release/`

- **文件名**：`app-release-unsigned.apk`（未签名）或 `app-release.apk`（已签名）

> 你可以在 Android Studio 左侧的 Project 视图中，切换到 **Project 模式**（而不是 Android 模式），然后逐级展开 `app` \-\> `build` \-\> `outputs` \-\> `apk` 目录来找到它。
> 
> 

---

## 如果找不到文件怎么办？

1. **检查构建变体 \(Build Variant\)**：确认你打包的是 debug 还是 release 版本，然后去对应的文件夹查找

2. **检查 Gradle 配置**：有些项目可能在 `build.gradle` 文件中自定义了输出路径或文件名

3. **使用命令行搜索**：如果你的项目路径比较复杂，可以在项目根目录下打开终端，运行 `find . -name "*.apk"` 命令来搜索所有 APK 文件

> （注：文档部分内容可能由 AI 生成）
