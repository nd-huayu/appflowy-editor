import 'package:flutter/widgets.dart';

class CustomStyleData {
  final Decoration? decoration; // 内容区域（去掉header，footer）的背景色
  final double? minHeight; // 内容区域（去掉header，footer）的最小高度
  final bool scrollbarVisible; // fyl：是否显示滚动条
  final double scale; // fyl：缩放比例
  final Size editorSize;
  EdgeInsets? editorPadding;
  final bool? showPageLine; // fyl：是否显示分页线
  final double headerHeight;
  final double footerHeight;

  CustomStyleData({
    required this.editorSize,
    this.decoration,
    this.minHeight,
    this.scrollbarVisible = true,
    this.scale = 1,
    this.editorPadding,
    this.showPageLine = false,
    this.headerHeight = 0,
    this.footerHeight = 0,
  }) {
    editorPadding ??= EdgeInsets.zero;
  }
}
