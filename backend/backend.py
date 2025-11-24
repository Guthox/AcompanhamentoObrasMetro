from fastapi import FastAPI, UploadFile, File, Form, Depends
import ifcopenshell
import os
import shutil
from ultralytics import YOLO
from time import time
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
#imports do banco de dados
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, Text, text, BigInteger
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from datetime import datetime
from pydantic import BaseModel

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


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
    # Note que NÃO salvamos nada sobre IFC aqui.

# Cria as tabelas automaticamente ao iniciar o código
Base.metadata.create_all(bind=engine)

# Função para obter a sessão do banco
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- MODELOS PARA RECEBER JSON (Pydantic) ---
class UsuarioCreate(BaseModel):
    nome: str
    email: str
    senha: str

class LoginData(BaseModel):
    email: str
    senha: str

class ObraCreate(BaseModel):
    id: int
    nome: str
    descricao: str
    localizacao: str
    responsavel: str
    status: str
    data_inicio: str 
    data_fim: str = None

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
        progresso=0.0
    )
    db.add(nova)
    db.commit()
    return {"msg": "Obra salva no banco com sucesso"}

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
    foto: UploadFile = File(...),
    db: Session = Depends(get_db)
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
