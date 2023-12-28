import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/history/undo_manager.dart';
import 'package:autosync/autosync.dart' as autosync;

class UniversalUndoManager2 extends autosync.UndoRedoManger {
  final UndoManager _undoManager;

  UniversalUndoManager2(super.maxSize) : _undoManager = UndoManager(maxSize);

  FixedSizeStack get redoStack => _undoManager.redoStack;
  FixedSizeStack get undoStack => _undoManager.undoStack;
  EditorState? get state => _undoManager.state;
  set state(EditorState? state) => _undoManager.state = state;

  //根据是否密封决定是否创建新的撤销项目
  HistoryItem getUndoHistoryItem(bool fromRedoOpt) {
    if (undoStack.isEmpty || undoStack.last.sealed) {
      //如果是redo操作产生的撤销项目，不用在diff撤销管理器中创建新的撤销项目
      if (!fromRedoOpt) {
        addEmptyDiffOperator();
      }
    }

    //如果是redo操作产生的撤销项目，不合并到上一个堆栈中
    if (fromRedoOpt) {
      return _newHistoryItem();
    }

    return _undoManager.getUndoHistoryItem();
  }

  //创建新的撤销项目
  HistoryItem _newHistoryItem() {
    final item = HistoryItem();
    undoStack.push(item);
    return item;
  }

  @override
  void endSession() {
    //todo: 改造返回值
    final success = super.endSession();
    if (true) {
      addEmptyUndoOperator();
      redoStack.clear();
    }
  }

  @override
  void undo() {
    super.undo();
    _undoManager.undo();
  }

  @override
  void redo() {
    super.redo();
    _undoManager.redo();
  }

  void forgetRecentUndo() {
    //todo: 实现
    // _asmanager.abandonSession();
    _undoManager.forgetRecentUndo();
  }

  //添加一个原始撤销队列的占位
  void addEmptyUndoOperator() {
    if (undoStack.isNonEmpty) {
      undoStack.last.seal();
    }
    final undoItem = HistoryItem();
    undoItem.seal();
    undoItem.add(UndoDiffOperation([]));
    _undoManager.undoStack.push(undoItem);
  }

//添加一个Diff撤销队列的占位
  void addEmptyDiffOperator() {
    super.beginSession();
    super.addDiff(autosync.Diff.fromIgnore('empty', {}));
    super.endSession();
  }
}
