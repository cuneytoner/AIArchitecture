🌐 Dağıtık AI Cluster Mimari Dokümantasyonu (v1.0.0)

Bu proje; İnternetsiz/Çevrimdışı Kodlama (Offline AI Coding), Genel Sohbet/Doküman Analizi (Chat Modülü), Asenkron Görsel Üretimi (ComfyUI Pipeline) ve 3D Karakter Kemiklendirme (Headless Blender Rig Otomasyonu) katmanlarını tek bir ortak semantik hafıza havuzunda birleştiren, yatayda genişletilebilir kurumsal bir yapay zeka laboratuvarıdır.

1. Donanım ve İşletim Sistemi Gereksinimleri (Cluster Nodes)
Sistem, iki farklı fiziksel bilgisayarın (Node) yerel ağ (LAN) üzerinden sabit IP'ler ile kenetlenmesi esasıyla çalışır:

🧩 Node 1: PC-1 (Runtime & Grafik Üretim Üssü)
- İşletim Sistemi: Pop!_OS 22.04 LTS (Ubuntu Tabanlı, NVIDIA Sürücüleri Yerleşik)
- İşlemci / RAM: Minimum 6-8 Çekirdek CPU / 16 GB veya 32 GB RAM
- Ekran Kartı (GPU): NVIDIA RTX 5060 Ti (Blackwell Mimarisi, 16GB VRAM, Compute Capability: sm_120)
- Ağ Rolü (IP): 192.168.50.1 (Sabit LAN IP)
- Görevi: Ağır grafik hesaplamaları (ComfyUI), 3D iskelet otomasyonu (Blender), yerel kodlama zekası (Ollama Qwen-14B), asenkron iş kuyruğu işçisi (Celery).

🧩 Node 2: PC-2 (Orchestrator & Ortak Bellek Üssü)
- İşletim Sistemi: Linux (Pop!_OS / Ubuntu / Debian Tabanlı)
- İşlemci / RAM: Minimum 4-6 Çekirdek CPU / 32 GB RAM (Büyük LLM modellerini RAM'de tutmak için)
- Ekran Kartı (GPU): NVIDIA GTX 1650 (Giriş seviyesi, sadece ekran çıkışı ve hafif yükler için)
- Ağ Rolü (IP): 192.168.50.2 (Sabit LAN IP)
- Görevi: Büyük planlama modelinin koşturulması (Llama3.3-70B), akıllı API yönlendirme (LiteLLM), semantik vektör veritabanı (Qdrant), kural tabanı (PostgreSQL), ChatGPT arayüzü (Open-WebUI) ve merkezi izleme panelleri (Portainer + Flower).

2. Servislerin Dağılımı ve Ağ Haritası (Network Map)
Sistemdeki tüm servisler izole Docker konteynerleri ve Linux systemd arka plan süreçleri olarak çalışmaktadır:

🖥️ PC-1 (192.168.50.1) Üzerinde Koşan Servisler
- ai_image_comfyui | Docker (Özel Derleme) | Port 8188 | Blackwell (sm_120) uyumlu CUDA Nightly kütüphaneli görsel üretim motoru.
- ai_3d_blender | Docker Container | Port 3001 | linuxserver/blender imajı. Sessiz modda (-b) 3D rig otomasyon betiğini koşturur.
- ai_queue_redis | Docker Container | Port 6379 | Celery iş kuyruğunun mesaj yöneticisi (Broker).
- ai-memory-agent.service | Linux systemd | Port 5000 | FastAPI tabanlı bellek aracısı. Cline ve diğer modüllerin hafıza köprüsüdür.
- ai-celery-worker.service | Linux systemd | Arka Plan | tasks.py dosyasını dinleyen asenkron işçi. Ağır işleri sıraya alır.
- Ollama (Local) | Linux Native | Port 11434 | qwen2.5-coder:14b modelini 5060Ti VRAM'inde saniyede 40+ token ile uçurur.

🧠 PC-2 (192.168.50.2) Üzerinde Koşan Servisler
- ai_router_litellm | Docker Container | Port 8000 | Gelen tüm LLM isteklerini karşılar, modelleri tek bir OpenAI API formatına çevirir.
- ai_chat_interface | Docker Container | Port 3000 | Open-WebUI: ChatGPT benzeri genel sohbet, doküman yükleme ve analiz arayüzü.
- ai_memory_qdrant | Docker Container | Port 6333 | Proje geçmişini ve konuşma özetlerini tutan Semantik Vektör Hafızası.
- ai_db_postgres | Docker Container | Port 5432 | Geliştirme kurallarını ve yapılandırmaları kalıcı tutan SQL kural tabanı.
- ai_memory_portainer | Docker Container | Port 9000 | PC-2'deki tüm konteynerleri tarayıcıdan durdurup başlatma ve log izleme paneli.
- ai_memory_celery_flower | Docker Container | Port 5555 | PC-1'deki Redis'e bağlanarak asenkron imaj ve 3D rig işlerini grafiksel izleyen panel.
- Ollama (Orchestrator) | Linux Native | Port 11434 | llama3.3:70B mimari planlama modelini 32GB RAM üzerinde çalıştırır.

3. Sıfırdan Adım Adım Kurulum Kılavuzu (Bootstrap Guide)
Sistem tamamen çöktüğünde veya yeni bir bilgisayara geçildiğinde sıfırdan ayağa kaldırma prosedürü:

Adım 1: Temel Linux Paketlerinin Kurulması
İki makinede de terminali açın ve şu paketleri kurun:
sudo apt update && sudo apt install -y git curl wget rsync docker.io docker-compose sshpass
sudo usermod -aG docker $USER

Adım 2: PC-1 Üzerinde NVIDIA Container Toolkit Kurulumu
5060Ti kartının Docker içinden okunabilmesi için:
curl -fsSL github.io | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L github.io | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.listsudo apt-get update && sudo apt-get install -y nvidia-container-toolkitsudo nvidia-ctk runtime configure --runtime=dockersudo systemctl restart docker

Adım 3: VS Code ve Cline Eklentisinin Yapılandırılması
Cline ayarlarına girin ve şu parametreleri bağlayın:
Provider: OpenAI Compatible
Base URL: 192.168.50
API Key: local-cluster-key
Model ID: akilli-kod-asistani
Context Window: 16384

Adım 4: Proje Kodlarının Çekilmesi ve Python Ortamı
git clone github.com
cd AIArchitecture
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt

Adım 5: Sistem Servislerinin Linux'a Tanıtılması
sudo chmod +x ./Services/install_services.sh
sudo ./Services/install_services.sh

Adım 6: Global CLI Yönetim Aracı ile Cluster'ı Ayağa Kaldırmak
chmod +x ./clusterctl.sh
./clusterctl.sh deploy

4. Cluster Yedekleme, Göç ve Genişletme Politikası (Migration)
Yedekleme: ./cluster_backup.sh backup (Postgres, Qdrant ve kodları paketler)
Geri Yükleme: ./cluster_backup.sh restore (Sistemi yeni makineye sıfır kayıpla giydirir)
Genişletme: Yeni makine geldiğinde sadece cluster_config.env dosyasındaki IP adreslerini güncelleyin. clusterctl.sh ve deploy mekanizmaları tüm ağ trafiğini yeni donanıma göre otomatik şekillendirecektir.

5. Doküman Güncelleme Kuralı
Cline eklentisi projede her başarılı git commit veya clusterctl.sh deploy işlemi yaptıktan sonra, bu dokümanı açıp en güncel port ve imaj bilgilerini revize etmekle yükümlüdür.
Güncellenen her mimari adım, memory_agent.py üzerinden PC-2 Qdrant veritabanına category: architectural_decision etiketiyle post edilir.
PC-2'deki Open-WebUI (Llama-70B) üzerinden bir döküman analizi sorgusu yaptığınızda, Llama-70B modeli Qdrant veritabanına başvurarak bu dökümandaki güncel port haritasını okur.
