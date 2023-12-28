import 'package:appflowy_editor/src/core/core.dart';
import 'package:autosync/autosync.dart';

void registerJson() {
  NodeSyncMixin.registerJson();
  JsonSerialization().register<SyncRxList<Node>>(
    (SyncRxList<Node> object) {
      final params = object.toJson();
      params['astype'] = 'SyncRxList<Node>';
      return params;
    },
    (Map<String, dynamic> params) {
      return SyncRxList<Node>.fromJson(params);
    },
    typename: 'SyncRxList<Node>',
  );
}
