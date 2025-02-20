import 'dart:math';
import 'dart:ui';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/core/document/attributes.dart';
import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/path.dart';
import 'package:appflowy_editor/src/core/document/text_delta.dart';
import 'package:appflowy_editor/src/core/location/position.dart';
import 'package:appflowy_editor/src/core/location/selection.dart';
import 'package:appflowy_editor/src/editor/block_component/base_component/selection/block_selection_container.dart';
import 'package:appflowy_editor/src/editor/block_component/rich_text/appflowy_rich_text_keys.dart';
import 'package:appflowy_editor/src/editor/util/color_util.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/extensions/text_style_extension.dart';
import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tuple/tuple.dart';

typedef TextSpanDecoratorForAttribute = InlineSpan Function(
  BuildContext context,
  Node node,
  int index,
  TextInsert text,
  TextSpan textSpan,
);

typedef AppFlowyTextSpanDecorator = TextSpan Function(TextSpan textSpan);

class AppFlowyRichText extends StatefulWidget {
  const AppFlowyRichText({
    super.key,
    this.cursorHeight,
    this.cursorWidth = 2.0,
    this.lineHeight,
    this.textSpanDecorator,
    this.placeholderText = ' ',
    this.placeholderTextSpanDecorator,
    this.textDirection = TextDirection.ltr,
    this.textSpanDecoratorForCustomAttributes,
    required this.textAlign,
    this.cursorColor = const Color.fromARGB(255, 0, 0, 0),
    this.selectionColor = const Color.fromARGB(53, 111, 201, 231),
    required this.delegate,
    required this.node,
    required this.editorState,
  });

  /// The node of the rich text.
  final Node node;

  /// The editor state.
  final EditorState editorState;

  /// The height of the cursor.
  ///
  /// If this is null, the height of the cursor will be calculated automatically.
  final double? cursorHeight;

  /// The width of the cursor.
  final double cursorWidth;

  /// The height of each line.
  final double? lineHeight;

  /// customize the text span for rich text
  final AppFlowyTextSpanDecorator? textSpanDecorator;

  /// The placeholder text when the rich text is empty.
  final String placeholderText;

  /// customize the text span for placeholder text
  final AppFlowyTextSpanDecorator? placeholderTextSpanDecorator;

  // get the cursor rect, selection rects or block rect from the delegate
  final SelectableMixin delegate;

  /// customize the text span for custom attributes
  ///
  /// You can use this to customize the text span for custom attributes
  ///   or override the existing one.
  final TextSpanDecoratorForAttribute? textSpanDecoratorForCustomAttributes;
  final TextDirection textDirection;

  /// TextAlign
  final TextAlign textAlign;

  final Color cursorColor;
  final Color selectionColor;

  @override
  State<AppFlowyRichText> createState() => _AppFlowyRichTextState();
}

class _AppFlowyRichTextState extends State<AppFlowyRichText>
    with SelectableMixin {
  final textKey = GlobalKey();
  final placeholderTextKey = GlobalKey();

  RenderParagraph? get _renderParagraph =>
      textKey.currentContext?.findRenderObject() as RenderParagraph?;

  RenderParagraph? get _placeholderRenderParagraph =>
      placeholderTextKey.currentContext?.findRenderObject() as RenderParagraph?;

  TextSpanDecoratorForAttribute? get textSpanDecoratorForAttribute =>
      widget.textSpanDecoratorForCustomAttributes ??
      widget.editorState.editorStyle.textSpanDecorator;

  double? _lineHeight;

  @override
  void initState() {
    if (widget.lineHeight != null) {
      _lineHeight = widget.lineHeight;
    } else {
      if (widget.node.attributes.containsKey(blockComponentTextHeight)) {
        _lineHeight = double.parse(
          widget.node.attributes[blockComponentTextHeight].toString(),
        );
      } else {
        _lineHeight = 1.5;
      }
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AppFlowyRichText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lineHeight != null) {
      _lineHeight = widget.lineHeight;
    } else {
      if (widget.node.attributes.containsKey(blockComponentTextHeight)) {
        _lineHeight = double.parse(
          widget.node.attributes[blockComponentTextHeight].toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = MouseRegion(
      cursor: SystemMouseCursors.text,
      child: isCoverAll && (widget.node.delta?.toPlainText().isEmpty ?? true)
          ? Stack(
              children: [
                _buildPlaceholderText(context),
                _buildRichText(context),
              ],
            )
          : _buildRichText(context),
    );

    return BlockSelectionContainer(
      delegate: widget.delegate,
      listenable: widget.editorState.selectionNotifier,
      node: widget.node,
      cursorColor: widget.cursorColor,
      selectionColor: widget.selectionColor,
      child: child,
    );
  }

  @override
  Position start() => Position(path: widget.node.path, offset: 0);

  @override
  Position end() => Position(
        path: widget.node.path,
        offset: widget.node.delta?.toPlainText().length ?? 0,
      );

  @override
  Rect getBlockRect({
    bool shiftWithBaseOffset = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Rect? getCursorRectInPosition(
    Position position, {
    bool shiftWithBaseOffset = false,
  }) {
    final textPosition = TextPosition(offset: position.offset);
    var cursorHeight = _renderParagraph?.getFullHeightForCaret(textPosition);
    var cursorOffset =
        _renderParagraph?.getOffsetForCaret(textPosition, Rect.zero) ??
            Offset.zero;
    if (cursorHeight == null) {
      cursorHeight =
          _placeholderRenderParagraph?.getFullHeightForCaret(textPosition);
      cursorOffset = _placeholderRenderParagraph?.getOffsetForCaret(
            textPosition,
            Rect.zero,
          ) ??
          Offset.zero;
      if (textDirection() == TextDirection.rtl) {
        if (widget.placeholderText.trim().isNotEmpty) {
          cursorOffset = cursorOffset.translate(
            _placeholderRenderParagraph?.size.width ?? 0,
            0,
          );
        }
      }
    }
    if (widget.cursorHeight != null && cursorHeight != null) {
      cursorOffset = Offset(
        cursorOffset.dx,
        cursorOffset.dy + (cursorHeight - widget.cursorHeight!) / 2,
      );
      cursorHeight = widget.cursorHeight;
    }
    final rect = Rect.fromLTWH(
      max(0, cursorOffset.dx - (widget.cursorWidth / 2.0)),
      cursorOffset.dy,
      widget.cursorWidth,
      cursorHeight ?? 16.0 * 1.5,
    );
    return rect;
  }

  @override
  Position getPositionInOffset(Offset start) {
    final offset = _renderParagraph?.globalToLocal(start) ?? Offset.zero;
    final baseOffset =
        _renderParagraph?.getPositionForOffset(offset).offset ?? -1;
    return Position(path: widget.node.path, offset: baseOffset);
  }

  @override
  Selection? getWordBoundaryInOffset(Offset offset) {
    final localOffset = _renderParagraph?.globalToLocal(offset) ?? Offset.zero;
    final textPosition = _renderParagraph?.getPositionForOffset(localOffset) ??
        const TextPosition(offset: 0);
    final textRange =
        _renderParagraph?.getWordBoundary(textPosition) ?? TextRange.empty;
    final start = Position(path: widget.node.path, offset: textRange.start);
    final end = Position(path: widget.node.path, offset: textRange.end);
    return Selection(start: start, end: end);
  }

  @override
  Selection? getWordBoundaryInPosition(Position position) {
    final textPosition = TextPosition(offset: position.offset);
    final textRange =
        _renderParagraph?.getWordBoundary(textPosition) ?? TextRange.empty;
    final start = Position(path: widget.node.path, offset: textRange.start);
    final end = Position(path: widget.node.path, offset: textRange.end);
    return Selection(start: start, end: end);
  }

  @override
  List<Rect> getRectsInSelection(
    Selection selection, {
    bool shiftWithBaseOffset = false,
  }) {
    final textSelection = textSelectionFromEditorSelection(selection);
    if (textSelection == null) {
      return [];
    }
    final rects = _renderParagraph
        ?.getBoxesForSelection(
          textSelection,
          boxHeightStyle: BoxHeightStyle.max,
        )
        .map((box) => box.toRect())
        .toList(growable: false);

    if (rects == null || rects.isEmpty) {
      // If the rich text widget does not contain any text,
      // there will be no selection boxes,
      // so we need to return to the default selection.
      return [Rect.fromLTWH(0, 0, 0, _renderParagraph?.size.height ?? 0)];
    }
    return rects;
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) {
    final localStart = _renderParagraph?.globalToLocal(start) ?? Offset.zero;
    final localEnd = _renderParagraph?.globalToLocal(end) ?? Offset.zero;
    final baseOffset =
        _renderParagraph?.getPositionForOffset(localStart).offset ?? -1;
    final extentOffset =
        _renderParagraph?.getPositionForOffset(localEnd).offset ?? -1;
    return Selection.single(
      path: widget.node.path,
      startOffset: baseOffset,
      endOffset: extentOffset,
    );
  }

  @override
  Offset localToGlobal(
    Offset offset, {
    bool shiftWithBaseOffset = false,
  }) {
    return _renderParagraph?.localToGlobal(offset) ?? Offset.zero;
  }

  @override
  TextDirection textDirection() {
    return widget.textDirection;
  }

  Widget _buildPlaceholderText(BuildContext context) {
    final textSpan = getPlaceholderTextSpan();
    return RichText(
      key: placeholderTextKey,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: true,
        applyHeightToLastDescent: true,
      ),
      text: widget.placeholderTextSpanDecorator != null
          ? widget.placeholderTextSpanDecorator!(textSpan)
          : textSpan,
      textDirection: textDirection(),
      textAlign: widget.textAlign,
    );
  }

  Widget _buildRichText(BuildContext context) {
    final textSpan = getTextSpan();
    Tuple2 tuple2 = widget.editorState.getCurNodeMaxFontSize(widget.node);
    return RichText(
      key: textKey,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: true,
        applyHeightToLastDescent: true,
      ),
      text: widget.textSpanDecorator != null
          ? widget.textSpanDecorator!(textSpan)
          : textSpan,
      textDirection: textDirection(),
      textAlign: widget.textAlign,
      strutStyle: StrutStyle.fromTextStyle(
        textSpan.style!.copyWith(fontSize: tuple2.item2),
      ),
    );
  }

  TextSpan getPlaceholderTextSpan() {
    final style = widget.editorState.editorStyle.textStyleConfiguration;
    return TextSpan(
      children: [
        TextSpan(
          text: widget.placeholderText,
          style: style.text.copyWith(height: _lineHeight),
        ),
      ],
    );
  }

  TextSpan getTextSpan() {
    int offset = 0;
    List<InlineSpan> textSpans = [];
    final style = widget.editorState.editorStyle.textStyleConfiguration;
    final textInserts = widget.node.delta!.whereType<TextInsert>();
    for (final textInsert in textInserts) {
      TextStyle textStyle = style.text.copyWith(height: _lineHeight);
      final attributes = textInsert.attributes;

      /// 上下标
      bool isSuperScript = false;
      bool isSubScript = false;
      if (attributes != null) {
        if (attributes.bold == true) {
          textStyle = textStyle.combine(style.bold);
        }
        if (attributes.italic == true) {
          textStyle = textStyle.combine(style.italic);
        }
        if (attributes.underline == true) {
          textStyle = textStyle.combine(style.underline);
        }
        if (attributes.strikethrough == true) {
          textStyle = textStyle.combine(style.strikethrough);
        }
        if (attributes.href != null) {
          textStyle = textStyle.combine(style.href);
        }
        if (attributes.code == true) {
          textStyle = textStyle.combine(style.code);
        }
        if (attributes.backgroundColor != null) {
          textStyle = textStyle.combine(
            TextStyle(backgroundColor: attributes.backgroundColor),
          );
        }
        if (attributes.findBackgroundColor != null) {
          textStyle = textStyle.combine(
            TextStyle(backgroundColor: attributes.findBackgroundColor),
          );
        }
        if (attributes.color != null) {
          textStyle = textStyle.combine(
            TextStyle(color: attributes.color),
          );
        }

        /// fontSize by 533335
        if (attributes.fontSize != null) {
          textStyle = textStyle.combine(
            TextStyle(fontSize: attributes.fontSize),
          );
        }

        /// fontFamily by 533335
        if (attributes.fontFamily != null) {
          if (kIsWeb || PlatformExtension.isMobile) {
            List<String> listFamily = [];
            if (widget.editorState.onSupportDisplayFamily != null) {
              listFamily = widget.editorState.onSupportDisplayFamily!(
                attributes.fontFamily,
                textInsert.text,
                widget.node,
              );
            }

            if (listFamily.isEmpty) {
              listFamily.addAll(defaultFontFamilyFallback);
            }
            textStyle = textStyle.combine(
              TextStyle(
                fontFamily: listFamily.last,
                fontFamilyFallback: listFamily + defaultFontFamilyFallback,
              ),
            );
          } else {
            textStyle = textStyle.combine(
              TextStyle(
                fontFamily: attributes.fontFamily,
                fontFamilyFallback: defaultFontFamilyFallback,
              ),
            );
          }
        } else {
          textStyle = textStyle.combine(
            TextStyle(
              fontFamily: defaultFontFamilyFallback.last,
              fontFamilyFallback: defaultFontFamilyFallback,
            ),
          );
        }

        /// 上下标
        isSuperScript = attributes.superScript;
        isSubScript = attributes.subScript;
      } else {
        textStyle = textStyle.combine(
          TextStyle(
            fontFamily: defaultFontFamilyFallback.last,
            fontFamilyFallback: defaultFontFamilyFallback,
          ),
        );
      }
      if (isSuperScript || isSubScript) {
        double fontSize = textStyle.fontSize ?? 16.0;
        double offset = isSuperScript ? (fontSize / 3 * -1) : fontSize / 3;
        textStyle = textStyle.combine(
          TextStyle(
            fontSize: max(3, fontSize / 1.5),
          ),
        );

        textInsert.text.split("").forEach((text) {
          _addSuperScriptText(
            textSpans,
            offset,
            text,
            textStyle,
            attributes?.underline == true,
            attributes?.strikethrough == true,
          );
        });
      } else {
        if(textInsert.text.contains('\t')){
          var tabs = _splitStringWithTabs(textInsert.text);
          var list = tabs.map((e) => e == '\t' ? WidgetSpan(
            child: Container(
              width: (textStyle.fontSize ?? 16) * 2,
              height: 1,
              color: Colors.transparent,
            ),
          ) : TextSpan(
            text: e,
            style: textStyle,
          )).toList();
          for (var element in list) {
            textSpans.add(element);
          }
        } else {
          textSpans.add(
            TextSpan(
              text: textInsert.text,
              style: textStyle,
            ),
          );
        }
      }
      // textSpans.add(
      //   textSpanDecoratorForAttribute != null
      //       ? textSpanDecoratorForAttribute!(
      //           context,
      //           widget.node,
      //           offset,
      //           textInsert,
      //           textSpan,
      //         )
      //       : textSpan,
      // );
      offset += textInsert.length;
    }
    return TextSpan(
      children: textSpans,
      style: TextStyle(height: _lineHeight),
    );
  }

  List<String> _splitStringWithTabs(String input) {
    RegExp exp = RegExp(r'(\\t|.)');
    Iterable<RegExpMatch> matches = exp.allMatches(input);
    List<String> result = matches.map((match) => match.group(0)!).toList();
    return result;
  }

  Size _measureCharacterWidth(String character, TextStyle textStyle) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: character, style: textStyle),
      textDirection: TextDirection.ltr,
      textScaleFactor: WidgetsBinding.instance.window.textScaleFactor,
    )..layout();

    return textPainter.size;
  }

  /// 多个上下标文本拆分成单个加入到textSpans中
  void _addSuperScriptText(
    List<InlineSpan> textSpans,
    double offsetY,
    String text,
    TextStyle textStyle,
    bool isUnderLine,
    bool isStrikethrough,
  ) {
    double curFontSize = textStyle.fontSize ?? 16;
    textSpans.add(WidgetSpan(
      baseline: TextBaseline.ideographic,
      alignment: PlaceholderAlignment.aboveBaseline,
      child: Transform.translate(
        offset: Offset(0, offsetY),
        child: Stack(
          children: [
            Text(
              text,
              style: textStyle.copyWith(decoration: TextDecoration.none),
            ),

            // 下划线和删除上下标时样式有问题，需要加上
            if (isUnderLine)
              Positioned(
                bottom: curFontSize * 0.2,
                child: Container(
                  height: 1,
                  width: curFontSize * 1.1,
                  color: textStyle.color,
                ),
              ),
            if (isStrikethrough)
              Positioned(
                bottom: curFontSize * 0.8,
                child: Container(
                  height: 1,
                  width: curFontSize * 1.1,
                  color: textStyle.color,
                ),
              )
          ],
        ),
      ),
    ));
  }

  TextSelection? textSelectionFromEditorSelection(Selection? selection) {
    if (selection == null) {
      return null;
    }

    final normalized = selection.normalized;
    final path = widget.node.path;
    if (path < normalized.start.path || path > normalized.end.path) {
      return null;
    }

    final length = widget.node.delta?.length;
    if (length == null) {
      return null;
    }

    TextSelection? textSelection;

    if (normalized.isSingle) {
      if (path.equals(normalized.start.path)) {
        if (normalized.isCollapsed) {
          textSelection = TextSelection.collapsed(
            offset: normalized.startIndex,
          );
        } else {
          textSelection = TextSelection(
            baseOffset: normalized.startIndex,
            extentOffset: normalized.endIndex,
          );
        }
      }
    } else {
      if (path.equals(normalized.start.path)) {
        textSelection = TextSelection(
          baseOffset: normalized.startIndex,
          extentOffset: length,
        );
      } else if (path.equals(normalized.end.path)) {
        textSelection = TextSelection(
          baseOffset: 0,
          extentOffset: normalized.endIndex,
        );
      } else {
        textSelection = TextSelection(
          baseOffset: 0,
          extentOffset: length,
        );
      }
    }
    return textSelection;
  }
}

extension AppFlowyRichTextAttributes on Attributes {
  bool get bold => this[AppFlowyRichTextKeys.bold] == true;

  bool get italic => this[AppFlowyRichTextKeys.italic] == true;

  bool get underline => this[AppFlowyRichTextKeys.underline] == true;

  bool get code => this[AppFlowyRichTextKeys.code] == true;

  bool get strikethrough {
    return (containsKey(AppFlowyRichTextKeys.strikethrough) &&
        this[AppFlowyRichTextKeys.strikethrough] == true);
  }

  Color? get color {
    final textColor = this[AppFlowyRichTextKeys.textColor] as String?;
    return textColor?.tryToColor();
  }

  Color? get backgroundColor {
    final highlightColor = this[AppFlowyRichTextKeys.highlightColor] as String?;
    return highlightColor?.tryToColor();
  }

  Color? get findBackgroundColor {
    final findBackgroundColor =
        this[AppFlowyRichTextKeys.findBackgroundColor] as String?;
    return findBackgroundColor?.tryToColor();
  }

  String? get href {
    if (this[AppFlowyRichTextKeys.href] is String) {
      return this[AppFlowyRichTextKeys.href];
    }
    return null;
  }

  String? get fontFamily {
    if (this[AppFlowyRichTextKeys.fontFamily] is String) {
      return this[AppFlowyRichTextKeys.fontFamily];
    }
    return null;
  }

  double? get fontSize {
    if (containsKey(AppFlowyRichTextKeys.fontSize)) {
      return double.parse(this[AppFlowyRichTextKeys.fontSize].toString());
    }
    return null;
  }

  bool get superScript => this[AppFlowyRichTextKeys.superScript] == true;
  bool get subScript => this[AppFlowyRichTextKeys.subScript] == true;
}
