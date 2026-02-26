#!/bin/bash

echo "=== 修复SSH密钥位置 ==="

# 方法1：移动现有密钥
if [ -f "id_ed25519_gitee" ]; then
    echo "移动密钥文件到.ssh目录..."
    mv id_ed25519_gitee* ~/.ssh/
    chmod 600 ~/.ssh/id_ed25519_gitee
    chmod 644 ~/.ssh/id_ed25519_gitee.pub
else
    # 方法2：重新生成密钥
    echo "重新生成SSH密钥..."
    ssh-keygen -t ed25519 -C "16673384113@163.com" -f ~/.ssh/id_ed25519_gitee -N ""
fi

# 配置SSH
echo "配置SSH..."
cat > ~/.ssh/config << EOF
Host gitee.com
  HostName gitee.com
  User git
  IdentityFile ~/.ssh/id_ed25519_gitee
EOF
chmod 600 ~/.ssh/config

# 显示公钥
echo ""
echo "=== 新生成的SSH公钥 ==="
cat ~/.ssh/id_ed25519_gitee.pub

echo ""
echo "=== 请复制上面的公钥内容到Gitee ==="
echo "=== 然后运行 ssh -T git@gitee.com 测试连接 ==="