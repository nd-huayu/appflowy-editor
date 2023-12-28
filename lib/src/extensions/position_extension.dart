import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

enum SelectionRange {
  character,
  word,
}

extension PositionExtension on Position {
  Position? moveHorizontal(
    EditorState editorState, {
    bool forward = true,
    SelectionRange selectionRange = SelectionRange.character,
  }) {
    final node = editorState.document.nodeAtPath(path);
    if (node == null) {
      return null;
    }

    if (forward && offset == 0) {
      final previousEnd = node.previous?.selectable?.end();
      if (previousEnd != null) {
        return previousEnd;
      }
      return null;
    } else if (!forward) {
      final end = node.selectable?.end();
      if (end != null && offset >= end.offset) {
        return node.next?.selectable?.start();
      }
    }

    switch (selectionRange) {
      case SelectionRange.character:
        final delta = node.delta;
        if (delta != null) {
          return Position(
            path: path,
            offset: forward
                ? delta.prevRunePosition(offset)
                : delta.nextRunePosition(offset),
          );
        }

        return Position(path: path, offset: offset);
      case SelectionRange.word:
        final delta = node.delta;
        if (delta != null) {
          final result = forward
              ? node.selectable?.getWordBoundaryInPosition(
                  Position(
                    path: path,
                    offset: delta.prevRunePosition(offset),
                  ),
                )
              : node.selectable?.getWordBoundaryInPosition(this);
          if (result != null) {
            return forward ? result.start : result.end;
          }
        }

        return Position(path: path, offset: offset);
    }
  }

  Position? moveVertical(
    EditorState editorState, {
    bool upwards = true,
  }) {
    final selection = editorState.selection;
    final rects = editorState.selectionRects();
    if (rects.isEmpty || selection == null) {
      return null;
    }

    Offset offset;
    if (selection.isBackward) {
      final rect = rects.reduce(
            (current, next) => current.bottom >= next.bottom ? current : next,
      );
      offset = upwards
          ? rect.topRight.translate(0, -rect.height)
          : rect.centerRight.translate(0, rect.height);
    } else {
      Rect rect = rects.reduce(
            (current, next) => current.top <= next.top ? current : next,
      );
      double offs = 9 * editorState.curCanvasScale;
      // 受缩放倍率影响，这里要乘以相应倍数
      rect = Rect.fromLTWH(
        rect.left,
        rect.top,
        rect.width * editorState.curCanvasScale,
        rect.height * editorState.curCanvasScale,
      );
      offset = upwards
          ? rect.topLeft.translate(0, -offs)
          : rect.bottomLeft.translate(0, offs);
    }

    return editorState.service.selectionService.getPositionInOffset(offset);
  }
}
