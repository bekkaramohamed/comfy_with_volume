# syntax=docker/dockerfile:1.4
FROM runpod/worker-comfyui:5.1.0-base

# =======================================================
# ⚙️ Dépendances système
# =======================================================
RUN apt-get update && apt-get install -y --no-install-recommends git curl && rm -rf /var/lib/apt/lists/*

# =======================================================
# 🔗 Préparation des liens symboliques pour RunPod
# =======================================================
# /workspace -> /runpod-volume
# /comfyui/models -> /runpod-volume/models
RUN mkdir -p /runpod-volume/models && \
    rm -rf /workspace && ln -s /runpod-volume /workspace && \
    rm -rf /comfyui/models && ln -s /runpod-volume/models /comfyui/models && \
    echo "🔗 Symlinks created:" && \
    ls -l / | grep runpod-volume && ls -l /comfyui | grep models

# =======================================================
# 🔍 Torch + CUDA Check
# =======================================================
RUN echo "🧠 Checking Torch and CUDA version..." && \
    python3 -c "import torch; print(f'Torch version: {torch.__version__}, CUDA: {torch.version.cuda}')"

# =======================================================
# ⚙️ Installation de Nunchaku
# =======================================================
RUN echo "📦 Installing Nunchaku wheel..." && \
    pip install --no-cache-dir \
      'https://github.com/nunchaku-tech/nunchaku/releases/download/v1.0.0/nunchaku-1.0.0+torch2.6-cp312-cp312-linux_x86_64.whl'

# =======================================================
# 🧩 Installation des nodes depuis le registry
# =======================================================
RUN echo "🧩 Installing registry-based custom nodes..." && \
    comfy-node-install \
      rgthree-comfy \
      ComfyUI-nunchaku \
      ComfyUI-WanVideoWrapper || true

# =======================================================
# 🧠 Clonage manuel des nodes non présents dans le registry
# =======================================================
RUN echo "📦 Cloning manual custom nodes..." && \
    cd /comfyui/custom_nodes && \
    git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    git clone --depth 1 https://github.com/shiimizu/ComfyUI-TiledDiffusion.git && \
    rm -rf /comfyui/custom_nodes/*/.git && \
    echo "📥 Installing deps for manually cloned nodes..." && \
    for d in /comfyui/custom_nodes/*; do \
      if [ -f "$d/requirements.txt" ]; then \
        echo "📦 Installing deps for $d..." && pip install -r "$d/requirements.txt" || true; \
      fi; \
    done

# =======================================================
# ✅ Vérifications finales
# =======================================================
RUN echo "✅ Installed custom nodes:" && ls -1 /comfyui/custom_nodes && \
    echo "✅ Symlinked model directory:" && ls -l /comfyui/models
