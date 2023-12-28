import 'package:autosync/autosync.dart';

import 'NdOnlineController.dart';
import 'convert_server.dart';
import 'env.dart';

/// IDocument 类中，文档协同相关的接口
mixin IDocCooperativeApi {
  ///同步节点根，子类必须实现
  SyncNodeRoot? get syncNodeRoot;

  //协同房间ID,服务端落盘时赋值，客户端不用赋值
  int? roomId;

  //最后一条命令的序号，服务端落盘时赋值，客户端首次打开新文档默认为0，后续利于该字段判断命令连续性
  //客户端打开文档时，从文档序列化数据中读取该值
  int sbbCmdSeq = 0;

  //协同创建参数，快速访问协同连接参数
  ConnectBean? connectBean;

  // 协同文档ID，连上协同时客户端自动赋值
  String? documentId;
  // 协同环境，连上协同时客户端自动赋值
  Env? env;

  /// 命令发送器，连上协同时客户端自动赋值
  IDiffSender? diffSender;

  /// 是否是协同文档
  bool isCooperative = false;

  //协同命令执行过程中的状态记录
  bool fromNetData = false;
  bool fromSelf = false;
  //来自其他远程客户端, 在async中使用可能不准确
  bool get fromOtherClient => fromNetData && (!fromSelf);

  void buildDirController() {}
  void buildVideoThumbnail() {}
  bool get isAllowEdit;
  void setEidtState(bool isEdit, bool immiapply) {}
  void applyEditState() {}

  //一次性消息广播处理器
  final List<BroadcastMessageHandler> _broadcastMessageHandler = [];
  // //注册一次性消息广播处理器
  void registerBroadcastMessage(BroadcastMessageHandler handler) {
    _broadcastMessageHandler.add(handler);
  }

  // //移除一次性消息广播处理器
  void unregisterBroadcastMessage(BroadcastMessageHandler handler) {
    _broadcastMessageHandler.remove(handler);
  }

  void onBroadcastMessage(String connectId, int type, String message) {
    for (var handler in _broadcastMessageHandler) {
      handler(connectId, type, message);
    }
  }
}

abstract class IDiffSender {
  //发送保存命令
  Future sendSave();
  //发送请求生成视频缩略图
  Future sendReqVideoThumbnail(int id, String source, String thumbnail);
  Future sendConvertRequest(
    int id,
    String source,
    DocTypeEnum doc_type,
    String? container_id,
  );
  //发送自定义命令盒，一个命令盒是一个原子操作
  void boardcastDiffBox(List<Diff> diffs);
  //发送一次性消息
  void boardcaseMessage(int type, String message);
  void sendCommand(Command command, List<Diff> difflist);

  //广播 diff 入队列，等待打包发送
  void sendBoardcast(Diff diff);

  ///广播自用户自定义命令到其他在线客户端，服务端忽略对Ignore类型消息的处理
  void sendIgnoreCommand(List<Diff> difflist);
  //业务动作触发同步时间节点，打包算法不会把同一个周期内的diff拆分到不同的包里发送
  void aVsync();
  Map<String, dynamic> get infos;
  void close();
}

class ConnectBean {
  String? documentId;
  String? deviceId;
  int? userId;
  String? userType;
  String? env;
  String? sbbCmdSeq;
  int? roomId;
  bool? whole;
  ConnectInfo? connectInfo;

  ConnectBean({
    this.documentId,
    this.deviceId,
    this.userId,
    this.userType,
    this.env,
    this.sbbCmdSeq,
    this.roomId,
    this.whole,
    this.connectInfo,
  });
}

typedef BroadcastMessageHandler = void Function(
  String connectId,
  int type,
  String message,
);
