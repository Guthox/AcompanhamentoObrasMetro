class Obras {

  final int id;
  final String nome;
  final String descricao;
  final String localizacao;
  final String status;        // "Em andamento", "Concluída", "Parada"
  final DateTime dataInicio;
  final DateTime? dataFim;
  final String responsavel;   // Engenheiro ou empresa
  final String imagem;        // Caminho para imagem local ou URL
  final double progresso;     // Percentual (0.0 a 1.0)

  Obras({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.localizacao,
    required this.status,
    required this.dataInicio,
    this.dataFim,
    required this.responsavel,
    required this.imagem,
    this.progresso = 0.0,
  });
}
