import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// BlockComponentContainer is a wrapper of block component
///
/// 1. used to update the child widget when node is changed
/// ~~2. used to show block component actions~~
/// 3. used to add the layer link to the child widget
class BlockComponentContainer extends StatefulWidget {
  const BlockComponentContainer({
    super.key,
    required this.configuration,
    required this.node,
    required this.builder,
    required this.editorState,
  });

  final Node node;
  final EditorState editorState;
  final BlockComponentConfiguration configuration;

  final WidgetBuilder builder;

  @override
  State<BlockComponentContainer> createState() =>
      BlockComponentContainerState();
}

class BlockComponentContainerState extends State<BlockComponentContainer> {
  bool get _showLockBorder {
    if (widget.node.type == 'page') {
      return false;
    }
    return widget.node.isLocked();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Node>.value(
      value: widget.node,
      child: Consumer<Node>(
        builder: (_, __, ___) {
          Log.editor.debug('node is rebuilding...: type: ${widget.node.type} ');
          widget.editorState.wordChange = true;
          Widget child = widget.builder(context);
          if (_showLockBorder) {
            child = Container(
              foregroundDecoration: BoxDecoration(
                border: Border.all(
                  color: Colors.red.withAlpha(100),
                  width: 1,
                ),
              ),
              child: child,
            );
          }
          return CompositedTransformTarget(
            link: widget.node.layerLink,
            child: child,
          );
        },
      ),
    );
  }
}
