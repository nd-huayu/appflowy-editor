part of 'NdOnlineController.dart';

class CtrlDisConnect {
  IDocCooperativeApi doc;
  ndclient.NdClient client;
  ndclient.NdChannel channel;
  ConnectStateNotifyer notifyer;

  CtrlDisConnect(
    this.doc,
    this.client,
    this.channel,
    this.notifyer,
  ) {
    // doc.listenerLifecycle(
    //   enterBackground: _onEnterBackground,
    //   becomeActive: _onBecomActive,
    // );

    timer = Timer.periodic(Duration(seconds: 30), _onTimeOut);
  }

  int runingInBackgorundSinceEpochTime = 0;
  Timer? timer;
  bool timeroutDised = false; //超时断开状态

  //程序进入后台，设置时间戳，当超时时根据是否处于连接状态决定是否进入超时断开流程
  //超时断开的连接，下次重新进入前台后会自动重连，其他原因断开的连接不会重连
  void _onTimeOut(Timer timer) {
    if (runingInBackgorundSinceEpochTime == 0) {
      return;
    }
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final diffEpoch = nowEpoch - runingInBackgorundSinceEpochTime;
    final duration = Duration(milliseconds: diffEpoch);
    if (duration > Duration(minutes: 5)) {
      if (client.isConnected()) {
        logger.d(
            "[autosync] _onTimeOut epoch:$runingInBackgorundSinceEpochTime, autoDis");
        client.close();
        doc.setEidtState(false, true);
        timeroutDised = true;
        runingInBackgorundSinceEpochTime = 0;
        notifyer.showForceReloadMessage("由于您长时间处于未操作状态，连接已断开。");
      }
    }
  }

  void _onEnterBackground() {
    runingInBackgorundSinceEpochTime = DateTime.now().millisecondsSinceEpoch;

    logger.d(
        "[autosync] _onEnterBackground epoch:$runingInBackgorundSinceEpochTime");
  }

//进入前台回调
//根据当前是否处于超时断开状态决定是否触发重连
  void _onBecomActive() {
    logger
        .d("[autosync] _onBecomActive epoch:$runingInBackgorundSinceEpochTime");
    runingInBackgorundSinceEpochTime = 0;
    // if (client.isConnected()) {
    //   timeroutDised = false;
    // }

    // if (timeroutDised && (!client.isConnected())) {
    //   channel.connect();
    // }
  }

  void OnDocumentClose() {
    timer?.cancel();
  }
}
