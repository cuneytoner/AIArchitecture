# En güncel resmi PyTorch CUDA ortamını taban alıyoruz
FROM pytorch/pytorch:latest

# Gerekli Linux sistem bağımlılıklarını kur
RUN apt-get update && apt-get install -y git wget curl libgl1-mesa-glx libglib2.0-0 && rm -rf /var/lib/apt/lists/*

# Çalışma dizinini ayarla
WORKDIR /workspace

# [GÜVENLİ BAĞLANTI]: Kırpılmayı önlemek için adresi parçalayıp birleştiriyoruz
RUN REPO_BASE="https://github.com" && \
    REPO_PATH="/comfyanonymous/ComfyUI.git" && \
    git clone "${REPO_BASE}${REPO_PATH}" .

# [KRİTİK ADIM]: İçerideki PyTorch'u zorla Blackwell (sm_120) destekleyen CUDA Nightly sürümüne yükseltiyoruz
RUN pip install --pre --upgrade --no-cache-dir torch torchvision torchaudio --extra-index-url https://pytorch.org

# ComfyUI'ın diğer tüm Python bağımlılıklarını kuruyoruz
RUN pip install --no-cache-dir -r requirements.txt

# Dış dünyaya ComfyUI portunu aç
EXPOSE 8188

# Konteyner başladığında doğrudan ComfyUI sunucusunu tetikle
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
