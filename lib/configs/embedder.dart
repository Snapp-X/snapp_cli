/// Flutter embedders which we are supporting in snapp_cli
enum FlutterEmbedder {
  /// Flutter official embedder for Linux
  flutter('Flutter Linux', 'Flutter Linux Official', 'flutter'),

  /// Flutter-pi embedder: [https://github.com/ardera/flutter-pi]
  flutterPi('Flutter-pi', 'Flutter-pi Embedder', 'flutter-pi'),

  iviHomescreen('ivi-homescreen', 'Toyota ivi-homescreen', 'homescreen');

  const FlutterEmbedder(
    this.label,
    this.sdkName,
    this.executableName,
  );

  final String label;
  final String sdkName;
  final String executableName;
}
