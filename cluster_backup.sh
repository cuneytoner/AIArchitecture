#!/bin/bash

# Renklendirme
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BACKUP_DIR="./cluster_backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="ai_cluster_backup_$TIMESTAMP.tar.gz"

# Cluster konfigürasyonunu yükle
if [ -f "./cluster_config.env" ]; then
    source ./cluster_config.env
else
    echo -e "${RED}❌ HATA: cluster_config.env bulunamadı!${NC}"
    exit 1
fi

usage() {
    echo -e "${YELLOW}Kullanım:${NC}"
    echo "  $0 backup   : Tüm cluster bileşenlerini (Kod, Kurallar, Hafıza Veritabanları) yedekler."
    echo "  $0 restore  : En son alınan yedeği sisteme geri yükler ve cluster'ı ayağa kaldırır."
    exit 1
}

do_backup() {
    echo -e "${GREEN}========== CLUSTER YEDEKLEME BAŞLADI ==========${NC}"
    mkdir -p $BACKUP_DIR

    # 1. PostgreSQL (Kalıcı Kurallar) Yedekleme (PC-2 üzerinden çekilir)
    echo -e "${YELLOW}[1/4] PC-2 PostgreSQL veritabanı yedeği alınıyor...${NC}"
    ssh cuneyt@$NODE_MEMORY_RAM_IP "docker exec ai_db_postgres pg_dump -U $POSTGRES_USER $POSTGRES_DB" > "$BACKUP_DIR/postgres_dump_$TIMESTAMP.sql" 2>/dev/null
    
    # 2. Qdrant (Semantik Vektör Hafızası) Yedekleme (PC-2 üzerinden çekilir)
    echo -e "${YELLOW}[2/4] PC-2 Qdrant semantik hafıza snapshot'ı alınıyor...${NC}"
    ssh cuneyt@$NODE_MEMORY_RAM_IP "curl -X POST http://localhost:6333/collections/$QDRANT_COLLECTION/snapshots" > /dev/null 2>&1
    # Uzaktaki en güncel snapshot dosyasını yerel yedek klasörüne çekelim
    rsync -avz cuneyt@$NODE_MEMORY_RAM_IP:~/AI/Pc2/qdrant_data/snapshots/ "$BACKUP_DIR/qdrant_snapshots_$TIMESTAMP/" > /dev/null 2>&1

    # 3. Proje Kodları, .clinerules ve Konfigürasyonları Paketleme
    echo -e "${YELLOW}[3/4] Proje kodları, .clinerules ve ayarlar paketleniyor...${NC}"
    tar -czf "$BACKUP_DIR/$BACKUP_NAME" \
        --exclude='./Pc1/comfyui_data' \
        --exclude='./Pc1/shared_3d_data' \
        --exclude='./Pc2/qdrant_data' \
        --exclude='./Pc2/postgres_data' \
        --exclude='./cluster_backups' \
        --exclude='./env' \
        .

    # 4. Her şeyi tek bir büyük ana göç paketinde birleştirme
    cd $BACKUP_DIR
    tar -czf "../$BACKUP_NAME" .
    cd ..
    rm -rf $BACKUP_DIR
    
    echo -e "${GREEN}============== YEDEKLEME TAMAMLANDI ==============${NC}"
    echo -e "${GREEN}✓ Göç ve Taşıma Paketiniz Hazır:${NC} ./$BACKUP_NAME"
    echo -e "${YELLOW}Bu dosyayı yeni sunucuya taşıyıp '$0 restore' çalıştırmanız yeterlidir.${NC}"
}

do_restore() {
    echo -e "${YELLOW}========== CLUSTER GERİ YÜKLEME / TAŞIMA BAŞLADI ==========${NC}"
    
    # En güncel yedek dosyasını bul
    LATEST_BACKUP=$(ls -t ai_cluster_backup_*.tar.gz 2>/dev/null | head -n 1)
    
    if [ -z "$LATEST_BACKUP" ]; then
        echo -e "${RED}❌ HATA: Mevcut dizinde herhangi bir ai_cluster_backup_*.tar.gz dosyası bulunamadı!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}En güncel yedek açılıyor:${NC} $LATEST_BACKUP"
    mkdir -p ./tmp_restore && tar -xzf "$LATEST_BACKUP" -C ./tmp_restore
    
    # Kodları ve .clinerules şablonlarını geri yükle
    MAIN_TAR=$(ls ./tmp_restore/ai_cluster_backup_*.tar.gz)
    tar -xzf "$MAIN_TAR" -C ./
    
    echo -e "${GREEN}✓ Proje kodları, .clinerules ve çevre dosyaları yeni ortama başarıyla açıldı.${NC}"
    echo -e "${YELLOW}Şimdi './Pc1/deploy.sh' komutunu çalıştırarak yeni donanım ağınızı tetikleyebilirsiniz.${NC}"
    
    rm -rf ./tmp_restore
    echo -e "${GREEN}========== GERİ YÜKLEME BAŞARIYLA TAMAMLANDI ==========${NC}"
}

# Komut kontrolü
case "$1" in
    backup)  do_backup ;;
    restore) do_restore ;;
    *)       usage ;;
esac
