import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final indentableBlockTypes = {
  BulletedListBlockKeys.type,
  NumberedListBlockKeys.type,
  TodoListBlockKeys.type,
  ParagraphBlockKeys.type,
};

/// Indent the current block
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent indentCommand = CommandShortcutEvent(
  key: 'indent',
  command: 'tab',
  handler: _indentCommandHandler,
);

// 响应缩进的tab事件
CommandShortcutEventHandler _indentDefaultCommandHandler = (editorState) {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return KeyEventResult.ignored;
  }
  final node = editorState.getNodeAtPath(selection.end.path);
  final previous = node?.previous;
  if (node == null ||
      previous == null ||
      !indentableBlockTypes.contains(previous.type) ||
      !indentableBlockTypes.contains(node.type)) {
    return KeyEventResult.handled; // ignore the system default tab behavior
  }
  final path = previous.path + [previous.children.length];
  final afterSelection = Selection(
    start: selection.start.copyWith(path: path),
    end: selection.end.copyWith(path: path),
  );
  final transaction = editorState.transaction
    ..deleteNode(node)
    ..insertNode(path, node, deepCopy: true)
    ..afterSelection = afterSelection;
  editorState.apply(transaction);

  return KeyEventResult.handled;
};

// 响应插入tab字符事件
CommandShortcutEventHandler _indentCommandHandler = (editorState) {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return KeyEventResult.ignored;
  }
  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node == null || delta == null) {
    return KeyEventResult.ignored;
  }

  // if(delta.operations.first is TextInsert && (delta.operations.first as TextInsert).text.startsWith('\t')){
  //   return _indentDefaultCommandHandler(editorState);
  // }
  // else{
  //   editorState.insertTextAtCurrentSelection('\t');
  //   return KeyEventResult.handled;
  // }

  editorState.insertTextAtCurrentSelection('\t');
  return KeyEventResult.handled;
};
