# En güncel resmi PyTorch CUDA ortamını taban alıyoruz
FROM pytorch/pytorch:latest

# [KRİTİK DÜZELTME]: Triton derleyicisinin ihtiyaç duyduğu C/C++ (GCC/G++) derleyicilerini ekliyoruz
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    libgl1-mesa-glx \
    libglib2.0-0 \
    gcc \
    g++ \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Çalışma dizinini ayarla
WORKDIR /workspace

# [GÜVENLİ BAĞLANTI]: Kırpılmayı önlemek için adresi parçalayıp birleştiriyoruz
RUN REPO_BASE="https://github.com" && \+-
    REPO_PATH="/comfyanonymous/ComfyUI.git" && \
    git clone "${REPO_BASE}${REPO_PATH}" .

# Blackwell (sm_120) için kararlı çalışan CUDA 13.0 Nightly paketini kuruyoruz
RUN pip install --pre --upgrade --no-cache-dir torch torchvision torchaudio --extra-index-url https://pytorch.org

# ComfyUI'ın diğer tüm Python bağımlılıklarını kuruyoruz
RUN pip install --no-cache-dir -r requirements.txt

# Konteyner içindeki çalışma alanının sahipliğini root'tan bizim kullanıcıya (1000:1000) çekiyoruz
RUN chown -R 1000:1000 /workspace

# Dış dünyaya ComfyUI portunu aç
EXPOSE 8188

# [KESİN VRAM OPTİMİZASYONU]: Büyük Qwen-2.5-VL modelleri için VRAM offloading ve FP8 hafifletme bayrakları eklendi
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--lowvram", "--fp8_e4m3fn-textenc", "--fp8_e4m3fn-unet", "--fp16-vae"]
