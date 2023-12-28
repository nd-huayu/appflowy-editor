part of 'NdOnlineController.dart';

class DiffSender extends IDiffSender {
  final IDocCooperativeApi _doc;
  final ndclient.NdClient _client;
  late autosync.SyncNodeRoot _root;

  late _UndoManager _undoManager;

  //周期内打包的命令列表
  final List<autosync.Diff> _sendCache = [];

  Timer? _senderTimer;

  //打包分割点
  final autosync.Diff _fence = autosync.Diff.test("fence");

  DiffSender._(this._doc, this._client) {
    _root = _doc.syncNodeRoot!;
    _undoManager = _UndoManager(_root);
  }

  Map<String, dynamic> get infos => _client.infos;

  void _onResponse(ndclient.Response resp) {
    _undoManager.onAck(resp.taskId);
  }

  //广播 diff 入队列，等待打包发送
  @override
  void sendBoardcast(autosync.Diff diff) {
    assert(() {
      if (diff.opt == autosync.OptType.Call.index) {
        final params = diff.methodParams;
        if (params != null) {
          assert(params is Map<String, dynamic>);
        }
        final oldparams = diff.undoMethodParams;
        if (oldparams != null) {
          assert(oldparams is Map<String, dynamic>);
        }
      }
      return true;
    }());
    assert(() {
      if (V_SEND) {
        _printlog("send:${json.encode(diff)}");
      }
      return true;
    }());
    //只有演讲者模式才同步类为为 PassThrough 的字段
    if (diff.mode == autosync.ModeType.PassThrough.index) {
      if (!autosync.kSpeakerMode) {
        return;
      }
    }
    _sendCache.add(diff);
  }

  @override
  Future<ndclient.SaveAck> sendSave() async {
    return ndclient.NdUtils.save(_client);
  }

  //发送请求生成视频缩略图
  @override
  Future<ndclient.ClientCustomMessageAck> sendReqVideoThumbnail(
    int id,
    String source,
    String thumbnail,
  ) {
    ndclient.VideoThumbParams params = ndclient.VideoThumbParams(
      id,
      source,
      thumbnail,
    );
    return ndclient.NdUtils.reqVideoThumbnail(_client, params);
  }

  @override
  Future<ndclient.ClientCustomMessageAck> sendConvertRequest(
    int id,
    String source,
    DocTypeEnum doc_type,
    String? container_id,
  ) {
    return convertRequest(_client, id, source, doc_type, container_id);
  }

  Future goDiffBox(List<autosync.Diff> diffs) async {
    //自定义命令列表单独发送，不经过融合，当前也没经过撤销堆栈
    final diff = ndclient.Diff(0, autosync.OptType.Box.index, diffs);
    final resp = await ndclient.NdUtils.clientCmd(_client, diff);
    final newsbbCmdSeq = resp.sbbCmdSeq;
    if (_doc.sbbCmdSeq + 1 != newsbbCmdSeq) {
      _printlog("sbbCmdSeq error: cur:${_doc.sbbCmdSeq}, next:$newsbbCmdSeq");
    }
    assert(_doc.sbbCmdSeq + 1 == newsbbCmdSeq);
    _doc.sbbCmdSeq = newsbbCmdSeq;
    return resp.data;
  }

  ///广播自用户自定义命令到其他在线客户端，服务端忽略对Ignore类型消息的处理
  @override
  void sendIgnoreCommand(List<autosync.Diff> difflist) {
    assert(() {
      for (int i = 0; i < difflist.length; i++) {
        if (difflist[i].opt != autosync.OptType.Ignore.index) {
          return false;
        }
      }
      return true;
    }(), "只能发送 Ignore 类型的 Diff");
    ndclient.NdUtils.diffBoardcast(
        _client, ndclient.Diff(0, autosync.OptType.Box.index, difflist));
  }

  //一个box表示一个原子操作，一起全部执行，中间不可分割
  @override
  void boardcastDiffBox(List<autosync.Diff> diffs) async {
    _boxPacker();
    for (int i = 0; i < diffs.length; i++) {
      sendBoardcast(diffs[i]);
    }
    _boxPacker();
  }

  @override
  void boardcaseMessage(int type, String message) {
    ndclient.NdUtils.messageBroadCast(_client, type, message);
  }

  void _boxPacker() {
    if (_sendCache.isEmpty) {
      return;
    }

    if (_sendCache.length == 1 && _sendCache.last == _fence) {
      return;
    }

    int fenceIndex = 0; //查询栅栏节点，并指向它，合并算法内部会自动忽略该类型节点
    for (int i = _sendCache.length - 1; i >= 0; i--) {
      if (_sendCache[i] == _fence) {
        fenceIndex = i;
        break;
      }
    }
    assert(fenceIndex >= 0);
    if (fenceIndex == 0) {
      fenceIndex = _sendCache.length - 1;
    }

    final box = _sendCache.getRange(0, fenceIndex + 1).toList();
    //参数 3 表示操作的 page 节点的id位置，根据文档树模型定义
    final sendbox = autosync.mergeDiffList(false, box, 3);
    //revertbox 已经是调整顺序后的命令列表，撤销动作不用反向执行
    final revertbox = autosync.mergeDiffList(true, box, 3);

    _sendCache.removeRange(0, fenceIndex + 1);

    final command = autosync.Command(
      sendbox,
      revertbox,
    );
    //发送到远端的数据不用携带olddata字段
    sendCommand(command, sendbox);
  }

  @override
  void sendCommand(autosync.Command command, List<autosync.Diff> difflist) {
    final req = ndclient.NdUtils.diffBoardcast(
        _client, ndclient.Diff(0, autosync.OptType.Box.index, difflist));
    _undoManager.addDiff(req.header.seq, command);
    assert(() {
      if (VV_REQ) {
        _printlog("send req:${json.encode(req)}");
      }
      return true;
    }());
  }

  @override
  void aVsync() {
    if (_sendCache.isEmpty) {
      return;
    }
    if (_sendCache.last == _fence) {
      return;
    }

    _sendCache.add(_fence);
  }

  void _tVsync(Timer timer) {
    _boxPacker();
  }

  void _start() {
    if (_senderTimer == null) {
      int delayMilli = 16;
      if (_doc.env == Env.XStudy || _doc.env == Env.TestXstudy) {
        delayMilli = 1000; // 该环境没有多用户同时编辑的场景，可以降低发送频率
      }
      _senderTimer =
          Timer.periodic(Duration(milliseconds: delayMilli), _tVsync);
    }
  }

  void close() {
    if (_senderTimer != null) {
      _senderTimer!.cancel();
      _senderTimer = null;
    }
  }

  // 回滚本地离线操作
  int _revert() {
    return _undoManager.revert();
  }

  // 重新执行本地离线操作
  void _advance() {
    _undoManager.advance();
  }
}
