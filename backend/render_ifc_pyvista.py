import ifcopenshell
import ifcopenshell.geom
import pyvista as pv
import numpy as np
import os
import sys
import argparse

# Configuração de Argumentos
parser = argparse.ArgumentParser(description='Renderizar IFC com PyVista')
parser.add_argument('--ifc', required=True, help='Caminho do arquivo IFC')
parser.add_argument('--output', required=True, help='Caminho de saída da imagem PNG')
parser.add_argument('--azimuth', type=float, default=45, help='Ângulo X (Azimute)')
parser.add_argument('--elevation', type=float, default=30, help='Ângulo Y (Elevação)')
parser.add_argument('--distance', type=float, default=10, help='Distância da câmera (Zoom level)')

args = parser.parse_args()

IFC_FILE = args.ifc
OUTPUT_IMAGE = args.output

if not os.path.isfile(IFC_FILE):
    print(f"Erro: Arquivo IFC não encontrado: {IFC_FILE}")
    sys.exit(1)

# --- Iniciar PyVista ---
try:
    plotter = pv.Plotter(off_screen=True, window_size=[1024, 768])
except Exception as e:
    print(f"Erro ao iniciar PyVista: {e}")
    sys.exit(1)

# --- Ler IFC e Adicionar Malhas ---
try:
    ifc_file = ifcopenshell.open(IFC_FILE)
    settings = ifcopenshell.geom.settings()
    settings.set(settings.USE_WORLD_COORDS, True)
    
    products = ifc_file.by_type('IfcProduct')
    
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
        except:
            pass

    # --- Configurar Câmera com Parâmetros ---
    plotter.enable_parallel_projection() # Ou perspectiva, dependendo do gosto
    plotter.view_isometric()
    
    # Aplica os ângulos recebidos do Flutter
    plotter.camera.azimuth = args.azimuth
    plotter.camera.elevation = args.elevation
    
    # O Zoom no PyVista funciona melhor para "distância" em projeção paralela
    # Se a distância for pequena, o zoom é maior. Ajuste essa lógica conforme sua escala.
    zoom_factor = 10.0 / (args.distance if args.distance > 0 else 1) 
    plotter.camera.Zoom(zoom_factor)

    # Renderizar e Salvar
    plotter.screenshot(OUTPUT_IMAGE)
    print(f"Sucesso: {OUTPUT_IMAGE}")

except Exception as e:
    print(f"Erro geral: {e}")
    sys.exit(1)
finally:
    plotter.close()