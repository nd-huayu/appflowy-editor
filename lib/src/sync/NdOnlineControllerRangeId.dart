part of 'NdOnlineController.dart';

class NodeIdPool extends IdGenerator {
  final Env env;
  final String document_id;
  final int initcap;
  final int step;
  final int threshold;

  final List<RangeId> _ranges = [];
  RangeId? _lastUsedRange;
  int _lastUsedId = 0;
  bool _duraingReqRange = false;

  /// 节点id池，负责分配节点id
  /// document_id 文档id
  /// initcap 初始池容量
  /// setp 每次分配的长度
  /// threshold 阈值，剩余id号不足threshold时触发申请
  NodeIdPool(
      this.env, this.document_id, this.initcap, this.step, this.threshold);

  Future warmup() async {
    //临时废掉一个
    await getRangeIdAutoUrl(document_id, initcap, env);
    await getRangeIdAutoUrl(document_id, initcap, env);
    final range = await getRangeIdAutoUrl(document_id, initcap, env);
    if (range == null) {
      return;
    }
    _ranges.add(range);
    return;
  }

  int _genId() {
    if (_lastUsedRange == null && _ranges.isEmpty) {
      _singleReqRange();
      _printlog("error: 无可用id号段");
      return SyncNode.genId();
    }
    if (_lastUsedRange == null && _ranges.isNotEmpty) {
      _lastUsedRange = _ranges.removeAt(0);
      _lastUsedId = _lastUsedRange!.start;
    }
    //剩余节点号快要耗尽，请求新的号段，请求需要时间，所以需要仔细调节 threshold 的值
    if ((_lastUsedRange!.end - _lastUsedId) < threshold && _ranges.isEmpty) {
      _singleReqRange();
    }

    //此时已经出问题了，说明 threshold 太小了, 本号段耗尽，下一个可用号段还没准备好
    if (_lastUsedId >= _lastUsedRange!.end && _ranges.isEmpty) {
      _singleReqRange();
      _printlog("error: id号段获取异常，threshold 太小了, 本号段耗尽，下一个可用号段还没准备好");
      return SyncNode.genId();
    }

    //当前号段使用完，切换到下一个号段，并且一定有下一个可用号段
    if (_lastUsedId >= _lastUsedRange!.end) {
      _lastUsedRange = _ranges.removeAt(0);
      _lastUsedId = _lastUsedRange!.start;
    }

    return _lastUsedId++;
  }

  Future<RangeId?> _singleReqRange({bool? preAlloc, int? len}) async {
    if (_duraingReqRange && preAlloc != true) {
      return Future.value(null);
    }
    _duraingReqRange = true;
    final future = getRangeIdAutoUrl(document_id, len ?? step, env);
    future.whenComplete(() => _duraingReqRange = false);
    future.then((value) {
      if (value != null) {
        _ranges.add(value);
      }
    });
    return future;
  }

  @override
  int allowId() {
    return _genId();
  }

  @override
  int cacheLen() {
    int len = 0;
    for (var block in _ranges) {
      len += (block.end - block.start);
    }
    if (_lastUsedRange != null) {
      final delta = _lastUsedRange!.end - _lastUsedId;
      if (delta > 0) {
        len += delta;
      }
    }

    return len;
  }

  @override
  Future preAllow(int len) {
    if (len < step) {
      len = step;
    }
    return _singleReqRange(preAlloc: true, len: len);
  }
}

class RangeId {
  final String document_id;
  final int start;
  final int end;
  RangeId(this.document_id, this.start, this.end);
}

Future<RangeId?> getRangeIdAutoUrl(String documentId, int len, Env env) async {
  final baseServerUrl = env.docCenterUrl;
  final rangeIdUrl =
      '${baseServerUrl}/v0.1/visitor/connect/seq/get_seq_start/${documentId}/$len';
  _printlog("req seq start: $rangeIdUrl");
  try {
    Response response =
        await Dio(BaseOptions(receiveDataWhenStatusError: true)).get(
      rangeIdUrl,
      options: Options(
        followRedirects: true,
        responseType: ResponseType.json,
        headers: {
          'Cache-Control': 'no-cache',
          'Sdp-App-Id': getSdpAppId(env),
        },
      ),
    );

    if (response.statusCode != 200) {
      return null;
    }
    final params = response.data as Map;
    final document_id = params['document_id'];
    final start = params['start'];
    final rangeId = RangeId(document_id, start, start + len);
    _printlog("rangeId:${rangeId.start}-${rangeId.end}");
    return rangeId;
  } on DioError catch (e) {
    _printlog("getRangeIdAutoUrl.DioError:${e.response}");
  } catch (e) {
    _printlog("getRangeIdAutoUrl:${e.toString()}");
  }
  return null;
}
