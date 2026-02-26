# 个人博客

基于 GitHub + Netlify 构建的个人静态博客，用于展示和分享文档、学习笔记等内容。

## 项目结构

```
my-blog/
├── index.html          # 主页文件，展示文件目录结构
├── files/              # 文件仓库，存放各种文档和资料
│   ├── AI/             # AI相关文档
│   ├── Android/        # Android相关文档
│   ├── IOS/            # iOS相关文档
│   └── UniApp/         # UniApp相关文档
├── files.json          # 文件目录结构清单（自动生成）
├── generate-file-list.js  # 生成files.json的脚本
└── README.md           # 项目说明文档
```

## 功能特性

- 📁 自动展示 files 目录的完整结构
- 🔍 支持按文件夹层级嵌套展示
- 📄 支持 PDF、DOCX 等文件的预览和下载
- 📱 响应式设计，适配不同设备
- 🎨 美观的界面设计，支持目录展开/折叠

## 容量限制

### GitHub 限制

- **仓库容量**：推荐不超过 1GB
- **单个文件**：最大 100MB（超过需使用 Git LFS）
- **文件类型**：支持所有静态文件类型

### Netlify 限制

- **带宽**：免费计划每月 100GB
- **构建**：有构建时间限制，但足够个人博客使用

## 支持的文件类型

- **文档**：PDF、DOCX、XLSX 等
- **图片**：JPG、PNG、GIF 等
- **视频**：MP4、MOV 等
- **音频**：MP3、WAV 等
- **代码**：HTML、CSS、JavaScript 等
- **压缩包**：ZIP、RAR 等

## 使用方法

### 1. 本地开发

```bash
# 克隆仓库
git clone git@github.com:shanyou2016/my-blog.git

# 进入目录
cd my-blog

# 启动本地服务器
python3 -m http.server 8080

# 在浏览器中访问
# http://localhost:8080
```

### 2. 添加新文件

1. **将文件复制到 files 文件夹中**
2. **重新生成 files.json**：
   ```bash
   node generate-file-list.js
   ```
3. **提交更改**：
   ```bash
   git add .
   git commit -m "添加新文件"
   git push origin master
   ```
4. **等待 Netlify 自动部署**

### 3. 部署流程

1. **GitHub**：将代码推送到 GitHub 仓库
2. **Netlify**：自动检测更新并部署
3. **访问**：通过 Netlify 生成的域名访问博客

## 常见问题

### 文件不显示
- 检查 files.json 是否已生成
- 检查 GitHub 是否推送了所有文件
- 检查 Netlify 是否已完成部署

### 大文件处理
- 单个文件超过 100MB 需使用 Git LFS
- 大型媒体文件建议使用外部存储服务

### 部署失败
- 检查构建日志中的错误信息
- 确保文件结构正确

## 技术栈

- **前端**：HTML、CSS、JavaScript
- **版本控制**：Git、GitHub
- **部署**：Netlify

## 许可证

MIT License

