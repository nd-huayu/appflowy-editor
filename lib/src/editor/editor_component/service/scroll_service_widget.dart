import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/editor/editor_component/service/scroll/auto_scrollable_widget.dart';
import 'package:appflowy_editor/src/editor/editor_component/service/scroll/auto_scroller.dart';
import 'package:appflowy_editor/src/editor/editor_component/service/scroll/desktop_scroll_service.dart';
import 'package:appflowy_editor/src/editor/editor_component/service/scroll/mobile_scroll_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScrollServiceWidget extends StatefulWidget {
  final bool scrollbarVisible;
  const ScrollServiceWidget({
    Key? key,
    required this.editorScrollController,
    required this.child,
    this.scrollbarVisible = true, // fyl 是否显示进度条
  }) : super(key: key);

  final EditorScrollController editorScrollController;

  final Widget child;

  @override
  State<ScrollServiceWidget> createState() => _ScrollServiceWidgetState();
}

class _ScrollServiceWidgetState extends State<ScrollServiceWidget>
    implements AppFlowyScrollService {
  final _forwardKey =
      GlobalKey(debugLabel: 'forward_to_platform_scroll_service');
  AppFlowyScrollService get forward =>
      _forwardKey.currentState as AppFlowyScrollService;

  late EditorState editorState = context.read<EditorState>();

  @override
  late ScrollController scrollController = ScrollController();

  double offset = 0;

  @override
  void initState() {
    super.initState();

    editorState.selectionNotifier.addListener(_onSelectionChanged);
    editorState.onDirectoryClick = (node) {
      _onSelectionChanged(
        tarSelection: Selection(
          start: Position(path: node.path),
          end: Position(path: node.path),
        ),
        duration: Duration.zero,
      );
    };
  }

  @override
  void dispose() {
    editorState.selectionNotifier.removeListener(_onSelectionChanged);
    editorState.onDirectoryClick = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: widget.editorScrollController,
      child: AutoScrollableWidget(
        scrollbarVisible: widget.scrollbarVisible,
        scrollController: widget.editorScrollController.scrollController,
        builder: ((context, autoScroller) {
          if (PlatformExtension.isDesktopOrWeb) {
            return _buildDesktopScrollService(context, autoScroller);
          } else if (PlatformExtension.isMobile) {
            return _buildMobileScrollService(context, autoScroller);
          }

          throw UnimplementedError();
        }),
      ),
    );
  }

  Widget _buildDesktopScrollService(
    BuildContext context,
    AutoScroller autoScroller,
  ) {
    return DesktopScrollService(
      key: _forwardKey,
      child: widget.child,
    );
  }

  Widget _buildMobileScrollService(
    BuildContext context,
    AutoScroller autoScroller,
  ) {
    return MobileScrollService(
      key: _forwardKey,
      child: widget.child,
    );
  }

  void _onSelectionChanged({Selection? tarSelection, Duration? duration}) {
    // should auto scroll after the cursor or selection updated.
    Selection? selection = editorState.selection;
    SelectionUpdateReason updateReason = editorState.selectionUpdateReason;
    if (tarSelection != null) {
      selection = tarSelection;
      updateReason = SelectionUpdateReason.uiEvent;
    }
    if (selection == null ||
        [SelectionUpdateReason.selectAll, SelectionUpdateReason.searchHighlight]
            .contains(updateReason)) {
      return;
    }

    final selectionType = editorState.selectionType;

    /// fyl：修复文本内容好几页时，全选-更改字号会触发内容滚动问题
    if (editorState.preSelection == selection) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final selectionRect =
          editorState.selectionRects(targetSelection: selection);
      if (selectionRect.isEmpty) {
        return;
      }

      final endTouchPoint = selectionRect.last.centerRight;

      if (selection!.isCollapsed) {
        if (PlatformExtension.isMobile) {
          // soft keyboard
          // workaround: wait for the soft keyboard to show up
          Future.delayed(const Duration(milliseconds: 300), () {
            startAutoScroll(endTouchPoint, edgeOffset: 50);
          });
        } else {
          if (selectionType == SelectionType.block ||
              updateReason == SelectionUpdateReason.transaction) {
            final box = editorState.renderBox;
            final editorOffset = box?.localToGlobal(Offset.zero);
            final editorHeight = box?.size.height;
            double offset = 100;
            if (editorOffset != null && editorHeight != null) {
              // try to center the highlight area
              double scale = editorState.editorStyle.customData?.scale ?? 1;
              //fyl：1/2改为1/4，避免画布缩小时触发EdgeDraggingAutoScroller._scroll的断言
              offset = editorOffset.dy + editorHeight / 4.0 * scale;
            }
            startAutoScroll(
              endTouchPoint,
              edgeOffset: offset,
              duration: Duration.zero,
            );
          } else {
            startAutoScroll(endTouchPoint, edgeOffset: 100, duration: duration);
          }
        }
      } else {
        startAutoScroll(endTouchPoint, duration: duration);
      }
    });
  }

  @override
  void disable() => forward.disable();

  @override
  double get dy => forward.dy;

  @override
  void enable() => forward.enable();

  @override
  double get maxScrollExtent => forward.maxScrollExtent;

  @override
  double get minScrollExtent => forward.minScrollExtent;

  @override
  double? get onePageHeight => forward.onePageHeight;

  @override
  int? get page => forward.page;

  @override
  void scrollTo(
    double dy, {
    Duration duration = const Duration(milliseconds: 150),
  }) =>
      forward.scrollTo(dy, duration: duration);

  @override
  void jumpTo(int index) => forward.jumpTo(index);

  @override
  void jumpToTop() {
    forward.jumpToTop();
  }

  @override
  void jumpToBottom() {
    forward.jumpToBottom();
  }

  @override
  void startAutoScroll(
    Offset offset, {
    double edgeOffset = 100,
    AxisDirection? direction,
    Duration? duration,
  }) {
    forward.startAutoScroll(
      offset,
      edgeOffset: edgeOffset,
      direction: direction,
      duration: duration,
    );
  }

  @override
  void stopAutoScroll() => forward.stopAutoScroll();

  @override
  void goBallistic(double velocity) => forward.goBallistic(velocity);
}
