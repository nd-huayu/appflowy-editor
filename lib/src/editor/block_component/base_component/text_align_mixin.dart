import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

mixin BlockComponentTextAlignMixin {
  Node get node;

  /// 获取文字对齐方向
  TextAlign calculateTextAlign({
    TextAlign? defaultTextAlign,
  }) {
    TextAlign align = TextAlign.left;
    final value = node.attributes[blockComponentTextAlign] as String?;
    if (value != null) {
      if (value == blockComponentTextAlignLeft) {
        align = TextAlign.left;
      } else if (value == blockComponentTextAlignCenter) {
        align = TextAlign.center;
      } else if (value == blockComponentTextAlignRight) {
        align = TextAlign.right;
      } else if (value == blockComponentTextAlignJustify) {
        align = TextAlign.justify;
      }
    }
    return align;
  }

  MainAxisAlignment calculateRowMainAxisAlignment(TextAlign textAlign) {
    MainAxisAlignment alignment = MainAxisAlignment.start;
    if (textAlign == TextAlign.left) {
      alignment = MainAxisAlignment.start;
    } else if (textAlign == TextAlign.center) {
      alignment = MainAxisAlignment.center;
    } else if (textAlign == TextAlign.right) {
      alignment = MainAxisAlignment.end;
    }
    return alignment;
  }

  CrossAxisAlignment calculateColumnMainAxisAlignment(TextAlign textAlign) {
    CrossAxisAlignment alignment = CrossAxisAlignment.start;
    if (textAlign == TextAlign.left) {
      alignment = CrossAxisAlignment.start;
    } else if (textAlign == TextAlign.center) {
      alignment = CrossAxisAlignment.center;
    } else if (textAlign == TextAlign.right) {
      alignment = CrossAxisAlignment.end;
    }
    return alignment;
  }
}
