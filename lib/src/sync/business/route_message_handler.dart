import 'package:appflowy_editor/appflowy_editor.dart';

import '../../editor/sync/editing_bean.dart';

class RouteMessageHandler {
  final IDocCooperativeApi cooper;
  RouteMessageHandler(this.cooper) {
    cooper.registerBroadcastMessage(handleEditingStateMessage);
  }

  void handleEditingStateMessage(String connectId, int type, String message) {}
}
