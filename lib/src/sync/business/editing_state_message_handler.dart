import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/editor/sync/editing_bean.dart';

import 'message_type.dart';

class EditingStateMessageHandler {
  final IDocCooperativeApi cooper;
  EditingStateMessageHandler(this.cooper) {
    cooper.registerBroadcastMessage(handleEditingStateMessage);
  }

  void handleEditingStateMessage(String connectId, int type, String message) {
    if (type != 0) {
      return;
    }

    var editingBean = EditingBean.fromJson(jsonDecode(message));

    final node = cooper.syncNodeRoot?.findNode([editingBean.syncNodeId], 0);
    if (node is Node) {
      if (editingBean.lock) {
        node.weakLock(connectId);
      } else {
        node.weakUnlock(connectId);
      }
    }
  }
}
