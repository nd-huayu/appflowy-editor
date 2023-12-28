import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:html/dom.dart' as dom;

class HTMLVideoNodeParser extends HTMLNodeParser {
  const HTMLVideoNodeParser();

  @override
  String get id => VideoBlockKeys.type;

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
    final anchor = dom.Element.tag(HTMLTags.video);
    anchor.attributes[VideoBlockKeys.url] = node.attributes[VideoBlockKeys.url];

    final height = node.attributes[VideoBlockKeys.height];
    if (height != null) {
      anchor.attributes[VideoBlockKeys.height] = height;
    }

    final width = node.attributes[VideoBlockKeys.width];
    if (width != null) {
      anchor.attributes[VideoBlockKeys.width] = width;
    }

    final autoPlay = node.attributes[VideoBlockKeys.autoPlay];
    if (autoPlay != null) {
      anchor.attributes[VideoBlockKeys.autoPlay] = autoPlay.toString();
    }

    final isLoop = node.attributes[VideoBlockKeys.isLoop];
    if (isLoop != null) {
      anchor.attributes[VideoBlockKeys.isLoop] = isLoop.toString();
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
