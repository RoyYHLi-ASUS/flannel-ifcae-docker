FROM alpine:latest

# 更新並安裝必要套件
RUN apk update && \
    apk add --no-cache \
    ansible \
    python3 \
    py3-pip \
    curl \
    bash \
    util-linux \
    ca-certificates

# 創建工作目錄
WORKDIR /ansible

# 複製 flannel playbook
COPY playbooks/flannel_playbook.yml /ansible/flannel_playbook.yml

# 設置 Ansible 配置
RUN mkdir -p /etc/ansible && \
    echo "[defaults]" > /etc/ansible/ansible.cfg && \
    echo "host_key_checking = False" >> /etc/ansible/ansible.cfg && \
    echo "interpreter_python = auto_silent" >> /etc/ansible/ansible.cfg

# 入口腳本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]