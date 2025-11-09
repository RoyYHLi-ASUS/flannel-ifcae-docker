#!/bin/bash
set -e

echo "=== Flannel Ansible 部署程序 (在 HOST 上執行) ==="
echo ""

# 檢查 playbook 是否存在
if [ ! -f "/ansible/flannel_playbook.yml" ]; then
    echo "❌ 錯誤: 找不到 /ansible/flannel_playbook.yml"
    echo "容器內檔案列表:"
    ls -la /ansible/
    exit 1
fi

echo "✅ 找到 playbook: /ansible/flannel_playbook.yml"
echo ""

# 複製 playbook 到 host 的 /tmp
echo "複製 playbook 到 host /tmp..."
cp /ansible/flannel_playbook.yml /host/tmp/flannel_playbook.yml
cp /ansible-vars-config/vars.yml /host/tmp/vars.yml

if [ ! -f "/host/tmp/flannel_playbook.yml" ]; then
    echo "❌ 錯誤: 複製失敗"
    exit 1
fi

echo "✅ Playbook 已複製到 host:/tmp/flannel_playbook.yml"
echo ""

# 使用 nsenter 進入 host 命名空間並執行 playbook
echo "進入 host 命名空間並執行 Ansible..."
echo ""

nsenter --target 1 --mount --uts --ipc --net --pid -- bash -c "
    set -e
    
    # 檢查 Ansible 是否安裝
    if ! command -v ansible-playbook &> /dev/null; then
        echo '❌ 錯誤: host 上未安裝 Ansible'
        echo ''
        echo '請先在 host 上安裝 Ansible:'
        echo '  Ubuntu/Debian: sudo apt-get install -y ansible'
        echo '  CentOS/RHEL:   sudo yum install -y ansible'
        echo '  Rocky/Alma:    sudo dnf install -y ansible'
        exit 1
    fi
    
    echo '✅ Ansible 已安裝'
    ansible --version | head -n 1
    echo ''
    
    # 檢查 kubectl 是否安裝
    if ! command -v kubectl &> /dev/null; then
        echo '❌ 錯誤: host 上未安裝 kubectl'
        echo '請確保 K3s 已安裝並且 kubectl 可用'
        exit 1
    fi
    
    echo '✅ kubectl 已安裝'
    kubectl version --client --short 2>/dev/null || kubectl version --client
    echo ''
    
    # 檢查 K3s 是否運行
    if ! systemctl is-active --quiet k3s; then
        echo '⚠️  警告: K3s 服務未運行'
        echo '嘗試啟動 K3s...'
        systemctl start k3s
        sleep 10
    fi
    
    echo '✅ K3s 服務運行中'
    echo ''
    
    # 檢查 playbook 是否存在
    if [ ! -f /tmp/flannel_playbook.yml ]; then
        echo '❌ 錯誤: /tmp/flannel_playbook.yml 不存在'
        exit 1
    fi
    
    echo '開始執行 Flannel 部署 playbook...'
    echo '---'
    
    # 在 host 上執行 playbook
    cd /tmp
    ansible-playbook flannel_playbook.yml \
        --connection=local \
        --inventory localhost, \
        --extra-vars \"@/tmp/vars.yml\" \
        -v
"

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ === Flannel 部署完成 ==="
    echo ""
    echo "驗證命令:"
    echo "  kubectl get pods -n kube-flannel"
    echo "  kubectl get nodes -o wide"
    echo "  cat /run/flannel/subnet.env"
    echo "  ip link show flannel.1"
else
    echo "❌ 部署失敗，退出碼: $EXIT_CODE"
    exit $EXIT_CODE
fi
