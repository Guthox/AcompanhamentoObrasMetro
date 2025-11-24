import ifcopenshell
import ifcopenshell.geom
import pyvista as pv
import numpy as np
import os
import sys
import json
import scipy


# --- 1. Configurações ---
IFC_FILE = r"E:\Dudu\Maua\6_semestre\PI\simulacao\MB-1.04.04.02-6J2-1001-1_v7.ifc"
OUTPUT_DIR = r"E:\Dudu\Maua\6_semestre\PI\simulacao\visibilidade_json"

# Cria pasta de saída se não existir
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Verifica se o IFC existe
if not os.path.isfile(IFC_FILE):
    print(f"❌ ERRO: Arquivo IFC não encontrado: {IFC_FILE}")
    sys.exit(1)

# --- Funções Auxiliares ---
def int_to_rgb(val):
    """
    Converte um número inteiro em uma cor RGB única (0-255).
    Isso nos permite criar até 16 milhões de cores únicas (IDs).
    """
    r = (val >> 16) & 255
    g = (val >> 8) & 255
    b = val & 255
    return (r, g, b)

# --- 2. Iniciar o PyVista (Modo Análise) ---
print("Iniciando PyVista...")
# Importante: Desligamos o anti-aliasing para as cores não se misturarem nas bordas
plotter = pv.Plotter(off_screen=True, window_size=[1024, 1024])
plotter.disable_anti_aliasing() 

# --- 3. Ler IFC e Mapear IDs ---
print("Lendo arquivo IFC e gerando geometria...")
ifc_file = ifcopenshell.open(IFC_FILE)
settings = ifcopenshell.geom.settings()
settings.set(settings.USE_WORLD_COORDS, True)

products = ifc_file.by_type('IfcProduct')

# Dicionários para controlar quem é quem
# Cor (Tuple) -> GlobalId (String)
mapa_cor_para_id = {} 

contador_id = 1 # Começamos do 1 (0 geralmente é fundo preto)

for product in products:
    if product.is_a('IfcOpeningElement') or product.is_a('IfcGrid') or product.is_a('IfcAnnotation'):
        continue
    if product.Representation is None:
        continue

    try:
        shape = ifcopenshell.geom.create_shape(settings, product)
        geom = shape.geometry
        
        # Criação da Mesh (igual ao seu código anterior)
        verts_np = np.array(geom.verts).reshape(-1, 3)
        faces = geom.faces
        if not faces: continue
        n_faces = len(faces) // 3
        padding = np.full((n_faces, 1), 3)
        faces_np = np.array(faces).reshape(n_faces, 3)
        pv_faces = np.hstack((padding, faces_np)).flatten()
        mesh = pv.PolyData(verts_np, faces=pv_faces)
        
        # --- A MÁGICA ACONTECE AQUI ---
        # 1. Geramos uma cor única baseada no contador
        cor_rgb = int_to_rgb(contador_id)
        
        # 2. Guardamos quem é o dono dessa cor no dicionário
        # O PyVista precisa da cor normalizada entre 0 e 1, mas guardamos 0-255 para comparar com a imagem
        mapa_cor_para_id[cor_rgb] = {
            "GlobalId": product.GlobalId,
            "Class": product.is_a(),
            "Name": product.Name
        }
        
        # 3. Adicionamos a malha com essa cor específica
        # lighting=False garante que não haja sombras alterando a cor
        plotter.add_mesh(mesh, color=cor_rgb, lighting=False, show_scalar_bar=False)
        
        contador_id += 1

    except Exception as e:
        pass

print(f"Cena carregada. {len(mapa_cor_para_id)} objetos mapeados.")

# --- 4. Configurar Câmera (Igual ao script de render) ---
plotter.view_isometric()
plotter.camera.azimuth = 0
plotter.camera.elevation = -30
plotter.camera.Zoom(1.5)

# Pega o azimute base
try:
    base_az = float(plotter.camera.azimuth)
except:
    base_az = 90.0

# --- 5. Loop de "Detecção Visual Inteligente" ---
print("Iniciando varredura com Agrupamento Visual (Simulando YOLO)...")

angulos_para_processar = range(0, 360, 30)
MINIMO_PIXELS_VISIVEIS = 400 

# Mapeamento simplificado para agrupar classes (Ex: tudo que é parede vira 'parede')
# A chave é o nome que o YOLO usa, o valor é uma lista de classes IFC correspondentes
DE_PARA_CLASSES = {
    "viga": ["IfcBeam", "IfcMember"],
    "coluna": ["IfcColumn", "IfcPile"],
    "parede": ["IfcWall", "IfcWallStandardCase"],
    "laje": ["IfcSlab", "IfcRoof", "IfcPlate"]
}

for angulo in angulos_para_processar:
    atual_az = base_az + angulo
    
    try:
        plotter.camera.azimuth = atual_az
    except:
        plotter.camera.Azimuth(atual_az - plotter.camera.GetAzimuth())
    
    plotter.render()
    
    # Captura a imagem bruta (H, W, 3)
    image_array = plotter.screenshot(return_img=True)
    
    # --- OTIMIZAÇÃO: Converter RGB para ID Inteiro Único ---
    # Isso acelera muito o processamento em vez de comparar tuplas RGB
    # Fórmula: R * 65536 + G * 256 + B
    id_image = image_array[:,:,0].astype(np.uint32) * 65536 + \
               image_array[:,:,1].astype(np.uint32) * 256 + \
               image_array[:,:,2].astype(np.uint32)
    
    # Recupera quais IDs (Cores) estão presentes nesta imagem
    cores_presentes_int = np.unique(id_image)
    
    resumo_contagem = {}
    total_objetos_visuais = 0
    
    # Processar classe por classe (ex: Primeiro conta todas as vigas, depois colunas...)
    for nome_yolo, classes_ifc in DE_PARA_CLASSES.items():
        
        # 1. Identificar quais IDs do IFC pertencem a essa classe (ex: IDs de todas as vigas)
        ids_desta_classe = []
        for cor_int in cores_presentes_int:
            # Reconverte int para rgb para buscar no dicionário
            r = (cor_int >> 16) & 255
            g = (cor_int >> 8) & 255
            b = cor_int & 255
            cor_tuple = (r, g, b)
            
            if cor_tuple in mapa_cor_para_id:
                info = mapa_cor_para_id[cor_tuple]
                # Verifica se a classe do objeto está na lista que estamos procurando
                for cls_ifc in classes_ifc:
                    if cls_ifc.lower() in info['Class'].lower():
                        ids_desta_classe.append(cor_int)
                        break
        
        if not ids_desta_classe:
            resumo_contagem[nome_yolo] = 0
            continue

        # 2. Criar uma MÁSCARA BINÁRIA apenas com objetos dessa classe
        # Onde for viga = 1, resto = 0
        mascara = np.isin(id_image, ids_desta_classe)
        
        # 3. Limpeza de ruído (Remove pontinhos isolados menores que o limiar)
        # Primeiro rotulamos para medir o tamanho
        labeled_array, num_features = scipy.ndimage.label(mascara)
        
        # Conta tamanho de cada componente
        component_sizes = scipy.ndimage.sum(mascara, labeled_array, range(1, num_features + 1))
        
        # Filtra apenas componentes grandes
        # Isso remove parafusos ou pedacinhos de viga que aparecem num canto
        valid_components = component_sizes > MINIMO_PIXELS_VISIVEIS
        count_final = valid_components.sum()
        
        resumo_contagem[nome_yolo] = int(count_final)
        total_objetos_visuais += int(count_final)

    # Salva o JSON
    nome_json = f"visibilidade_agrupada_{angulo}.json"
    caminho_json = os.path.join(OUTPUT_DIR, nome_json)
    
    dados_saida = {
        "angulo": angulo,
        "total_visuais_esperados": total_objetos_visuais,
        "detalhe_por_classe": resumo_contagem
    }
    
    with open(caminho_json, 'w') as f:
        json.dump(dados_saida, f, indent=4)
        
    print(f"📸 Ângulo {angulo}°: {total_objetos_visuais} objetos visuais (Vigas unidas, etc). {resumo_contagem}")

plotter.close()