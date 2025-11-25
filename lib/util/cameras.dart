class Cameras {
  final int id;
  final double anguloX;
  final double anguloY;
  final double zoom;
  final int obraId;
  final String nome;
  final String? renderUrl;
  final String? renderRealAnotadoUrl;
  final Map<String, dynamic>? estatisticas;
  final Map<String, dynamic>? estatisticasReal;

  Cameras({
    required this.id,
    required this.anguloX,
    required this.anguloY,
    required this.zoom,
    required this.obraId,
    required this.nome,
    this.renderUrl,
    this.renderRealAnotadoUrl,
    this.estatisticas,
    this.estatisticasReal,
  });
}