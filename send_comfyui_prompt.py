from tasks import generate_image_comfyui

# A futuristic, otherworldly cityscape where geometric shapes form intricate structures floating on air. This city is inhabited by sentient robots and glowing drones hover above the streets.
prompt = "A futuristic, otherworldy cityscape where geometric shapes form intricate structures floating on air. This city is inhabited by sentient robots and glowing drones hover above the streets."

# Send prompt asynchronously to ComfyUI
generate_image_comfyui.delay(prompt)