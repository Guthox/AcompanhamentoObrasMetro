from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Depends
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
#imports do banco de dados
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, Text, text, BigInteger, ForeignKey, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship
from datetime import datetime
from pydantic import BaseModel
from typing import Optional, Dict


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# --- BANCO DE DADOS ---
DB_USER = "root"
DB_PASSWORD = "123456"  # <--- UTILIZAR SENHA DO SEU SQL
DB_HOST = "localhost"
DB_PORT = "3306"
DB_NAME = "metro_sp"

SERVER_URL = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}"

try:
    engine_server = create_engine(SERVER_URL)
    with engine_server.connect() as conn:
        conn.execute(text(f"CREATE DATABASE IF NOT EXISTS {DB_NAME}"))
        print(f"--- Banco de dados '{DB_NAME}' verificado/criado com sucesso ---")
except Exception as e:
    print(f"Erro ao tentar criar database: {e}")

#utilizar a senha do seu sql
SQLALCHEMY_DATABASE_URL = "mysql+pymysql://root:123456@localhost:3306/metro_sp"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# --- TABELA DE USUÁRIOS ---
class Usuario(Base):
    __tablename__ = "usuarios"
    id = Column(BigInteger, primary_key=True, index=True)
    nome = Column(String(100))
    email = Column(String(100), unique=True, index=True)
    senha = Column(String(100))

# --- TABELA DE OBRAS (SEM IFC) ---
class ObraDB(Base):
    __tablename__ = "obras"
    id = Column(BigInteger, primary_key=True, index=True) # ID vindo do Flutter
    nome = Column(String(100))
    descricao = Column(Text)
    localizacao = Column(String(100))
    responsavel = Column(String(100))
    status = Column(String(50))
    data_inicio = Column(DateTime)
    data_fim = Column(DateTime, nullable=True)
    progresso = Column(Float, default=0.0)
    caminho_ifc = Column(String(255), nullable=True)

    cameras = relationship("CameraDB", back_populates="obra", cascade="all, delete-orphan")

class CameraDB(Base):
    __tablename__ = "cameras"
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    obra_id = Column(BigInteger, ForeignKey("obras.id"))
    nome = Column(String(100))
    angulo_x = Column(Float)
    angulo_y = Column(Float)
    zoom = Column(Float)
    render_url = Column(String(255)) # URL da imagem gerada pelo PyVista
    estatisticas = Column(JSON, nullable=True) # JSON com a contagem do YOLO
    
    # Campos para a foto real (opcionais no início)
    render_real_anotado_url = Column(String(255), nullable=True)
    estatisticas_real = Column(JSON, nullable=True)
    progresso = Column(Float, default=0.0)

    # Relacionamento inverso
    obra = relationship("ObraDB", back_populates="cameras")

# Cria as tabelas automaticamente ao iniciar o código
Base.metadata.create_all(bind=engine)

# Função para obter a sessão do banco
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# No arquivo backend.py

def atualizar_progresso_obra(obra_id: int, db: Session):
    """Calcula a média do progresso das câmeras e salva na obra"""
    cameras = db.query(CameraDB).filter(CameraDB.obra_id == obra_id).all()
    
    if not cameras:
        obra = db.query(ObraDB).filter(ObraDB.id == obra_id).first()
        if obra:
            obra.progresso = 0.0
            db.commit()
            print(f"Obra {obra_id}: Sem câmeras. Progresso zerado.")
        return

    soma_progresso = sum([c.progresso for c in cameras])
    media = soma_progresso / len(cameras)
    
    obra = db.query(ObraDB).filter(ObraDB.id == obra_id).first()
    if obra:
        obra.progresso = media
        db.commit()
        print(f"Progresso da obra {obra_id} atualizado para {media:.2f}")

# --- MODELOS PARA RECEBER JSON (Pydantic) ---
class UsuarioCreate(BaseModel):
    nome: str
    email: str
    senha: str

class LoginData(BaseModel):
    email: str
    senha: str

# No backend.py

class ObraCreate(BaseModel):
    id: int
    nome: str
    descricao: str
    localizacao: str
    responsavel: str
    status: str
    data_inicio: Optional[str] = None 
    data_fim: Optional[str] = None

class CameraCreate(BaseModel):
    obra_id: int
    nome: str
    angulo_x: float
    angulo_y: float
    zoom: float
    render_url: str
    estatisticas: Optional[Dict] = {}

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
        plotter.window_size = [1024, 1024]

        plotter.screenshot(caminho_saida)
        plotter.close()
        return True
    except Exception as e:
        print(f"Erro no PyVista: {e}")
        if 'plotter' in locals():
            plotter.close()
        return False
    
def aplicar_boost_progresso(progresso: float) -> float:
    if progresso <= 0.0: return 0.0
    if progresso >= 1.0: return 1.0
    
    # Lógica de "boost" para compensar alucinação da IA
    if progresso < 0.5:
        return progresso
    elif progresso < 0.8:
        return min(1.0, progresso + 0.1)
    elif progresso < 0.95:
        return min(1.0, progresso + 0.05)
    
    return progresso

# --- ROTAS ---

@app.post("/cadastro")
def cadastrar_usuario(usuario: UsuarioCreate, db: Session = Depends(get_db)):
    # Verifica se email já existe
    if db.query(Usuario).filter(Usuario.email == usuario.email).first():
        raise HTTPException(status_code=400, detail="Email já cadastrado")
    
    novo = Usuario(nome=usuario.nome, email=usuario.email, senha=usuario.senha)
    db.add(novo)
    db.commit()
    return {"msg": "Usuário criado com sucesso"}

@app.post("/login")
def login_usuario(dados: LoginData, db: Session = Depends(get_db)):
    user = db.query(Usuario).filter(Usuario.email == dados.email).first()
    if not user or user.senha != dados.senha:
        raise HTTPException(status_code=401, detail="Credenciais inválidas")
    return {"msg": "Login autorizado", "nome": user.nome}

@app.post("/criar_obra")
def criar_obra_db(obra: ObraCreate, db: Session = Depends(get_db)):
    # Converte strings de data para formato Python
    dt_inicio = datetime.fromisoformat(obra.data_inicio.replace("Z", ""))
    dt_fim = datetime.fromisoformat(obra.data_fim.replace("Z", "")) if obra.data_fim else None

    nova = ObraDB(
        id=obra.id,
        nome=obra.nome,
        descricao=obra.descricao,
        localizacao=obra.localizacao,
        responsavel=obra.responsavel,
        status=obra.status,
        data_inicio=dt_inicio,
        data_fim=dt_fim,
        progresso=0.0,
        caminho_ifc=""
    )
    db.add(nova)
    db.commit()
    return {"msg": "Obra salva no banco com sucesso"}

@app.post("/enviar_ifc")
async def enviar_ifc(
    obra_id: int = Form(...),
    ifc: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """Recebe e salva o arquivo IFC vinculado à obra."""

    IFC_DIR = "obras_ifc"
    os.makedirs(IFC_DIR, exist_ok=True)

    destino = f"{IFC_DIR}/obra_{obra_id}.ifc"

    with open(destino, "wb") as f:
        f.write(await ifc.read())

    obra = db.query(ObraDB).filter(ObraDB.id == obra_id).first()
    if obra:
        obra.caminho_ifc = destino
        db.commit()

    return {"status": "ok", "msg": "IFC salvo com sucesso", "arquivo": destino}


@app.get("/obras")
def listar_obras(db: Session = Depends(get_db)):
    obras = db.query(ObraDB).all()
    return [
        {
            "id": o.id,
            "nome": o.nome,
            "descricao": o.descricao,
            "localizacao": o.localizacao,
            "responsavel": o.responsavel,
            "status": o.status,
            "data_inicio": o.data_inicio.isoformat(),
            "data_fim": o.data_fim.isoformat() if o.data_fim else None,
            "progresso": o.progresso,
            "caminho_ifc": o.caminho_ifc
        }
        for o in obras
    ]

@app.delete("/obras/{obra_id}")
def deletar_obra(obra_id: int, db: Session = Depends(get_db)):
    obra = db.query(ObraDB).filter(ObraDB.id == obra_id).first()

    if not obra:
        return {"erro": "Obra não encontrada"}

    # Remove obra do banco
    db.delete(obra)
    db.commit()

    # Apaga o IFC vinculado
    caminho_ifc = f"{IFC_DIR}/obra_{obra_id}.ifc"
    if os.path.exists(caminho_ifc):
        os.remove(caminho_ifc)

    return {"msg": "Obra excluída com sucesso"}


@app.get("/obra/{obra_id}")
def get_obra(obra_id: int, db: Session = Depends(get_db)):
    obra = db.query(ObraDB).filter(ObraDB.id == obra_id).first()
    if not obra:
        return {"erro": "Obra não encontrada"}
    
    return {
        "id": obra.id,
        "nome": obra.nome,
        "descricao": obra.descricao,
        "localizacao": obra.localizacao,
        "responsavel": obra.responsavel,
        "status": obra.status,
        "data_inicio": obra.data_inicio.isoformat(),
        "data_fim": obra.data_fim.isoformat() if obra.data_fim else None,
        "progresso": obra.progresso,
        "caminho_ifc": obra.caminho_ifc
    }



@app.post("/analisar")
async def analisar(
    obra_id: int = Form(...),
    foto: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    # -------------------------
    # 1) CARREGA IFC DA OBRA
    # -------------------------
    obra_db = db.query(ObraDB).filter(ObraDB.id == obra_id).first()
    
    if obra_db and obra_db.caminho_ifc:
        caminho_ifc = obra_db.caminho_ifc
    else:
        caminho_ifc = f"{IFC_DIR}/obra_{obra_id}.ifc" # Fallback

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

    #Salva progresso no bd
    obra_db = db.query(ObraDB).filter(ObraDB.id == obra_id).first()
    if obra_db:
        obra_db.progresso = progresso_total / 100.0
        db.commit()

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

@app.post("/renderizar_camera")
async def renderizar_camera(
    obra_id: int = Form(...),
    azimuth: float = Form(...),
    elevation: float = Form(...),
    zoom: float = Form(...),
    db: Session = Depends(get_db)
):
    # Busca IFC
    obra = db.query(ObraDB).filter(ObraDB.id == obra_id).first()
    if not obra or not obra.caminho_ifc:
        caminho_ifc = f"{IFC_DIR}/obra_{obra_id}.ifc"
        if not os.path.exists(caminho_ifc):
             raise HTTPException(status_code=404, detail="IFC não encontrado.")
    else:
        caminho_ifc = obra.caminho_ifc

    # Gera nome único
    ts = int(time() * 1000)
    nome_imagem = f"render_{obra_id}_{ts}.png"
    caminho_saida = f"{OUTPUT_DIR}/{nome_imagem}"

    # 1. RENDERIZAÇÃO (PyVista)
    sucesso = gerar_render_ifc(caminho_ifc, caminho_saida, azimuth, elevation, zoom)

    if not sucesso:
        raise HTTPException(status_code=500, detail="Falha ao gerar renderização 3D.")

    # 2. PREDIÇÃO (YOLO)
    estatisticas = {}
    total_objetos = 0

    if model:
        try:
            # Roda a predição na imagem recém gerada
            results = model(caminho_saida)
            
            # Conta as classes detectadas
            for r in results:
                for box in r.boxes:
                    cls_id = int(box.cls)
                    class_name = model.names[cls_id]
                    estatisticas[class_name] = estatisticas.get(class_name, 0) + 1
                    total_objetos += 1
            
        except Exception as e:
            print(f"Erro na inferência YOLO: {e}")
            estatisticas = {"erro": "Falha na detecção"}

    image_url = f"http://127.0.0.1:8000/resultados/{nome_imagem}"

    return {
        "status": "ok",
        "image_url": image_url,
        "local_path": nome_imagem,
        "estatisticas": estatisticas, 
        "total_objetos": total_objetos
    }

@app.post("/salvar_camera")
def salvar_camera(cam: CameraCreate, db: Session = Depends(get_db)):
    nova_cam = CameraDB(
        obra_id=cam.obra_id,
        nome=cam.nome,
        angulo_x=cam.angulo_x,
        angulo_y=cam.angulo_y,
        zoom=cam.zoom,
        render_url=cam.render_url,
        estatisticas=cam.estatisticas,
        progresso=0.0
    )
    db.add(nova_cam)
    db.commit()
    db.refresh(nova_cam)

    atualizar_progresso_obra(cam.obra_id, db)
    return {"msg": "Câmera salva", "id": nova_cam.id}


@app.get("/cameras/{obra_id}")
def listar_cameras(obra_id: int, db: Session = Depends(get_db)):
    cameras = db.query(CameraDB).filter(CameraDB.obra_id == obra_id).all()
    return [
        {
            "id": c.id,
            "nome": c.nome,
            "angulo_x": c.angulo_x,
            "angulo_y": c.angulo_y,
            "zoom": c.zoom,
            "render_url": c.render_url,
            "estatisticas": c.estatisticas,
            "estatisticas_real": c.estatisticas_real,
            "render_real_anotado_url": c.render_real_anotado_url
        }
        for c in cameras
    ]

@app.delete("/cameras/{camera_id}")
def deletar_camera(camera_id: int, db: Session = Depends(get_db)):
    cam = db.query(CameraDB).filter(CameraDB.id == camera_id).first()
    
    if not cam: 
        return {"erro": "Câmera não encontrada"}
    id_da_obra = cam.obra_id 
    db.delete(cam)
    db.commit()

    atualizar_progresso_obra(id_da_obra, db)

    return {"msg": "Câmera deletada"}

@app.post("/analisar_foto_real_camera")
async def analisar_foto_real_camera(
    camera_id: int = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """ [NOVO] Analisa foto e salva resultados na câmera específica do banco """
    ts = int(time() * 1000)
    temp_path = os.path.join(OUTPUT_DIR, f"temp_real_{ts}.jpg")
    with open(temp_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    estatisticas_real = {}
    url_anotada = ""

    if model:
        results = model(temp_path)
        for r in results:
            for box in r.boxes:
                cls_id = int(box.cls)
                class_name = model.names[cls_id]
                estatisticas_real[class_name] = estatisticas_real.get(class_name, 0) + 1
            
            nome_anotada = f"anotada_cam_{camera_id}_{ts}.jpg"
            caminho_anotada = os.path.join(OUTPUT_DIR, nome_anotada)
            r.save(filename=caminho_anotada)
            url_anotada = f"http://127.0.0.1:8000/resultados/{nome_anotada}"

    # Atualiza a câmera no banco
    cam = db.query(CameraDB).filter(CameraDB.id == camera_id).first()
    if cam:
        cam.estatisticas_real = estatisticas_real
        cam.render_real_anotado_url = url_anotada
        
        if cam.estatisticas:
            total_esperado = sum(cam.estatisticas.values())
            total_real = 0
            for key, qtd_esperada in cam.estatisticas.items():
                qtd_real = estatisticas_real.get(key, 0)
                total_real += min(qtd_real, qtd_esperada)
            
            progresso_bruto = 0.0
            if total_esperado > 0:
                progresso_bruto = total_real / total_esperado
            
            cam.progresso = aplicar_boost_progresso(progresso_bruto)
            
        db.commit()
        atualizar_progresso_obra(cam.obra_id, db)

    return {
        "status": "ok",
        "estatisticas_real": estatisticas_real,
        "imagem_anotada_url": url_anotada,
        "progresso_calculado": cam.progresso
    }


@app.post("/analisar_foto_real")
async def analisar_foto_real(file: UploadFile = File(...)):
    """
    Recebe uma foto real, roda o YOLO, conta objetos e retorna a URL da imagem anotada.
    """
    try:
        # 1. Salva a imagem original temporariamente
        ts = int(time() * 1000)
        temp_filename = f"temp_real_{ts}.jpg"
        temp_path = os.path.join(OUTPUT_DIR, temp_filename)
        
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        estatisticas_real = {}
        caminho_anotada = ""
        url_anotada = ""

        # 2. Roda o YOLO
        if model:
            # O YOLO retorna uma lista de resultados (um para cada imagem)
            results = model(temp_path)
            
            for r in results:
                # a. Conta as classes
                for box in r.boxes:
                    cls_id = int(box.cls)
                    class_name = model.names[cls_id]
                    estatisticas_real[class_name] = estatisticas_real.get(class_name, 0) + 1
                
                # b. Salva a imagem com as anotações (plot() gera a imagem)
                # Gera um nome para a imagem anotada
                nome_anotada = f"anotada_{ts}.jpg"
                caminho_anotada = os.path.join(OUTPUT_DIR, nome_anotada)
                
                # Salva a imagem plotada (o array numpy) no disco
                # Usamos o OpenCV (cv2) ou PIL para salvar o array
                import cv2
                # O results[0].plot() retorna um array BGR (para opencv)
                img_anotada_np = r.plot() 
                cv2.imwrite(caminho_anotada, img_anotada_np)
                
                # Cria a URL pública
                # AJUSTE O IP/PORTA SE NECESSÁRIO
                url_anotada = f"http://127.0.0.1:8000/resultados/{nome_anotada}"

        # Opcional: Remover a imagem original temporária
        # os.remove(temp_path) 

        return {
            "status": "ok",
            "estatisticas_real": estatisticas_real,
            "imagem_anotada_url": url_anotada, # Retorna a nova URL
            "imagem_anotada_path": nome_anotada # Retorna o nome do arquivo
        }

    except Exception as e:
        print(f"Erro ao analisar foto real: {e}")
        # Tenta limpar arquivo temporário em caso de erro
        if 'temp_path' in locals() and os.path.exists(temp_path):
             os.remove(temp_path)
        return {"status": "error", "detail": str(e)}