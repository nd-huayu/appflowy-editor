import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:autosync/autosync.dart' as autosync;
import 'package:autosync/autosync.dart';
import 'package:autosync/channel.dart' as ndclient;
import 'package:dio/dio.dart';

import 'IDocCooperativeApi.dart';
import 'build_client.dart';
import 'convert_server.dart';
import 'env.dart';
import 'logger.dart';

part 'NdOnlineControllerRangeId.dart';
part 'NdOnlineControllerTicket.dart';
part 'undo_redo_manager.dart';
part 'NdOnlineControllerNotify.dart';
part 'diff_sender.dart';
part 'NdOnlineControllerPush.dart';
part 'NdOnlineCtrlDisCon.dart';
part 'sync_close_channel.dart';

//是否打印单条命令
const V_SEND = false;
//是否打印合并后的命令
const VV_REQ = false;
//是否打印接收到的命令，理论上接收到的等于合并后发送的内容
const V_RECV = false;

void _printlog(String message) {
  // logger.w("autosync: $message");
  print("autosync: $message");
}

/// 在初始化过程中可能同时接收到来自初始化接口的命令和来自广播接口的命令
///
/// 来自广播接口的命令需要暂存起来等待初始化完成后接着执行
///
class _PreInitCache {
  final IDocCooperativeApi doc;
  final ndclient.NdClient client;

  late StreamController<ndclient.ClientCmdBroadcast> _controller;
  late StreamSink<ndclient.ClientCmdBroadcast> _sink;
  late Stream<ndclient.ClientCmdBroadcast> _stream;
  StreamSubscription<ndclient.ClientCmdBroadcast>? _subscription;

  _PreInitCache(this.doc, this.client) {
    _controller = StreamController();
    _sink = _controller.sink;
    _stream = _controller.stream;
  }

  bool _firstRec = false;

  void onRecvBoardcast(ndclient.ClientCmdBroadcast cmdboardcast) {
    if (_firstRec == false) {
      _firstRec = true;
      _printlog("firstBoardcast:${cmdboardcast.sbbCmdSeq}");
    }
    _sink.add(cmdboardcast);
  }

  void initDone() {
    _subscription ??= _stream.listen(_handleEvent);
  }

  void close() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _handleEvent(ndclient.ClientCmdBroadcast cmdBoardcast) {
    final fromSelf = client.isSelf(cmdBoardcast.connectId);
    final newsbbCmdSeq = cmdBoardcast.sbbCmdSeq;

    final diffmap = cmdBoardcast.data as Map<String, dynamic>;
    handleEvent(fromSelf, newsbbCmdSeq, diffmap, cmdBoardcast.connectId);
  }

  void handleEvent(
    bool fromSelf,
    int newsbbCmdSeq,
    dynamic diffmap,
    String? fromConnectId,
  ) {
    if (doc.sbbCmdSeq + 1 != newsbbCmdSeq) {
      _printlog("sbbCmdSeq error: cur:${doc.sbbCmdSeq}, next:$newsbbCmdSeq");
    }

    assert(doc.sbbCmdSeq + 1 == newsbbCmdSeq);
    doc.sbbCmdSeq = newsbbCmdSeq;
    assert(diffmap is Map);
    if ((diffmap as Map).isEmpty) {
      return;
    }

    assert(() {
      if (V_RECV) {
        _printlog("recv:${json.encode(diffmap)}");
      }
      return true;
    }());

    final activeDoc = doc;
    try {
      activeDoc.fromNetData = true;
      activeDoc.fromSelf = fromSelf;
      if (diffmap['opt'] == autosync.OptType.Box.index) {
        final difflist = diffmap['diff'] as List;
        for (int i = 0; i < difflist.length; i++) {
          final diff = autosync.Diff.fromJson(difflist[i]);
          _messageHandler(activeDoc, fromSelf, diff, fromConnectId);
        }
      } else {
        final diff = autosync.Diff.fromJson(diffmap['diff']);
        _messageHandler(activeDoc, fromSelf, diff, fromConnectId);
      }
    } catch (e) {
      _printlog("_PreInitCache.handleEvent:${e.toString()}");
    } finally {
      activeDoc.fromNetData = false;
    }
  }
}

void _onConnected(
    DiffSender acker,
    ndclient.NdClient client,
    ConnectStateNotifyer stateNotifyer,
    NotifyClientHandler notifyHandler,
    IDocCooperativeApi doc,
    int sbbCmdSeq,
    int roomId,
    int userId,
    int whole,
    String path) async {
  try {
    _printlog("start register");
    ndclient.RegisterAck registerAck = await ndclient.NdUtils.register(
      client,
      client.loginInfo.ticket,
      path,
      client.loginInfo.userType,
      client.loginInfo.aid,
    );
    if (registerAck.code != ndclient.ACK_CODE_SUCCESS) {
      if (registerAck == ndclient.ACK_CODE_REG_FAILED_ROOM_MAX_CLIENT_LIMIT) {
        stateNotifyer.showErrorMessage("用户数量已达上限");
      }
      final errstr = "register 失败，错误代码:${registerAck.code}";
      _printlog(errstr);
      client.close();
      return;
    }
    _printlog("register success");
  } catch (e) {
    final errstr = "register 失败，错误原因:${e}";
    _printlog(errstr);
    client.close();
    return;
  }

  //命令执行者，接受来自协同服务器的命令
  _PreInitCache preInitCache = _PreInitCache(doc, client);

  acker._start();
  //回滚本地离线操作
  final hasLocalOpt = acker._revert() > 0;

  client.onDisConnected = (reason) => preInitCache.close();

  //初始化过程中如果用其他用户在线操作，服务端依然会下发广播
  //此处用来临时接收这种情况下的操作命令
  client.boardcastHandler =
      (dffboardcast) => preInitCache.onRecvBoardcast(dffboardcast);

  //用户上下线变化回调
  client.userChangeHandler = (connectId, boardcast) => stateNotifyer
      .onUserOnlineStateChanged(boardcast.change, boardcast.connectId);

  //服务端主动推送的信息
  client.notifyClientHandler = (info) => notifyHandler.handler(info);
  //处理广播的一次性消息
  client.broadcastMessageHandler = (connectId, message) =>
      doc.onBroadcastMessage(connectId, message.type, message.data);

  //参数重传递的 sbbCmdSeq 是首次加载文档中的， doc.sbbCmdSeq 是操作一段时间后的最新的
  //正常情况下永远是 doc.sbbCmdSeq 大
  doc.sbbCmdSeq = max(doc.sbbCmdSeq, sbbCmdSeq);

  _printlog("clientCmdInitStart:${doc.sbbCmdSeq}， roomId:${roomId}");
  final lastNotifyerState = stateNotifyer.state;
  bool hasRemoteOpt = false;
  ndclient.NdUtils.clientCmdInit(client, doc.sbbCmdSeq, whole).listen(
      (initAck) {
    hasRemoteOpt = initAck.commands.isNotEmpty;
    for (int i = 0; i < initAck.commands.length; i++) {
      final cmd = initAck.commands[i];
      final fromSelf = false;
      final newsbbCmdSeq = cmd.sbbCmdSeq;
      final diffmap = cmd.data as Map<String, dynamic>;

      preInitCache.handleEvent(fromSelf, newsbbCmdSeq, diffmap, null);
    }
  }, onDone: () {
    stateNotifyer.onConnect(hasLocalOpt, hasRemoteOpt);
    //离线重连的情况下需要发送本地缓存的离线操作命令
    acker._advance();
    preInitCache.initDone();
    _printlog("clientCmdInit completed, sbbCmdSeq:${doc.sbbCmdSeq}");
    stateNotifyer.onSyncSuccess(lastNotifyerState);
    doc.applyEditState();
    doc.buildDirController();
    doc.buildVideoThumbnail();
  }, onError: (e, s) {
    _printlog("clientCmdInit error, ${e}");
    stateNotifyer.onServerError();
    client.close();
  }, cancelOnError: false);
}

//返回 false 表示参数异常，没有触发协同连接
//返回 true 表示开始进行协同连接，至于协同是否真正连接成功，通过异步回调返回
Future<bool> initOnlineDocument(
  IDocCooperativeApi doc,
  int sbbCmdSeq,
  String docurl,
  ConnectBean? openBean,
) async {
  //final ticket = NdToken.getTicket(roomId, userId, "mac");
  var env = EnvExtension.autoSelect(docurl);
  //如果存在强制参数，优先级更高
  if (openBean?.env?.isNotEmpty ?? false) {
    env = Env.values.firstWhere(
      (element) => element.name.toLowerCase() == openBean!.env!.toLowerCase(),
      orElse: () => env,
    );
  }
  //可强制指定从某个序号开始同步
  if (openBean?.sbbCmdSeq?.isNotEmpty ?? false) {
    final seq = openBean!.sbbCmdSeq!;
    sbbCmdSeq = int.parse(seq);
  }

  final document_id = openBean?.documentId; //str
  if (document_id == null) {
    _printlog("连接协同失败，缺少 document_id 参数");
    return false;
  }
  final user_type = openBean?.userType; //str
  if (user_type == null) {
    _printlog("连接协同失败，缺少 user_type 参数");
    return false;
  }
  final user_id = openBean?.userId; //int
  if (user_id == null) {
    _printlog("连接协同失败，缺少 user_id 参数");
    return false;
  }

  final deviceId = openBean?.deviceId; //str
  if (deviceId == null) {
    _printlog("连接协同失败，缺少 device_id 参数");
    return false;
  }
  String quickOpen = "no quick open";
  if (docurl.contains('document_id') == false) {
    final joinsym = docurl.contains('?') ? '&' : '?';
    quickOpen =
        "${docurl}${joinsym}document_id=${document_id}&env=${env.name}&user_id=${user_id}&user_type=${user_type}&device_id=${deviceId}";
    _printlog('quickopen:$quickOpen');
  }

  final connectInfo = await getTicketAutoUrl(
    docurl,
    env,
    openBean!.userId!,
    openBean.documentId!,
    openBean.deviceId!,
    openBean.userType,
    env == Env.Metting ? "nd-meeting" : null,
  );

  if (connectInfo == null) {
    return false;
  }
  final permission = connectInfo.ticketer.permission;
  if (permission == Permission_Edit || permission == Permission_OWN) {
    doc.setEidtState(true, false);
  } else {
    _printlog("文档只读权限");
    doc.setEidtState(false, false);
  }
  if (permission == Permission_NO) {
    _printlog("文档无任何权限,停止连接协同服务");
    return false;
  }

  openBean.roomId = connectInfo.ticketer.room_id;
  openBean.connectInfo = connectInfo;
  doc.env = env;
  doc.documentId = document_id;
  doc.roomId = connectInfo.ticketer.room_id;
  doc.connectBean = openBean;

  final idpool = NodeIdPool(env, document_id, 1000000, 1000000, 500000);
  await idpool.warmup();
  autosync.globalIdGenerator = idpool;

  final isHttps = EnvExtension.isHttps();
  final proto = isHttps ? 'wss' : 'ws';
  final wsurl = "$proto://${connectInfo.ticketer.server.host}/ws";
  _printlog("connect:$wsurl");

  //协同命令客户端实现
  ndclient.NdClient client = buildClient(
    connectInfo.ticketer.room_id,
    connectInfo.userId,
    connectInfo.ticketer.connect_id,
    connectInfo.ticketer.ticket,
    connectInfo.platform,
    user_type,
    user_id,
  );
  client.quickOpen = quickOpen;

  _printlog("client version:${client.platformInfo.version}");

  final stateNotifyer = ConnectStateNotifyer(doc);
  //网络连接通道
  ndclient.NdChannel channel = ndclient.NdChannel.create(wsurl);

  //命令发送者，并缓存发送的命令做ack确认
  DiffSender sender = DiffSender._(doc, client);

  final ctrlDisconnct = CtrlDisConnect(doc, client, channel, stateNotifyer);

  NotifyClientHandler notifyhandler =
      NotifyClientHandler(doc, client, stateNotifyer);

  //注入，方便其他位置直接发送命令数据
  doc.diffSender = sender;

  void sendHander(diff) {
    sender.sendBoardcast(diff);
  }

  hookDiffHandler(
    doc,
    sendHander,
  );

  // IDocuments.get().SetContainerCallback(_AutoCloseChannel(
  //   doc,
  //   client,
  //   channel,
  //   sender,
  //   ctrlDisconnct,
  // ));

  channel.onConnected((peer) async {
    client.onConnectServer(peer);
    try {
      _onConnected(
        sender,
        client,
        stateNotifyer,
        notifyhandler,
        doc,
        sbbCmdSeq,
        connectInfo.ticketer.room_id,
        connectInfo.userId,
        (openBean.whole ?? false)
            ? ndclient.WHOLE_FULL
            : ndclient.WHOLE_DISABLE,
        docurl,
      );
    } catch (e) {
      _printlog(e.toString());
    }
  });
  channel.onMessage((peer, message) {
    final resp = client.onMessage(message);
    sender._onResponse(resp);
  });
  channel.onDisConnected((reason) {
    client.onConnectDisconnect();
  });
  channel.onConnectError((reason) {
    stateNotifyer.onConnectError(false);
  });

  channel.connect();
  return true;
}

void hookDiffHandler(IDocCooperativeApi doc, autosync.RootDiffHandler handler) {
  autosync.SyncNodeRoot root = doc.syncNodeRoot!;
  var diffhandler = root.onDiffHandler;
  root.onDiffHandler = ((diff) {
    if (autosync.SyncNodeRoot.shadowMode) {
      diff = autosync.Diff(
        autosync.ModeType.PassThrough.index,
        diff.path,
        diff.rev,
        diff.opt,
        diff.newdata,
        diff.olddata,
        ancestor: diff.ancestor,
      );
    }
    diffhandler!(diff);
    handler(diff);
  });
}

void _leftOrRight(
  autosync.SyncNodeRoot root,
  autosync.Diff diff,
  Function function,
) {
  //无路本端是在正常模式还是在影子模式，正常落盘命令都直接强制修改原始数据，
  if (diff.mode == autosync.ModeType.Normal.index) {
    root.leftValue(() {
      function.call();
    });
  } else if (diff.mode == autosync.ModeType.PassThrough.index) {
    ///如果本端没有处于影子模式，但是接收到直通命令了，直接忽略
    ///只有本端和远端同处于影子模式时才处理影子命令
    if (autosync.SyncNodeRoot.shadowMode) {
      function.call();
    } else {
      //接收到切换模式命令要特殊处理下
      final enterShadowMode =
          diff.path == "0" && diff.newdata['isSpeakering'] == true;
      if (enterShadowMode) {
        function.call();
      }
    }
  }
}

void _messageHandler(
  IDocCooperativeApi doc,
  bool fromSelf,
  autosync.Diff diff,
  String? fromConnectId,
) {
  autosync.SyncNodeRoot root = doc.syncNodeRoot!;
  //来自远端的diff执行防止再次出发 onDiffHandler
  var diffhandler = root.onDiffHandler;
  try {
    _leftOrRight(root, diff, () {
      if (diff.opt == autosync.OptType.Custom.index) {
        root.customCommandHander.remoteCustomDiffHandler(diff, false);
        return;
      }
      if (diff.opt == autosync.OptType.Ignore.index) {
        root.ignoreCommandHander.remoteIgnoreDiffHandler(diff, fromSelf, false);
        return;
      }
      List<int> path = autosync.SyncNode.getPath(diff.path);
      autosync.SyncNode? node = root.findNode(path, 0);
      if (node == null) {
        return;
      }
      if (fromSelf && diff.opt == autosync.OptType.Setter.index) {
        //对于同一个属性的更新，如果本地发生多次更新，从网络返回的历史更新需要忽略，防止属性值抖动问题
        // 远端命令不会修改本端 rev
        if (diff.rev <= node.rev) {
          return;
        }
      }

      root.onDiffHandler = null;
      node.applyDiff(diff, false);
    });
  } catch (e) {
    rethrow;
  } finally {
    root.onDiffHandler = diffhandler;
  }
}
