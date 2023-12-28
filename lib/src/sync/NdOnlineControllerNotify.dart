part of 'NdOnlineController.dart';

//网络状态提示，检查到网络状态不佳时
const NetError = '网络异常，离线编辑内容将在网络恢复后同步至备课台';
//服务器状态提示，服务器异常时出现
const ServerError = '服务器出错，最新内容将在重新连接后同步至备课台';
//网盘空间不足提示
const DiskSpaceError = '空间不足，无法将课件同步至备课台';
//网盘空间快要用完时提示，小于10M
const DiskSpaceLimit = '磁盘空间不足，可能影响自动同步的体验，请及时清理';

//前提：服务器断网重连后
//条件：本地有增量编辑，同时无远端增量内容
const SyncingContent = '正在同步离线内容至备课台';

//前提：服务器断网重连后
//条件：当多人协同编辑，需要补齐差量时
//
const SyngintContent2 = '当前课件有多人在协同编辑，正在同步最新内容';

//前提：服务器断网重连后
//条件：无
const SyncSuccess = '同步成功，课件已同步至备课台';

enum ConnectState {
  None, //初始状态，首次连接成功后一定不会回到此状态
  Conneced,
  ConnectError,
}

class ConnectStateNotifyer {
  final IDocCooperativeApi doc;
  ConnectStateNotifyer(this.doc);
  ConnectState _state = ConnectState.None;

  ConnectState get state => _state;

  bool get isXStudy => doc.env == Env.XStudy;

  String _R(String str) {
    if (isXStudy) {
      return str.replaceAll("备课台", "我的资源库");
    }
    return str;
  }

  void onConnect(bool hasLocalOpt, bool hasRemoteOpt) {
    //只在断线重连成功时提示，首次连接不提示
    if (_state != ConnectState.ConnectError) {
      _state = ConnectState.Conneced;
      return;
    }

    _state = ConnectState.Conneced;

    if (hasRemoteOpt) {
      // web.showMessage(web.MessageType.info, _R(SyngintContent2));
    } else if (hasLocalOpt) {
      // web.showMessage(web.MessageType.info, _R(SyncingContent));
    }
  }

  void onSyncSuccess(ConnectState last) {
    if (_state != ConnectState.Conneced || last == ConnectState.None) {
      return;
    }
    // web.showMessage(web.MessageType.success, _R(SyncSuccess));
  }

  void onConnectError(bool userOpt) {
    if (_state == ConnectState.ConnectError) {
      return;
    }
    _state = ConnectState.ConnectError;

    if (!userOpt) {
      // web.showMessage(web.MessageType.warning, _R(ServerError));
    }
  }

  void onDiskSpaceLimit() {
    // web.showMessage(web.MessageType.warning, _R(DiskSpaceLimit));
  }

  void onDiskSpaceError() {
    // web.showMessage(web.MessageType.warning, _R(DiskSpaceError));
  }

  void onServerError() {
    // web.showMessage(web.MessageType.warning, _R(ServerError));
  }

  void showErrorMessage(String message) {
    // web.showMessage(web.MessageType.error, _R(message));
  }

  void showInfoMessage(String message) {
    // web.showMessage(web.MessageType.info, _R(message));
  }

  void onUserOnlineStateChanged(int change, String connectid) {
    // if (PlatformProvider.isNotWeb) {
    //   return;
    // }
    // final data = <String, dynamic>{'change': change, 'connectid': connectid};
    // WebMessage().sendMessage(kOnline, data);
  }

  void showReloadMessage(String version, String message) {
    // if (PlatformProvider.isNotWeb) {
    //   return;
    // }
    // final content = "${version} \n${message}";
    // web.showReloadMessage(web.MessageType.warning, _R(content));
  }

  void showForceReloadMessage(String message) {
    // if (PlatformProvider.isNotWeb) {
    //   return;
    // }
    // web.showReloadMessage(web.MessageType.warning, _R(message));
  }
}
