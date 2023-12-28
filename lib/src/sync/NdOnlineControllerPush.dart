part of 'NdOnlineController.dart';

class NotifyClientHandler {
  final IDocCooperativeApi doc;
  final ndclient.NdClient client;
  final ConnectStateNotifyer stateNotifyer;
  NotifyClientHandler(this.doc, this.client, this.stateNotifyer);

  void handler(ndclient.NotifyClientInfo info) {
    try {
      final type = info.type;
      if (type == ndclient.NOTIFY_TYPE_ROOM_DELETED) {
        client.close();
        logger.d("NotifyClientHandler:room deleted 禁止编辑");
        doc.setEidtState(false, true);
      } else if (type == ndclient.NOTIFY_TYPE_PERMISSION) {
        if (info.params == ndclient.PERMISSION_TYPE_OWNER ||
            info.params == ndclient.PERMISSION_TYPE_READ_WRITE) {
          doc.setEidtState(true, true);
        } else if (info.params == ndclient.PERMISSION_TYPE_NO) {
          client.close();
          doc.setEidtState(false, true);
        } else {
          logger.d("NotifyClientHandler:parse error 禁止编辑");
          doc.setEidtState(false, true);
        }
      } else if (type == ndclient.NOTIFY_TYPE_VERSION) {
        // final params = json.decode(info.params);
        // final versinoInfo = ndcmd.VersionInfo.fromJson(params);
        // if (versinoInfo.forceUpdate) {
        //   stateNotifyer.showReloadMessage(
        //       versinoInfo.version, versinoInfo.content);
        // } else {
        //   stateNotifyer.showInfoMessage(versinoInfo.content);
        // }
      } else if (type == ndclient.NOTIFY_TYPE_LONGTIME_NO_OPT) {
        client.close();
        doc.setEidtState(false, true);
        stateNotifyer.showForceReloadMessage("由于您长时间未操作，连接已断开。");
      } else if (type == ndclient.NOTIFY_TYPE_VIDEO_THUMBNAIL) {
        final thumbparams = ndclient.VideoThumbParams.decode(info.params);

        final node = doc.syncNodeRoot?.searchNode(thumbparams.id);
        node?.updateVersion();
        node?.updateNode();
      } else if (type == ndclient.NOTIFY_TYPE_CONVERT_RESULT) {
        logger.d("转码服务响应:${info.params}");
        final params = json.decode(info.params);
        final response = ndclient.ConvertResponse.fromJson(params);
        final id = response.id;
        final node = doc.syncNodeRoot?.searchNode(id);
        if (node == null) {
          logger.e("转码响应种描述的节点id:$id 在数据模型上找不到");
        }
        node?.updateVersion();
        node?.updateNode();
      }
    } catch (e) {
      logger.e('handle push message error:${e.toString()}');
    }
  }
}
