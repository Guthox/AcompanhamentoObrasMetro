from fastapi import FastAPI, UploadFile, File, Form
import ifcopenshell
import os
import shutil
from ultralytics import YOLO
from time import time
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pastas
OUTPUT_DIR = "resultados"
IFC_DIR = "obras_ifc"

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(IFC_DIR, exist_ok=True)

# YOLO
model = YOLO("best.pt")

# MAPEAMENTO
TIPOS_IFC = {
    "IfcWall": "Wall",
    "IfcMember": "Column",
    "IfcBeam": "Beam",
    "IfcSlab": "Slab",
    "IfcDoor": "Door",
    "IfcWindow": "Window",
}

app.mount("/resultados", StaticFiles(directory=OUTPUT_DIR), name="resultados")

@app.post("/enviar_ifc")
async def enviar_ifc(
    obra_id: int = Form(...),
    ifc: UploadFile = File(...)
):
    """Recebe e salva o arquivo IFC vinculado à obra."""

    IFC_DIR = "obras_ifc"
    os.makedirs(IFC_DIR, exist_ok=True)

    destino = f"{IFC_DIR}/obra_{obra_id}.ifc"

    with open(destino, "wb") as f:
        f.write(await ifc.read())

    return {"status": "ok", "msg": "IFC salvo com sucesso", "arquivo": destino}



@app.post("/analisar")
async def analisar(
    obra_id: int = Form(...),
    foto: UploadFile = File(...)
):
    # -------------------------
    # 1) CARREGA IFC DA OBRA
    # -------------------------
    caminho_ifc = f"{IFC_DIR}/obra_{obra_id}.ifc"

    if not os.path.exists(caminho_ifc):
        return {"erro": f"Arquivo IFC da obra {obra_id} não encontrado"}

    ifc = ifcopenshell.open(caminho_ifc)

    # Conta planejado
    planejado = {tipo: len(ifc.by_type(tipo)) for tipo in TIPOS_IFC}

    # -------------------------
    # 2) Salva imagem enviada
    # -------------------------
    temp_path = f"{OUTPUT_DIR}/obra_{obra_id}_entrada.jpg"

    with open(temp_path, "wb") as buffer:
        shutil.copyfileobj(foto.file, buffer)

    # -------------------------
    # 3) YOLO
    # -------------------------
    result = model(temp_path)[0]

    # Salva imagem anotada SEM duplicar diretórios
    ts = int(time() * 1000)
    anotada_filename = f"anotada_{obra_id}_{ts}.jpg"
    anotada_path = f"{OUTPUT_DIR}/{anotada_filename}"

    result.save(filename=anotada_path)

    # -------------------------
    # 4) Detecções YOLO
    # -------------------------
    detectado = {}

    for det in result.boxes:
        nome = model.names[int(det.cls)]
        detectado[nome] = detectado.get(nome, 0) + 1

    # YOLO → IFC
    detect_ifc = {
        tipo: detectado.get(nome_yolo, 0)
        for tipo, nome_yolo in TIPOS_IFC.items()
    }

    # -------------------------
    # 5) Progresso
    # -------------------------
    total_plan = sum(planejado.values()) or 1
    pesos = {t: planejado[t] / total_plan for t in planejado}

    progresso_total = 0
    progresso_tipo = {}

    for tipo in planejado:
        det = detect_ifc[tipo]
        plan = planejado[tipo]

        pct = det / plan if plan > 0 else 0
        progresso_tipo[tipo] = round(pct * 100, 2)
        progresso_total += pct * pesos[tipo]

    progresso_total = round(progresso_total * 100, 2)

    # -------------------------
    # 6) Retorno
    # -------------------------
    return {
        "obra_id": obra_id,
        "planejado": planejado,
        "detectado": detectado,
        "progresso_por_tipo": progresso_tipo,
        "progresso_total": progresso_total,
        "imagem_anotada": anotada_filename
    }
