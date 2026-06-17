#!/bin/bash

# Read configuration from cluster_config.env
source ./cluster_config.env

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required commands
if ! command_exists rsync; then
    echo "rsync is not installed. Please install it first."
    exit 1
fi

if ! command_exists sshpass; then
    echo "sshpass is not installed. Please install it first."
    exit 1
fi

if ! command_exists docker compose; then
    echo "docker compose is not installed. Please install it first."
    exit 1
fi

# Deploy: Sync project code to PC-2 and run docker compose up -d
deploy() {
    echo "Deploying project to PC-2..."
    
    # 1. Uzak makinede (PC-2) hedef runtime klasörünün varlığından emin olalım
    sshpass -p 'your_password_here' ssh cuneyt@$NODE_MEMORY_RAM_IP "mkdir -p $PROJECT_ROOT_PATH/Pc2"

    # 2. Sadece Pc2 klasörünün içeriğini karşıya gönderiyoruz (Büyük ZIP'ler ve .git filtrelendi)
    # NOT: Yereldeki ./Pc2/ sonundaki eğik çizgi (/) içeriği tam aktarmak için kritiktir!
    rsync -avz --delete \
        --exclude '.git/' \
        --exclude 'node_modules/' \
        --exclude 'env/' \
        --exclude '*.env' \
        --exclude '*.log' \
        --exclude '*.zip' \
        --exclude '*.tar.gz' \
        ./Pc2/ cuneyt@$NODE_MEMORY_RAM_IP:$PROJECT_ROOT_PATH/Pc2/

    echo "Activating Docker containers on PC-2..."
    # 3. Uzak makinede doğrudan hedef klasöre girip modern docker compose komutunu tetikliyoruz
    sshpass -p 'your_password_here' ssh cuneyt@$NODE_MEMORY_RAM_IP "cd $PROJECT_ROOT_PATH/Pc2/ && docker compose down 2>/dev/null && docker compose up -d"
}

# Up: Start local services on PC-1 and PC-2, and Systemd services on PC-1
up() {
    echo "Starting services on PC-1..."
    sudo systemctl start ai-memory-agent.service
    sudo systemctl start ai-celery-worker.service

    echo "Starting services on PC-2..."
    sshpass -p 'your_password_here' ssh cuneyt@$NODE_MEMORY_RAM_IP "docker compose up -d"
}

# Down: Stop services on PC-1 and PC-2, and Systemd services on PC-1
down() {
    echo "Stopping services on PC-1..."
    sudo systemctl stop ai-memory-agent.service
    sudo systemctl stop ai-celery-worker.service

    echo "Stopping services on PC-2..."
    sshpass -p 'your_password_here' ssh cuneyt@$NODE_MEMORY_RAM_IP "docker compose down"
}

# Status: Show status of Docker containers and Systemd services on PC-1 and PC-2
status() {
    echo "Status of PC-1:"
    systemctl list-units --type=service | grep -E 'ai-memory-agent.service|ai-celery-worker.service'

    echo "Status of PC-2:"
    sshpass -p 'your_password_here' ssh cuneyt@$NODE_MEMORY_RAM_IP "docker compose ps"
}

# Main command handling
case "$1" in
    deploy)
        deploy
        ;;
    up)
        up
        ;;
    down)
        down
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: ./clusterctl.sh {deploy|up|down|status}"
        exit 1
        ;;
esac