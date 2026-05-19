class GuiaSlide {
  final String emoji;
  final String titulo;
  final String texto;
  final String? botonFinal; // solo en el último slide

  const GuiaSlide({
    required this.emoji,
    required this.titulo,
    required this.texto,
    this.botonFinal,
  });
}
