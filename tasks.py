import json
import os
import requests
import subprocess
from celery import Celery

# PC-1 yerel Redis bağlantısı
celery_app = Celery('ai_tasks', broker='redis://localhost:6379/0', backend='redis://localhost:6379/0')

COMFY_URL = "http://localhost:8188/prompt"
WORKFLOW_FILE = "comfy_workflow_api.json"

@celery_app.task(name="tasks.generate_image_comfyui")
def generate_image_comfyui(prompt_text: str):
    """Gerçek ComfyUI API şemasını yükler, promptu dinamik bulup günceller"""
    
    if not os.path.exists(WORKFLOW_FILE):
        return {"status": "error", "message": f"'{WORKFLOW_FILE}' root dizinde bulunamadı!"}
        
    with open(WORKFLOW_FILE, 'r') as f:
        workflow_data = json.load(f)
        
    # --- KRİTİK DÜZELTME: ID NUMARASINA BAKMAKSIZIN PROMPTU BUL ---
    # Sabit "3" veya "6" aramak yerine tüm şemayı tarayıp pozitif prompt alanını buluyoruz
    found_node = False
    for node_id, node_info in workflow_data.items():
        # CLIPTextEncode sınıfından olan ve içinde 'text' girişi barındıran düğümü yakala
        if node_info.get("class_type") == "CLIPTextEncode" and "text" in node_info.get("inputs", {}):
            # Negatif prompt kutusunu (genellikle içinde 'text, watermark' yazar) atlamak için kontrol:
            current_text = str(node_info["inputs"]["text"]).lower()
            if "watermark" in current_text or "bad anatomy" in current_text or "embedding" in current_text:
                continue # Bu negatif prompttur, geçiyoruz.
                
            # Doğru pozitif prompt düğümünü bulduk, yeni metnimizi yazıyoruz:
            node_info["inputs"]["text"] = prompt_text
            found_node = True
            print(f"[BAŞARILI] Pozitif prompt düğümü otomatik tespit edildi. ID: {node_id}")
            break
            
    if not found_node:
        return {"status": "error", "message": "JSON içinde uygun CLIPTextEncode düğümü tespit edilemedi."}

    # 2. İsteği ComfyUI API'sine Gönder
    payload = {
        "client_id": "distributed_cluster_pc1",
        "prompt": workflow_data
    }
    
    try:
        response = requests.post(COMFY_URL, json=payload, timeout=10)
        res_json = response.json()
        
        # Eğer ComfyUI tarafı yine de hata döndürürse logu detaylı yakalayalım
        if "error" in res_json:
            return {
                "status": "comfy_error",
                "error_details": res_json["error"],
                "node_errors": res_json.get("node_errors", {})
            }
            
        return {
            "status": "success", 
            "prompt_id": res_json.get("prompt_id"),
            "message": "Görsel üretimi başarıyla tetiklendi."
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}


@celery_app.task(name="tasks.process_3d_rig")
def process_3d_rig(model_name: str):
    """PC-1 üzerindeki Headless Blender konteynerini tetikleyerek asenkron otomatik rig atar"""
    
    # Ortak disk havuzundaki giriş yolu
    in_file = f"/3d_workspace/{model_name}"
    
    # [KESİN DÜZELTME]: Liste (list) riskini tamamen yok edip saf string (metin) üretiyoruz
    if '.' in model_name:
        clean_base = str(model_name.rsplit('.', 1)[0])
    else:
        clean_base = str(model_name)
        
    out_file = f"/3d_workspace/rigged_{clean_base}.fbx"
    
    # Blender Docker konteynerinin içinde yeni güvenli yoldan betiği tetikliyoruz
    docker_blender_cmd = [
        "docker", "exec", "ai_3d_blender",
        "blender", "-b", "--python", "/3d_workspace/rig_automator.py",
        "--", in_file, out_file
    ]       
    
    try:
        print(f"[Kuyruk] Blender 3D Otomatik Rigging Başlatılıyor: {model_name}")
        result = subprocess.run(docker_blender_cmd, capture_output=True, text=True, check=True)
        
        # Blender'ın iç loglarını Celery çıktısına tam besliyoruz
        blender_output = result.stdout if result.stdout else result.stderr
        return {
            "status": "success",
            "message": "3D Rigging otomasyonu tamamlandı.",
            "blender_log": blender_output
        }
    except subprocess.CalledProcessError as e:
        return {
            "status": "error",
            "message": "Blender işlenirken çöktü.",
            "details": e.stderr if e.stderr else e.stdout
        }