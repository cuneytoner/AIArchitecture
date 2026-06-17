import sys
import os

try:
    import bpy
except ImportError:
    print("Bu betik sadece Blender konteyneri içinde çalıştırılabilir!")
    sys.exit(1)

def auto_rig_process(input_path, output_path):
    """Gelen 3D modeli Blender içine aktarır, temel humanoid kemik yapısı kurar ve kaydeder"""
    # 1. Sahneyi temizle
    bpy.ops.wm.read_factory_settings(use_empty=True)
    
    # 2. Dosya türüne göre içeri aktar
    if input_path.endswith('.fbx'):
        bpy.ops.import_scene.fbx(filepath=input_path)
    elif input_path.endswith('.obj'):
        bpy.ops.import_scene.obj(filepath=input_path)
    else:
        print(f"Desteklenmeyen dosya formatı: {input_path}")
        return False

    print(f"[BLENDER] 3D Model başarıyla yüklendi: {input_path}")

    # 3. Otomatik Temel İskelet (Armature) Oluşturma Otomasyonu
    # Modelin bounding box (boyut) sınırlarına göre basit bir dikey omurga kemiği ekliyoruz
    bpy.ops.object.armature_add(radius=1.0, enter_editmode=False, location=(0, 0, 0))
    armature_obj = bpy.context.active_object
    armature_obj.name = "Auto_AI_Rig_Skeleton"

    # 4. Mesh Modellerini Bul ve İskelete Kemikle (Parenting with Automatic Weights)
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            # Mesh modelini seç ve aktif yap
            bpy.ops.object.select_all(action='DESELECT')
            obj.select_set(True)
            armature_obj.select_set(True)
            bpy.context.view_layer.objects.active = armature_obj
            
            # Kemikleri modele otomatik ağırlıklandırarak bağla (Rigging İşlemi)
            try:
                bpy.ops.object.parent_set(type='ARMATURE_AUTO')
                print(f"[BLENDER] '{obj.name}' karakteri iskelete başarıyla riglendi.")
            except Exception as e:
                print(f"[UYARI] Otomatik ağırlıklandırma atlanıyor (Aparatsız mesh): {e}")

    # 5. Riglenmiş Modeli Yeni FBX Olarak Dışa Aktar
    bpy.ops.export_scene.fbx(filepath=output_path, use_selection=False)
    print(f"[BAŞARILI] Riglenmiş AI 3D modeli kaydedildi: {output_path}")
    return True

if __name__ == "__main__":
    # Konsoldan gelen argümanları yakala (Blender headless mod parametreleri)
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if len(args) >= 2:
        auto_rig_process(args[0], args[1])
    else:
        print("HATA: Girdi ve çıktı dosya yolları eksik!")
