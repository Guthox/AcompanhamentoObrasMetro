import 'dart:typed_data';

class Obras {
  final int id;
  final String nome;
  final String descricao;
  final String localizacao;
  final String responsavel;
  final String status;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final String imagem;
  final double progresso;

  final String? ifcPath;     // para Android/iOS/Desktop
  final Uint8List? ifcBytes; // para Web
  final String? ifcName;     // nome do arquivo IFC

  Obras({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.localizacao,
    required this.responsavel,
    required this.status,
    required this.dataInicio,
    required this.dataFim,
    required this.imagem,
    required this.progresso,
    this.ifcPath,
    this.ifcBytes,
    this.ifcName,
  });
}
