import 'package:flutter/material.dart';

const String notoFontFamily = "Noto Sans SC";
const String initialFontFamily = "Blackboard Common";
const List<String> defaultFontFamilyFallback = [
  notoFontFamily,
  initialFontFamily,
];

/// only for the common config of text style
class TextStyleConfiguration {
  const TextStyleConfiguration({
    this.text = const TextStyle(fontSize: 16.0),
    this.bold = const TextStyle(fontWeight: FontWeight.bold),
    this.italic = const TextStyle(fontStyle: FontStyle.italic),
    this.underline = const TextStyle(
      decoration: TextDecoration.underline,
    ),
    this.strikethrough = const TextStyle(
      decoration: TextDecoration.lineThrough,
    ),
    this.href = const TextStyle(
      color: Colors.lightBlue,
      decoration: TextDecoration.underline,
    ),
    this.code = const TextStyle(
      color: Colors.red,
      backgroundColor: Color.fromARGB(98, 0, 195, 255),
    ),
    this.fontSize = const TextStyle(fontSize: 16.0),
    this.fontFamily = const TextStyle(
      fontFamily: notoFontFamily,
      fontFamilyFallback: defaultFontFamilyFallback,
    ),
  });

  /// default text style
  final TextStyle text;

  /// bold text style
  final TextStyle bold;

  /// italic text style
  final TextStyle italic;

  /// underline text style
  final TextStyle underline;

  /// strikethrough text style
  final TextStyle strikethrough;

  /// href text style
  final TextStyle href;

  /// code text style
  final TextStyle code;

  /// fontSize text style
  final TextStyle fontSize;

  /// fontFamily text style
  final TextStyle fontFamily;

  TextStyleConfiguration copyWith({
    TextStyle? text,
    TextStyle? bold,
    TextStyle? italic,
    TextStyle? underline,
    TextStyle? strikethrough,
    TextStyle? href,
    TextStyle? code,
    TextStyle? fontSize,
    TextStyle? fontFamily,
  }) {
    return TextStyleConfiguration(
      text: text ?? this.text,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      href: href ?? this.href,
      code: code ?? this.code,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}
