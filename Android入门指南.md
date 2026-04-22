# Android Studio开发环境入门指南

## 1. 创建第一个Android项目

### 步骤：
1. 打开Android Studio
2. 选择 "Start a new Android Studio project"
3. 选择 "Empty Activity" 模板
4. 配置项目信息：
   - Name: MyFirstApp
   - Package name: com.example.myfirstapp
   - Save location: 选择合适的目录
   - Language: Kotlin
   - Minimum SDK: API 21 (Android 5.0)
5. 点击 "Finish"

## 2. 项目结构介绍

### 主要目录：
- **app/src/main/java**: Kotlin源代码
- **app/src/main/res**: 资源文件（布局、字符串、图片等）
- **app/src/main/AndroidManifest.xml**: 应用配置文件

### 核心文件：
- **MainActivity.kt**: 主Activity，应用的入口
- **activity_main.xml**: 主界面布局文件

## 3. 运行第一个应用

1. 点击工具栏中的 "Run" 按钮（绿色三角形）
2. 选择一个模拟器或连接真实设备
3. 等待应用编译和安装
4. 查看运行结果

## 4. 基础概念

### Activity：
- Android应用的基本组件
- 代表一个用户界面
- 有生命周期：onCreate -> onStart -> onResume -> onPause -> onStop -> onDestroy

### 布局文件：
- 使用XML定义界面结构
- 常用布局：LinearLayout、RelativeLayout、ConstraintLayout

### 视图组件：
- TextView：显示文本
- Button：按钮
- EditText：输入框
- ImageView：显示图片

## 5. 简单示例：修改界面

### 修改布局文件 (activity_main.xml):
```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:gravity="center"
    tools:context=".MainActivity">

    <TextView
        android:id="@+id/hello_text"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Hello Android!"
        android:textSize="24sp" />

    <Button
        android:id="@+id/click_button"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="点击我"
        android:layout_marginTop="20dp" />

</LinearLayout>
```

### 修改MainActivity.kt:
```kotlin
package com.example.myfirstapp

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.widget.Button
import android.widget.TextView

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val helloText = findViewById<TextView>(R.id.hello_text)
        val clickButton = findViewById<Button>(R.id.click_button)

        clickButton.setOnClickListener {
            helloText.text = "按钮被点击了！"
        }
    }
}
```

## 6. 下一步学习内容

1. 学习Android布局系统
2. 了解Activity生命周期
3. 学习Intent和页面跳转
4. 学习数据存储（SharedPreferences、SQLite）
5. 学习网络请求

## 7. 常用快捷键

- Ctrl+Space: 代码补全
- Ctrl+D: 复制当前行
- Ctrl+Y: 删除当前行
- Ctrl+F: 查找
- Ctrl+R: 替换
- Shift+F10: 运行应用
- Shift+F9: 调试应用

## 8. 学习资源推荐

- Android官方文档：https://developer.android.com/docs
- Kotlin官方文档：https://kotlinlang.org/docs/home.html
- Stack Overflow：https://stackoverflow.com/questions/tagged/android
- GitHub上的开源项目

开始你的Android开发之旅吧！