library delta_markdown;

import 'dart:convert';

import 'package:appflowy_editor/src/core/document/document.dart';
import 'package:appflowy_editor/src/plugins/html/html_document_decoder.dart';
import 'package:appflowy_editor/src/plugins/html/html_document_encoder.dart';

import 'encoder/parser/audio_node_parser.dart';
import 'encoder/parser/html_parser.dart';
import 'encoder/parser/video_node_parser.dart';

/// Converts a html to [Document].
Document htmlToDocument(String html) {
  return const AppFlowyEditorHTMLCodec().decode(html);
}

/// Converts a [Document] to html.
String documentToHTML(
  Document document, {
  List<HTMLNodeParser> customParsers = const [],
}) {
  return AppFlowyEditorHTMLCodec(
    encodeParsers: [
      ...customParsers,
      const HTMLTextNodeParser(),
      const HTMLBulletedListNodeParser(),
      const HTMLNumberedListNodeParser(),
      const HTMLTodoListNodeParser(),
      const HTMLQuoteNodeParser(),
      const HTMLHeadingNodeParser(),
      const HTMLImageNodeParser(),
      const HTMLAudioNodeParser(),
      const HTMLVideoNodeParser(),
    ],
  ).encode(document);
}

class AppFlowyEditorHTMLCodec extends Codec<Document, String> {
  const AppFlowyEditorHTMLCodec({
    this.encodeParsers = const [],
  });

  final List<HTMLNodeParser> encodeParsers;

  @override
  Converter<String, Document> get decoder => DocumentHTMLDecoder();

  @override
  Converter<Document, String> get encoder =>
      DocumentHTMLEncoder(encodeParsers: encodeParsers);
}
