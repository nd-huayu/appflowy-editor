part of 'NdOnlineController.dart';

class _UndoManager {
  autosync.SyncNodeRoot _root;
  Map<int, autosync.Command> _commandBox = {};
  autosync.CommandBox? _performBox; //每次执行时克隆一份

  _UndoManager(this._root);

  void addDiff(int req, autosync.Command command) {
    _commandBox[req] = command;
  }

  void onAck(int req) {
    _commandBox.remove(req);
  }

  // 回滚本地离线操作
  int revert() {
    assert(_performBox == null, "已经执行过一次 revert");
    if (_performBox != null) {
      return 0;
    }
    //生成撤销命令列表
    final commands = _commandBox.values.toList();
    _performBox = List<autosync.Command>.generate(
      commands.length,
      (index) => commands[index],
    );

    //清空缓存盒，准备回滚过程中发送的命令缓存
    _commandBox.clear();

    _printlog("revert:${_performBox!.length}");
    _performDiffs(_performBox!, true);
    return _performBox!.length;
  }

  void advance() {
    assert(_performBox != null, "还未执行过 revert");
    if (_performBox == null) {
      return;
    }
    _printlog("advance:${_performBox!.length}");
    _performDiffs(_performBox!, false);
    _performBox = null;
  }

  //执行撤销时，box本身需要逆序执行，但是每条 Command 中的命令序列不需要逆序执行了
  void _performDiffs(autosync.CommandBox box, bool undo) {
    final diffs = <autosync.Diff>[];
    box = undo ? box.reversed.toList() : box;
    for (int i = 0; i < box.length; i++) {
      final params = undo ? box[i].redocommand : box[i].undocommand;
      params.forEach((diff) {
        diffs.add(diff);
      });
    }

    _root.dispatchDiff(diffs, undo);
  }
}
