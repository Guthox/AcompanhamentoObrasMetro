import ifcopenshell
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import FileResponse
import shutil
from ultralytics import YOLO
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
from time import time
import os

app = FastAPI()

# Fix Cors
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/resultados", StaticFiles(directory="resultados"), name="resultados")

@app.get("/resultados/{arquivo}")
def obter_resultado(arquivo: str):
    caminho = os.path.join("resultados", arquivo)

    if not os.path.exists(caminho):
        return {"erro": "Arquivo não encontrado"}

    return FileResponse(
        caminho,
        media_type="image/jpeg",
        headers={
            "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0"
        }
    )


# ============================
# CONFIGURAÇÃO DO YOLO + IFC
# ============================
MODEL_PATH = "best.pt"
IFC_PATH = "ifc2.ifc"
OUTPUT_DIR = "resultados"

os.makedirs(OUTPUT_DIR, exist_ok=True)

print("Carregando modelo YOLO...")
model = YOLO(MODEL_PATH)

print("Carregando arquivo IFC...")
ifc = ifcopenshell.open(IFC_PATH)

# TIPOS_IFC = {
#     "IfcWall": "Wall",
#     "IfcColumn": "Column",
#     "IfcBeam": "Beam",
#     "IfcSlab": "Slab",
#     "IfcDoor": "Door",
#     "IfcWindow": "Window",
# }

TIPOS_IFC = {
    "IfcWall": "Wall",
    "IfcMember": "Column",
    "IfcMember": "Beam",
    "IfcSlab": "Slab",
    "IfcDoor": "Door",
    "IfcWindow": "Window",
}

# Conta itens no IFC
planejado = {tipo: len(ifc.by_type(tipo)) for tipo in TIPOS_IFC}


# ============================
# ROTAS
# ============================

@app.get("/ping")
def ping():
    return {"status": "ok"}


@app.post("/analisar")
async def analisar(
    obra_id: int = Form(...),
    foto: UploadFile = File(...)
):
    """Recebe uma imagem, roda YOLO e compara com IFC."""
    
    # Salvar imagem temporária
    temp_path = f"{OUTPUT_DIR}/obra_{obra_id}_entrada.jpg"
    with open(temp_path, "wb") as buffer:
        shutil.copyfileobj(foto.file, buffer)

    # Rodar YOLO
    resultado = model(temp_path)[0]

    # Criar imagem anotada. USA TEMPO PARA DESATIVAR CACHE NO SITE
    ts = int(time() * 1000)
    anotada_filename = f"obra_{obra_id}_anotada_{ts}.jpg"
    anotada_path = f"resultados/{anotada_filename}"
    resultado.save(filename=anotada_path)

    # anotada_path = f"{OUTPUT_DIR}/obra_{obra_id}_anotada.jpg"
    # resultado.save(filename=anotada_path)

    # Contar detecções YOLO
    detectado = {}
    for det in resultado.boxes:
        classe = model.names[int(det.cls)]
        detectado[classe] = detectado.get(classe, 0) + 1

    # Converter YOLO → IFC
    detectado_ifc = {tipo: 0 for tipo in TIPOS_IFC}

    for ifc_tipo, nome_yolo in TIPOS_IFC.items():
        detectado_ifc[ifc_tipo] = detectado.get(nome_yolo, 0)

    # Calcular progresso
    total_planejado = sum(planejado.values())
    progresso_total = 0
    pesos = {t: planejado[t] / total_planejado for t in planejado}

    progresso_por_tipo = {}

    for tipo_ifc, quant_plan in planejado.items():
        quant_det = detectado_ifc[tipo_ifc]

        prog = (quant_det / quant_plan) if quant_plan > 0 else 0
        progresso_por_tipo[tipo_ifc] = round(prog * 100, 2)

        progresso_total += prog * pesos[tipo_ifc]

    progresso_total = round(progresso_total * 100, 2)

    # Retorno
    return {
    "obra_id": obra_id,
    "planejado": planejado,
    "detectado": detectado,
    "progresso_por_tipo": progresso_por_tipo,
    "progresso_total": progresso_total,
    "imagem_anotada": anotada_filename  
}



@app.get("/imagem/{arquivo}")
def imagem(arquivo: str):
    """Retorna imagem anotada."""
    caminho = f"{OUTPUT_DIR}/{arquivo}"
    if os.path.exists(caminho):
        return FileResponse(caminho)
    return {"erro": "Arquivo não encontrado"}
