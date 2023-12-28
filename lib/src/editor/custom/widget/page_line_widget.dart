import 'package:appflowy_editor/appflowy_editor.dart' as editor;
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

class PageLineWidget extends StatefulWidget {
  final editor.EditorState editorState;
  final double lineWidth; //线的长度
  final double gapHeight; // 线的间隔
  final double paddingTop; // 上边距
  final double paddingBottom; // 下边距

  const PageLineWidget({
    super.key,
    required this.editorState,
    required this.gapHeight,
    required this.lineWidth,
    this.paddingTop = 0,
    this.paddingBottom = 0,
  });

  @override
  State<StatefulWidget> createState() => _PageLineState();
}

class _PageLineState extends State<PageLineWidget> {
  double? totalHeight;

  double get lineWidth => widget.lineWidth;
  double get lineHeight => widget.gapHeight;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    widget.editorState.scrollService?.scrollController
        .removeListener(_scrollListener);
  }

  double get padding => widget.paddingTop + widget.paddingBottom;

  void _scrollListener() {
    final scrollService = widget.editorState.scrollService;
    if (totalHeight == null ||
        scrollService == null ||
        scrollService.onePageHeight == null) {
      return;
    }

    int count1 = totalHeight! ~/ lineHeight;
    int count2 = (scrollService.onePageHeight! - padding) ~/ lineHeight;
    if (count1 != count2) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final scrollService = widget.editorState.scrollService;
    if (scrollService == null || scrollService.onePageHeight == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        setState(() {});
      });
      return Container();
    }

    /// 只注册一次回调
    if (totalHeight == null) {
      scrollService.scrollController.addListener(_scrollListener);
    }
    totalHeight = scrollService.onePageHeight! - padding;
    int count = totalHeight! ~/ lineHeight;

    return Column(
      children: [
        SizedBox(height: widget.paddingTop),
        CustomPaint(
          painter: _PageLinePainter(count, Size(lineWidth, lineHeight)),
        ),
      ],
    );
  }
}

class _PageLinePainter extends CustomPainter {
  final int count;
  final Size lineSize;

  final Paint _paintLine = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFFDCDEE3);
  final Paint _paintBg = Paint()..color = const Color(0xFFBEC2CC);

  _PageLinePainter(this.count, this.lineSize);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 1; i <= count; i++) {
      double y = i * lineSize.height;

      final text = TextPainter(
        text: TextSpan(
          text: 'P$i',
          style: const TextStyle(fontSize: 12, color: Color(0xFF686773)),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      text.layout();

      double btnWidth = 24; // text.width + 10;
      double btnHeight = 28; // text.height + 12;

      /// 虚线
      Path path = Path()
        ..moveTo(0, y)
        ..lineTo(lineSize.width - btnWidth, y);
      canvas.drawPath(
        dashPath(path, dashArray: CircularIntervalList<double>([5.0, 5.0])),
        _paintLine,
      );

      /// 文本背景
      Rect rect = Rect.fromLTWH(
        lineSize.width - btnWidth,
        y - btnHeight,
        btnWidth,
        btnHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        _paintBg,
      );

      /// 文本
      text.paint(
        canvas,
        Offset(
          rect.center.dx - text.width / 2,
          rect.center.dy - text.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
