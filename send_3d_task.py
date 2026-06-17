from tasks import process_3d_rig

# Path to the model file
model_path = "Pc1/shared_3d_data/test_character.fbx"

# Send the 3D rigging task asynchronously to Celery queue
process_3d_rig.delay(model_path)