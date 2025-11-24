from fastapi import FastAPI, UploadFile, File, Form, HTTPException
import ifcopenshell
import ifcopenshell.geom
import os
import shutil
import numpy as np
import pyvista as pv
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

# --- CONFIGURAÇÕES ---
OUTPUT_DIR = "resultados"
IFC_DIR = "obras_ifc"

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(IFC_DIR, exist_ok=True)

# Servir arquivos estáticos (para o Flutter poder baixar as imagens)
app.mount("/resultados", StaticFiles(directory=OUTPUT_DIR), name="resultados")

# Modelo YOLO (Carregar apenas uma vez)
try:
    model = YOLO("best.pt")
except:
    print("Aviso: Modelo YOLO 'best.pt' não encontrado. As rotas de análise falharão.")
    model = None

# --- FUNÇÃO AUXILIAR DE RENDERIZAÇÃO ---
def gerar_render_ifc(caminho_ifc: str, caminho_saida: str, azimute: float, elevacao: float, zoom: float):
    """Lógica do PyVista encapsulada em uma função"""
    try:
        plotter = pv.Plotter(off_screen=True, window_size=[1024, 768])
        
        ifc_file = ifcopenshell.open(caminho_ifc)
        settings = ifcopenshell.geom.settings()
        settings.set(settings.USE_WORLD_COORDS, True)
        
        products = ifc_file.by_type('IfcProduct')
        mesh_added = False

        for product in products:
            if product.is_a('IfcOpeningElement') or product.is_a('IfcGrid') or product.is_a('IfcAnnotation'):
                continue
            if product.Representation is None:
                continue

            try:
                shape = ifcopenshell.geom.create_shape(settings, product)
                geom = shape.geometry
                verts_np = np.array(geom.verts).reshape(-1, 3)
                faces = geom.faces
                if not faces: continue
                
                n_faces = len(faces) // 3
                padding = np.full((n_faces, 1), 3)
                faces_np = np.array(faces).reshape(n_faces, 3)
                pv_faces = np.hstack((padding, faces_np)).flatten()

                mesh = pv.PolyData(verts_np, faces=pv_faces)
                plotter.add_mesh(mesh, color='lightgrey', smooth_shading=True)
                mesh_added = True
            except:
                pass

        if not mesh_added:
            plotter.close()
            raise Exception("Nenhuma geometria válida encontrada no IFC.")

        # Configura Câmera
        plotter.enable_parallel_projection()
        plotter.view_isometric()
        plotter.camera.azimuth = azimute
        plotter.camera.elevation = elevacao
        plotter.camera.Zoom(zoom)

        plotter.screenshot(caminho_saida)
        plotter.close()
        return True
    except Exception as e:
        print(f"Erro no PyVista: {e}")
        if 'plotter' in locals():
            plotter.close()
        return False

# --- ROTAS ---

@app.post("/enviar_ifc")
async def enviar_ifc(obra_id: int = Form(...), ifc: UploadFile = File(...)):
    destino = f"{IFC_DIR}/obra_{obra_id}.ifc"
    with open(destino, "wb") as f:
        f.write(await ifc.read())
    return {"status": "ok", "msg": "IFC salvo com sucesso"}

@app.post("/renderizar_camera")
async def renderizar_camera(
    obra_id: int = Form(...),
    azimuth: float = Form(...),
    elevation: float = Form(...),
    zoom: float = Form(...)
):
    """Gera um render baseado no IFC já salvo e nos parâmetros da câmera"""
    
    caminho_ifc = f"{IFC_DIR}/obra_{obra_id}.ifc"
    
    if not os.path.exists(caminho_ifc):
        raise HTTPException(status_code=404, detail="IFC da obra não encontrado. Faça upload primeiro.")

    # Nome único para a imagem
    ts = int(time() * 1000)
    nome_imagem = f"render_{obra_id}_{ts}.png"
    caminho_saida = f"{OUTPUT_DIR}/{nome_imagem}"

    # Chama a função de renderização
    sucesso = gerar_render_ifc(caminho_ifc, caminho_saida, azimuth, elevation, zoom)

    if not sucesso:
        raise HTTPException(status_code=500, detail="Falha ao gerar renderização 3D.")

    # Retorna a URL completa (ajuste o localhost se estiver em produção)
    image_url = f"http://127.0.0.1:8000/resultados/{nome_imagem}"

    return {
        "status": "ok",
        "image_url": image_url,
        "local_path": nome_imagem
    }