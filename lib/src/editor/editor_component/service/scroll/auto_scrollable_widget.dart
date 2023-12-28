import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/editor/custom/scroll/no_bar_scroll_behavior.dart';
import 'package:appflowy_editor/src/editor/editor_component/service/scroll/auto_scroller.dart';
import 'package:flutter/material.dart';

class AutoScrollableWidget extends StatefulWidget {
  final bool scrollbarVisible; // fyl 是否显示进度条
  const AutoScrollableWidget({
    super.key,
    this.shrinkWrap = false,
    required this.scrollController,
    required this.builder,
    this.scrollbarVisible = true,
  });

  final bool shrinkWrap;
  final ScrollController scrollController;
  final Widget Function(
    BuildContext context,
    AutoScroller autoScroller,
  ) builder;

  @override
  State<AutoScrollableWidget> createState() => _AutoScrollableWidgetState();
}

class _AutoScrollableWidgetState extends State<AutoScrollableWidget> {
  late AutoScroller _autoScroller;
  late ScrollableState _scrollableState;

  @override
  Widget build(BuildContext context) {
    Widget builder(context) {
      return widget.builder(context, _autoScroller);
    }

    _scrollableState = ScrollableState();
    _initAutoScroller();

    if (widget.shrinkWrap) {
      return widget.builder(context, _autoScroller);
    } else {
      return LayoutBuilder(
        builder: (context, viewportConstraints) => ScrollConfiguration(
          behavior: widget.scrollbarVisible // fyl 是否显示进度条
              ? ScrollConfiguration.of(context)
              : const NoBarScrollBehavior(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(right: 1),
            controller: widget.scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: Builder(
                builder: builder,
              ),
            ),
          ),
        ),
      );
    }
  }

  void _initAutoScroller() {
    _autoScroller = AutoScroller(
      _scrollableState,
      velocityScalar: PlatformExtension.isDesktopOrWeb ? 25 : 100,
      onScrollViewScrolled: () {
        // _autoScroller.continueToAutoScroll();
      },
    );
  }
}
