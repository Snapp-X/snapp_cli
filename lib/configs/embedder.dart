/// Flutter embedders which we are supporting in snapp_cli
enum FlutterEmbedder {
  /// Flutter official embedder for Linux
  flutter('Flutter Linux', 'Flutter Linux Official'),

  /// Flutter-pi embedder: [https://github.com/ardera/flutter-pi]
  flutterPi('Flutter-pi', 'Flutter-pi Embedder');

  const FlutterEmbedder(this.label, this.sdkName);

  final String label;
  final String sdkName;
}
