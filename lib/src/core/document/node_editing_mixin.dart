part of 'node.dart';

mixin NodeEditingMixin on SyncNode {
  final List<String> _editingUsers = [];

  //对指定节点弱锁定，不是真的锁，只是加红框指示有用户正在编辑该节点
  void weakLock(String userEntry) {
    if (userEntry.isEmpty) {
      return;
    }
    if (!_editingUsers.contains(userEntry)) {
      _editingUsers.add(userEntry);
    }
    //print("weakLock: $syncNodeId, len:${_editingUsers.length}");
    (this as Node).notify();
  }

  //对指定节点解锁
  void weakUnlock(String userEntry) {
    _editingUsers.remove(userEntry);
    //print("unLock: $syncNodeId, len:${_editingUsers.length}");
    (this as Node).notify();
  }

  bool isLocked() {
    return _editingUsers.isNotEmpty;
  }
}
