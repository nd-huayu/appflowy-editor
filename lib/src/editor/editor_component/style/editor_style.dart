import 'package:appflowy_editor/appflowy_editor.dart';

import 'package:flutter/material.dart';

/// The style of the editor.
///
/// You can customize the style of the editor by passing the [EditorStyle] to
///  the [AppFlowyEditor].
///
class EditorStyle {
  const EditorStyle({
    required this.padding,
    required this.cursorColor,
    required this.selectionColor,
    required this.textStyleConfiguration,
    required this.textSpanDecorator,
    this.defaultTextDirection,
    this.customData,
  });

  /// fyl:自定义的数据，如“分页线”相关数据
  final CustomStyleData? customData;

  /// The padding of the editor.
  final EdgeInsets padding;

  /// The cursor color
  final Color cursorColor;

  /// The selection color
  final Color selectionColor;

  /// Customize the text style of the editor.
  ///
  /// All the text-based components will use this configuration to build their
  ///   text style.
  ///
  /// Notes, this configuration is only for the common config of text style and
  ///   it maybe override if the text block has its own [BlockComponentConfiguration].
  final TextStyleConfiguration textStyleConfiguration;

  /// Customize the built-in or custom text span.
  ///
  /// For example, you can add a custom text span for the mention text
  ///   or override the built-in text span.
  final TextSpanDecoratorForAttribute? textSpanDecorator;

  final String? defaultTextDirection;

  const EditorStyle.desktop({
    EdgeInsets? padding,
    Color? backgroundColor,
    Color? cursorColor,
    Color? selectionColor,
    TextStyleConfiguration? textStyleConfiguration,
    TextSpanDecoratorForAttribute? textSpanDecorator,
    this.defaultTextDirection,
    CustomStyleData? customDataParam,
  })  : padding = padding ?? const EdgeInsets.symmetric(horizontal: 100),
        cursorColor = cursorColor ?? const Color(0xFF00BCF0),
        selectionColor =
            selectionColor ?? const Color.fromARGB(53, 111, 201, 231),
        textStyleConfiguration = textStyleConfiguration ??
            const TextStyleConfiguration(
              text: TextStyle(fontSize: 16, color: Colors.black),
            ),
        textSpanDecorator =
            textSpanDecorator ?? defaultTextSpanDecoratorForAttribute,
        customData = customDataParam;

  const EditorStyle.mobile({
    EdgeInsets? padding,
    Color? backgroundColor,
    Color? cursorColor,
    Color? selectionColor,
    TextStyleConfiguration? textStyleConfiguration,
    TextSpanDecoratorForAttribute? textSpanDecorator,
    this.defaultTextDirection,
    CustomStyleData? customDataParam,
  })  : padding = padding ?? const EdgeInsets.symmetric(horizontal: 20),
        cursorColor = cursorColor ?? const Color(0xFF00BCF0),
        selectionColor =
            selectionColor ?? const Color.fromARGB(53, 111, 201, 231),
        textStyleConfiguration = textStyleConfiguration ??
            const TextStyleConfiguration(
              text: TextStyle(fontSize: 16, color: Colors.black),
            ),
        textSpanDecorator =
            textSpanDecorator ?? mobileTextSpanDecoratorForAttribute,
        customData = customDataParam;

  EditorStyle copyWith({
    EdgeInsets? padding,
    Color? backgroundColor,
    Color? cursorColor,
    Color? selectionColor,
    TextStyleConfiguration? textStyleConfiguration,
    TextSpanDecoratorForAttribute? textSpanDecorator,
    String? defaultTextDirection,
    CustomStyleData? customData,
  }) {
    return EditorStyle(
      padding: padding ?? this.padding,
      cursorColor: cursorColor ?? this.cursorColor,
      selectionColor: selectionColor ?? this.selectionColor,
      textStyleConfiguration:
          textStyleConfiguration ?? this.textStyleConfiguration,
      textSpanDecorator: textSpanDecorator ?? this.textSpanDecorator,
      defaultTextDirection: defaultTextDirection,
      customData: customData ?? this.customData,
    );
  }
}
