const fs = require('fs');
const path = require('path');

function scanDir(dir, baseDir = dir) {
  const results = [];
  const list = fs.readdirSync(dir);

  list.forEach(file => {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);

    if (stat.isDirectory()) {
      // 递归扫描子目录
      results.push({
        name: file,
        type: 'folder',
        path: path.relative(baseDir, fullPath),
        children: scanDir(fullPath, baseDir)
      });
    } else {
      // 记录所有文件类型
      const ext = path.extname(file).toLowerCase();
      results.push({
        name: file,
        type: 'file',
        ext: ext,
        path: path.relative(baseDir, fullPath)
      });
    }
  });

  return results;
}

// 扫描 files 目录
const filesDir = path.join(__dirname, 'files');
const fileList = scanDir(filesDir);

// 写入到 files.json
fs.writeFileSync(
  path.join(__dirname, 'files.json'),
  JSON.stringify(fileList, null, 2)
);

console.log('✅ files.json 已生成');
