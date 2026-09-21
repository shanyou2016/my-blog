# 个人博客

基于 Gitee + GitHub Actions + Netlify 构建的个人静态博客，用于展示和分享文档、学习笔记等内容。

> 架构说明：Gitee 为主仓（本地日常推送），GitHub Actions 每 5 分钟自动将 Gitee 内容同步到 GitHub，Netlify 监听 GitHub 自动部署。本地无需访问 GitHub。

## 项目结构

```
my-blog/
├── .github/
│   └── workflows/
│       └── sync-from-gitee.yml  # GitHub Actions：自动同步 Gitee → GitHub
├── index.html          # 主页文件，展示文件目录结构
├── files/              # 文件仓库，存放各种文档和资料
│   ├── AI/             # AI相关文档
│   ├── Android/        # Android相关文档
│   ├── IOS/            # iOS相关文档
│   ├── UniApp/         # UniApp相关文档
│   ├── 小技巧/          # 小技巧文档
│   └── 服务器/          # 服务端技术文档
├── files.json          # 文件目录结构清单（自动生成）
├── generate-file-list.js  # 生成files.json的脚本
├── LICENSE             # MIT 许可证
└── README.md           # 项目说明文档
```

## 功能特性

- 📁 自动展示 files 目录的完整结构
- 🔍 支持按文件夹层级嵌套展示
- 📄 支持 PDF、DOCX 等文件的预览和下载
- 📱 响应式设计，适配不同设备
- 🎨 美观的界面设计，支持目录展开/折叠

## 容量限制

### Gitee 限制（主仓）

- **仓库容量**：推荐不超过 1GB（免费版上限 5GB）
- **单个文件**：最大 100MB（超过需使用 Git LFS）
- **文件类型**：支持所有静态文件类型

### GitHub 限制（同步镜像）

- 与 Gitee 基本一致，仅作为 Netlify 部署源

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
# 克隆仓库（Gitee 主仓）
git clone git@gitee.com:shanzihao/my-blog.git

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
   git push gitee main
   ```
4. **等待自动部署**：GitHub Actions 每 5 分钟自动同步到 GitHub，Netlify 检测更新后自动部署

### 3. 部署流程

1. **Gitee**：本地将代码推送到 Gitee 主仓（`git push gitee main`）
2. **GitHub Actions**：每 5 分钟自动将 Gitee 内容同步到 GitHub 仓库
3. **Netlify**：自动检测 GitHub 更新并部署，通过 Netlify 域名访问博客

## 常见问题

### 文件不显示
- 检查 files.json 是否已生成
- 检查 Gitee 是否推送了所有文件
- 检查 GitHub Actions 同步是否成功（仓库 Actions 页查看运行记录）
- 检查 Netlify 是否已完成部署

### 大文件处理
- 单个文件超过 100MB 需使用 Git LFS
- 大型媒体文件建议使用外部存储服务

### 部署失败
- 检查构建日志中的错误信息
- 确保文件结构正确

## 技术栈

- **前端**：HTML、CSS、JavaScript
- **版本控制**：Git + Gitee（主仓）+ GitHub（镜像）
- **自动同步**：GitHub Actions
- **部署**：Netlify

## 许可证

MIT License

