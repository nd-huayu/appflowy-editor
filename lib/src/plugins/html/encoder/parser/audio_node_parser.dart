import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:html/dom.dart' as dom;

class HTMLAudioNodeParser extends HTMLNodeParser {
  const HTMLAudioNodeParser();

  @override
  String get id => AudioBlockKeys.type;

  @override
  String transformNodeToHTMLString(
    Node node, {
    required List<HTMLNodeParser> encodeParsers,
  }) {
    return toHTMLString(
      transformNodeToDomNodes(node, encodeParsers: encodeParsers),
    );
  }

  @override
  List<dom.Node> transformNodeToDomNodes(
    Node node, {
    required List<HTMLNodeParser> encodeParsers,
  }) {
    final anchor = dom.Element.tag(HTMLTags.audio);
    anchor.attributes[AudioBlockKeys.url] = node.attributes[AudioBlockKeys.url];

    final height = node.attributes[AudioBlockKeys.height];
    if (height != null) {
      anchor.attributes[AudioBlockKeys.height] = height;
    }

    final width = node.attributes[AudioBlockKeys.width];
    if (width != null) {
      anchor.attributes[AudioBlockKeys.width] = width;
    }

    final autoPlay = node.attributes[AudioBlockKeys.autoPlay];
    if (autoPlay != null) {
      anchor.attributes[AudioBlockKeys.autoPlay] = autoPlay.toString();
    }

    final isLoop = node.attributes[AudioBlockKeys.isLoop];
    if (isLoop != null) {
      anchor.attributes[AudioBlockKeys.isLoop] = isLoop.toString();
    }

    return [
      anchor,
      ...processChildrenNodes(
        node.children.toList(),
        encodeParsers: encodeParsers,
      ),
    ];
  }
}
