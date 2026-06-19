#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}========== DAĞITIK AI CLUSTER HOST SERVİS KURULUMU BAŞLADI ==========${NC}"

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ HATA: Bu scripti 'sudo' ile çalıştırmalısınız! (sudo ./install_services.sh)${NC}"
  exit 1
fi

# 1. Standart sistem servislerini kopyalama
echo -e "${YELLOW}[1/3] Sistem servisleri /etc/systemd/system/ altına yerleştiriliyor...${NC}"
cp ./ai-celery-worker.service /etc/systemd/system/
cp ./ai-memory-agent.service /etc/systemd/system/

# 2. Ollama Yerel Ağ Ayarlarını (Override) Enjekte Etme
echo -e "${YELLOW}[2/3] Ollama yerel ağ (LAN) dinleme konfigürasyonu kuruluyor...${NC}"
mkdir -p /etc/systemd/system/ollama.service.d
cp ./ollama.service.d/override.conf /etc/systemd/system/ollama.service.d/

# 3. Systemd Katmanını Yenileme ve Servisleri Aktif Etme
echo -e "${YELLOW}[3/3] Linux Systemd servisleri çekirdekten tetikleniyor...${NC}"
systemctl daemon-reload

systemctl enable ollama 2>/dev/null
systemctl restart ollama 2>/dev/null

systemctl enable ai-celery-worker.service
systemctl restart ai-celery-worker.service

systemctl enable ai-memory-agent.service
systemctl restart ai-memory-agent.service

echo -e "${GREEN}========== TÜM SERVİSLER VE OLLAMA NETWORK BAĞLARI BAŞARIYLA KODA İŞLENDİ! ==========${NC}"
