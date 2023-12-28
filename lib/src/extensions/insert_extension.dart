import 'package:appflowy_editor/appflowy_editor.dart';

extension InsertMediaNode on EditorState {
  Future<void> insertImageNode(
    String src,
  ) async {
    _realInsertNode(
        this,
        () => imageNode(
              url: src,
            ));
  }

  Future<void> insertAudioNode(String src,
      {bool autoPlay = false, bool isLoop = false}) async {
    _realInsertNode(
        this,
        () => audioNode(
              url: src,
              autoPlay: autoPlay,
              isLoop: isLoop,
            ));
  }

  Future<void> insertVideoNode(String src,
      {bool autoPlay = false, bool isLoop = false}) async {
    _realInsertNode(
        this, () => videoNode(url: src, autoPlay: autoPlay, isLoop: isLoop));
  }

  Future<void> _realInsertNode(EditorState editorState, Function call) async {
    final insertNode = call();
    final transaction = this.transaction;
    final selection = this.selection;
    if (selection == null) {
      return;
    }
    final node = getNodeAtPath(selection.end.path);
    if (node == null) {
      return;
    }
    final delta = node.delta;
    //无选区，焦点在尾巴之前
    if (selection.isCollapsed &&
        node.type == ParagraphBlockKeys.type &&
        delta != null) {
      final length = getOperationLength(delta.operations);
      if (selection.endIndex < length) {
        //光标在行首
        if (selection.endIndex == 0) {
          final selection = this.selection;
          if (selection == null) {
            return;
          }
          final node = getNodeAtPath(selection.end.path);
          if (node == null) {
            return;
          }
          transaction.insertNode(
            node.path,
            insertNode,
          );
          transaction.afterSelection = Selection.collapsed(
            Position(
              path: node.path.next,
              offset: 0,
            ),
          );
          apply(transaction);
        } else {
          editorState.insertNewLine(position: selection.end).then((value) {
            final selection = this.selection;
            if (selection == null) {
              return;
            }
            final node = getNodeAtPath(selection.end.path);
            if (node == null) {
              return;
            }
            transaction.insertNode(
              node.path,
              insertNode,
            );
            transaction.afterSelection = Selection.collapsed(
              Position(
                path: node.path.next,
                offset: 0,
              ),
            );
            apply(transaction);
          });
        }
        return;
      }
    }
    //无选区焦点在尾巴
    //或有选区
    if (node.type == ParagraphBlockKeys.type &&
        (node.delta?.operations.isEmpty ?? false)) {
      //当前处于文本空行
      // 仅存在一行，且无内容
      if (editorState.document.root.children.length == 1 &&
          editorState.document.root.children.first.type ==
              ParagraphBlockKeys.type &&
          (editorState.document.root.children.first.delta?.operations.isEmpty ??
              false)) {
        transaction.insertNode(
          node.path.previous,
          insertNode,
        );
      } else {
        transaction.insertNode(
          node.path,
          insertNode,
        );
      }
    } else {
      transaction.insertNode(
        node.path.next,
        insertNode,
      );
    }

    transaction.afterSelection = Selection.collapsed(
      Position(
        path: node.path.next,
        offset: 0,
      ),
    );

    return apply(transaction);
  }

  int getOperationLength(List<TextOperation> ops) {
    int length = 0;

    try {
      for (var op in ops.map((e) => e as TextInsert)) {
        length += op.length;
      }
    } catch (e) {}

    return length;
  }
}
