import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/editor/sync/editing_bean.dart';
import 'package:appflowy_editor/src/sync/business/message_type.dart';
import 'package:flutter/material.dart';

import '../../../sync/business/route_message_handler.dart';

class EditingUserWidget extends StatefulWidget {
  const EditingUserWidget({
    super.key,
    required this.editorState,
    required this.child,
  });
  final EditorState editorState;
  final Widget child;

  @override
  State<EditingUserWidget> createState() => _EditingUserWidgetState();
}

class _EditingUserWidgetState extends State<EditingUserWidget>
    with WidgetsBindingObserver {
  EditorState get editorState => widget.editorState;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    editorState.selectionNotifier.addListener(_onSelectionChanged);
  }

  @override
  void didUpdateWidget(EditingUserWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.editorState != oldWidget.editorState) {
      editorState.selectionNotifier.addListener(_onSelectionChanged);
    }
  }

  @override
  void dispose() {
    editorState.selectionNotifier.removeListener(_onSelectionChanged);
    WidgetsBinding.instance.removeObserver(this);

    _clear();

    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();

    _clear();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    _showAfterDelay();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _resetSelectionByConnectId(String connectId) {}

  void _onSelectionChanged() {
    final coorper =
        editorState.document.root.root?.firstChild as IDocCooperativeApi?;
    if (coorper == null || coorper.connectBean == null) {
      // return;
    }
    List<Node> nodes = [];
    if (editorState.selection != null) {
      nodes = editorState.getNodesInSelection(editorState.selection!);
    }
    List<Node> preNodes = [];
    if (editorState.preSelection != null) {
      preNodes = editorState.getNodesInSelection(editorState.preSelection!);
    }

    if (preNodes.isNotEmpty) {
      for (final node in preNodes) {
        final connectId =
            coorper?.connectBean?.connectInfo?.ticketer.connect_id ?? '';
        node.weakUnlock(connectId);
        sendWeakLock(node.syncNodeId, connectId, false);
      }
    }

    if (nodes.isEmpty) {
      return;
    }

    for (final node in nodes) {
      final connectId =
          coorper?.connectBean?.connectInfo?.ticketer.connect_id ?? '';
      node.weakLock(connectId);
      sendWeakLock(node.syncNodeId, connectId, true);
    }
    // final selection = editorState.selection;
    // final selectionType = editorState.selectionType;
    // if (selection == null ||
    //     selection.isCollapsed ||
    //     selectionType == SelectionType.block) {
    //   _clear();
    // } else {
    //   // uses debounce to avoid the computing the rects too frequently.
    //   _showAfterDelay(const Duration(milliseconds: 200));
    // }
  }

  void sendWeakLock(int syncNodeId, String connectId, bool lock) {
    IDocCooperativeApi? coorper = editorState.cooperativeApi;
    if (coorper == null) {
      return;
    }

    coorper.diffSender?.boardcaseMessage(
      EditingStateChangeType,
      wrapEditingBeanMessage(
        EditingBean(
          syncNodeId: syncNodeId,
          lock: lock,
          connectId: connectId,
        ),
      ),
    );
  }

  void _clear() {}
  void _showAfterDelay([Duration? delay]) {}
}
