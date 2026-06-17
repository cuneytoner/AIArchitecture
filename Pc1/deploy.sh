#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PC1_USER=$(whoami)
PC2_USER="cuneyt" # Kendi PC-2 Linux kullanıcı adınızla DEĞİŞTİRİN!
PC2_IP="192.168.50.2"

echo -e "${YELLOW}======================================================${NC}"
echo -e "${YELLOW}    DAĞITIK AI MİMARİSİ DAĞITIM VE KURULUM SCRIPTİ    ${NC}"
echo -e "${YELLOW}======================================================${NC}"

# --- ADIM 1: PC-1 YEREL SERVİSLERİ AYAĞA KALDIRMA ---
echo -e "\n${GREEN}[1/4] PC-1 (Yerel) Servisleri Başlatılıyor...${NC}"
cd ./Pc1 || exit 1
docker compose down
docker compose up -d
cd ..

# --- ADIM 2: PC-2 AĞ VE SSH KONTROLÜ ---
echo -e "\n${GREEN}[2/4] PC-2 Bağlantısı Test Ediliyor...${NC}"
ping -c 1 $PC2_IP > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ HATA: PC-2 ($PC2_IP) cihazına ulaşılamıyor!${NC}"
    exit 1
fi

# --- ADIM 3: PC-2'YE DOSYA TRANSFERİ ---
echo -e "${GREEN}[3/4] Klasör Yapısı ve Dosyalar PC-2'ye Gönderiliyor...${NC}"
# Uzak makinede hedef runtime klasörünün varlığından emin olalım
ssh ${PC2_USER}@${PC2_IP} "mkdir -p ~/AI/Pc2"

# Yerel projedeki `./Pc2/` klasörünün içindekileri uzak tarafa gönderir
# NOT: ./Pc2/ sonundaki eğik çizgi içeriği tam aktarmak için kritiktir!
rsync -avz --delete \
    --exclude='qdrant_data' \
    --exclude='postgres_data' \
    ./Pc2/ ${PC2_USER}@${PC2_IP}:~/AI/Pc2/

# --- ADIM 4: PC-2 UZAKTAN DOCKER COMPOSE TETİKLEME ---
echo -e "\n${GREEN}[4/4] PC-2 Üzerindeki Docker Servisleri Uzaktan Başlatılıyor...${NC}"
# Uzaktaki klasöre tam erişim sağlayıp, standart docker-compose.yml dosyasını kaldırıp ayağa kaldırıyoruz
ssh ${PC2_USER}@${PC2_IP} "cd ~/AI/Pc2 && docker compose down 2>/dev/null && docker compose up -d"

echo -e "\n${GREEN}======================================================${NC}"
echo -e "${GREEN}   ✓ TÜM DAĞITIK SİSTEM BAŞARIYLA AKTİF EDİLDİ!   ${NC}"
echo -e "======================================================${NC}"
