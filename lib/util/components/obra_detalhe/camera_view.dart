// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:obras_view/util/cameras.dart';
import 'package:obras_view/util/cores.dart';
import 'package:obras_view/util/imagens.dart';
import 'package:obras_view/util/info.dart';

class CameraView extends StatelessWidget {
  final Cameras camera;
  final double opacidadeOverlay;
  final bool mostrarAnotacoesIA;

  // Callbacks para ações
  final Function(double) onOpacidadeChanged;
  final Function(bool) onMostrarIAChanged;
  final VoidCallback onAdicionarFoto;
  final VoidCallback onExcluirCamera;

  const CameraView({
    super.key,
    required this.camera,
    required this.opacidadeOverlay,
    required this.mostrarAnotacoesIA,
    required this.onOpacidadeChanged,
    required this.onMostrarIAChanged,
    required this.onAdicionarFoto,
    required this.onExcluirCamera,
  });

  @override
  Widget build(BuildContext context) {
    final larguraTela = MediaQuery.of(context).size.width;

    // Lógica para buscar imagem real
    final imagemReal = Info.listaImagens.lastWhere(
      (img) => img.cameraId == camera.id,
      orElse: () => Imagens(localPath: '', cameraId: -1),
    );
    final temImagemReal =
        imagemReal.cameraId != -1 && imagemReal.localPath.isNotEmpty;
    final temAnotacaoIA =
        camera.renderRealAnotadoUrl != null &&
        camera.renderRealAnotadoUrl!.isNotEmpty;

    // Cálculo do Progresso
    double progresso = _calcularProgresso();
    String porcentagemTexto = (progresso * 100).toStringAsFixed(0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CABEÇALHO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            camera.nome,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Cores.azulMetro,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: onExcluirCamera,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            tooltip: "Excluir Câmera",
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(label: Text("Azimute: ${camera.anguloX}°")),
                          Chip(label: Text("Elevação: ${camera.anguloY}°")),
                          Chip(label: Text("Zoom: ${camera.zoom}x")),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: onAdicionarFoto,
                        icon: const Icon(
                          Icons.add_photo_alternate,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Adicionar Foto",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Cores.azulMetro,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ÁREA VISUAL
            LayoutBuilder(
              builder: (context, constraints) {
                double alturaImagem = constraints.maxWidth < 400
                    ? constraints.maxWidth
                    : 400;
                return Column(
                  children: [
                    Container(
                      height: alturaImagem,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (camera.renderUrl != null)
                              Image.network(
                                camera.renderUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, err, stack) => const Center(
                                  child: Icon(Icons.broken_image),
                                ),
                              )
                            else
                              const Center(child: Text("Sem render 3D")),

                            if (temImagemReal)
                              Opacity(
                                opacity: opacidadeOverlay,
                                child: Builder(
                                  builder: (context) {
                                    if (mostrarAnotacoesIA && temAnotacaoIA) {
                                      return Image.network(
                                        camera.renderRealAnotadoUrl!,
                                        fit: BoxFit.contain,
                                        loadingBuilder: (ctx, child, p) =>
                                            p == null
                                            ? child
                                            : const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                      );
                                    }
                                    if (kIsWeb) {
                                      return Image.network(
                                        imagemReal.localPath,
                                        fit: BoxFit.contain,
                                      );
                                    }
                                    return Image.file(
                                      File(imagemReal.localPath),
                                      fit: BoxFit.contain,
                                    );
                                  },
                                ),
                              ),

                            if (!temImagemReal)
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "Adicione foto real",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // CONTROLES
                    if (temImagemReal)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Render",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: opacidadeOverlay,
                                    min: 0.0,
                                    max: 1.0,
                                    activeColor: Cores.azulMetro,
                                    inactiveColor: Colors.grey[300],
                                    onChanged: onOpacidadeChanged,
                                  ),
                                ),
                                const Text(
                                  "Foto Real",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Cores.azulMetro,
                                  ),
                                ),
                              ],
                            ),
                            if (temAnotacaoIA)
                              Container(
                                margin: const EdgeInsets.only(top: 5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Cores.azulMetro.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Cores.azulMetro.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          size: 18,
                                          color: Cores.azulMetro,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Máscaras IA",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      value: mostrarAnotacoesIA,
                                      activeColor: Cores.azulMetro,
                                      onChanged: onMostrarIAChanged,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            // BARRA DE PROGRESSO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Progresso",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "$porcentagemTexto%",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: progresso == 1.0 ? Colors.green : Cores.azulMetro,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progresso,
                minHeight: 15,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progresso == 1.0 ? Colors.green : Cores.azulMetro,
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "Componentes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // GRID DE ESTATÍSTICAS
            if (camera.estatisticas != null && camera.estatisticas!.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: larguraTela > 860
                      ? 4
                      : larguraTela > 680
                      ? 3
                      : larguraTela > 350
                      ? 2
                      : 1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 80,
                ),
                itemCount: camera.estatisticas!.length,
                itemBuilder: (context, index) {
                  final entry = camera.estatisticas!.entries.elementAt(index);
                  int real = 0;
                  if (camera.estatisticasReal != null &&
                      camera.estatisticasReal!.containsKey(entry.key)) {
                    real = camera.estatisticasReal![entry.key];
                  }
                  int esperado = entry.value;
                  bool completo = real >= esperado;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: completo
                            ? Colors.green.withOpacity(0.5)
                            : Cores.azulMetro.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          completo ? Icons.check_circle : Icons.pending,
                          size: 28,
                          color: completo ? Colors.green : Cores.azulMetro,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "$esperado",
                                      style: TextStyle(
                                        color: completo
                                            ? Colors.green
                                            : Cores.azulMetro,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: " / ",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextSpan(
                                      text: real > esperado
                                          ? "$esperado"
                                          : "$real",
                                      style: TextStyle(
                                        color: completo
                                            ? Colors.green
                                            : Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Sem dados."),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  double _calcularProgresso() {
    if (camera.estatisticas == null || camera.estatisticas!.isEmpty) return 0.0;
    if (camera.estatisticasReal == null) return 0.0;

    int totalEsperado = 0;
    int totalReal = 0;

    camera.estatisticas!.forEach((key, value) {
      int esperadoItem = value as int;
      totalEsperado += esperadoItem;

      if (camera.estatisticasReal!.containsKey(key)) {
        int realItem = camera.estatisticasReal![key] as int;
        
        // --- CORREÇÃO AQUI ---
        // Se o real for maior que o esperado (alucinação), consideramos apenas o esperado.
        // Isso impede que o "excesso" de um item cubra a falta de outro.
        if (realItem > esperadoItem) {
          totalReal += esperadoItem;
        } else {
          totalReal += realItem;
        }
      }
    });

    if (totalEsperado == 0) return 0.0;
    
    double progresso = totalReal / totalEsperado;
    // Ajuste para mitigar alucinação da IA
    if (progresso < 0.5) {
      return progresso;
    } else if (progresso < 0.8) {
      return progresso + 0.1;
    } else if (progresso < 0.95) {
      return progresso + 0.05;
    }
    return progresso > 1.0 ? 1.0 : progresso;
  }
}