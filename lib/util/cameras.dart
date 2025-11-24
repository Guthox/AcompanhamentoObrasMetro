class Cameras {
  final double anguloX;
  final double anguloY;
  final double zoom;
  final int obraId;
  final String nome;
  final String? renderUrl;

  Cameras({
    required this.anguloX,
    required this.anguloY,
    required this.zoom,
    required this.obraId,
    required this.nome,
    this.renderUrl,
  });
}