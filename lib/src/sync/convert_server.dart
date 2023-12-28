import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:autosync/channel.dart' as ndclient;

import 'IDocCooperativeApi.dart';
import 'env.dart';
import 'logger.dart';

class ConvertResult {
  ConvertInput input;
  ConvertOutput output;
  ConvertResult({
    required this.input,
    required this.output,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'input': input,
      'output': output,
    };
  }

  factory ConvertResult.fromJson(Map<dynamic, dynamic> params) {
    return ConvertResult(
      input: ConvertInput.fromJson(params['input']),
      output: ConvertOutput.fromJson(params['output']),
    );
  }
}

class ConvertInput {
  DocTypeEnum type;
  String url;
  String filename;
  int filesize;

  ConvertInput({
    required this.type,
    required this.url,
    required this.filename,
    required this.filesize,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'url': url,
      'filename': filename,
      'filesize': filesize,
    };
  }

  factory ConvertInput.fromJson(Map<String, dynamic> params) {
    final type = DocTypeEnum.values.firstWhere(
      (element) => element.name == params['type'],
      orElse: () => DocTypeEnum.DOC_TYPE_UNDEF,
    );
    return ConvertInput(
      type: type,
      url: params['url'] ?? '',
      filename: params['filename'] ?? '',
      filesize: params['filesize'] ?? 0,
    );
  }
}

class ConvertOutput {
  DocTypeEnum type;
  List<String> outfiles;
  List<int>? outsize;
  List<Resolution>? resolutions;

  ConvertOutput({
    required this.type,
    required this.outfiles,
    this.outsize,
    this.resolutions,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'outfiles': outfiles,
      'outsize': outsize,
      'resolutions': resolutions,
    };
  }

  factory ConvertOutput.fromJson(Map<String, dynamic> params) {
    final type = DocTypeEnum.values.firstWhere(
      (element) => element.name == params['type'],
      orElse: () => DocTypeEnum.DOC_TYPE_UNDEF,
    );
    final resolutions = (params['resolutions'] as List?)
        ?.map<Resolution>(
          (e) => Resolution.fromJson(e),
        )
        .toList();

    return ConvertOutput(
      type: type,
      outfiles: (params['outfiles'] as List).cast<String>(),
      outsize: (params['outsize'] as List?)?.cast<int>(),
      resolutions: resolutions,
    );
  }
}

class Resolution {
  int width;
  int height;

  Resolution({required this.width, required this.height});
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'width': width,
      'height': height,
    };
  }

  factory Resolution.fromJson(Map<String, dynamic> params) {
    return Resolution(
      width: params['width'] ?? 0,
      height: params['height'] ?? 0,
    );
  }
}

enum DocTypeEnum {
  DOC_TYPE_UNDEF,
  DOC_TYPE_PDF,
  DOC_TYPE_PPTX,
  DOC_TYPE_WORD,
  DOC_TYPE_THUMBNAIL,
  DOC_TYPE_SUPERBOARD,
  DOC_TYPE_EXERCISE,
  DOC_TYPE_VIDEO_MP4_H264,
}

// //shape层定义的类型到 json 格式种约定的映射
// DocTypeEnum DocType(DocContainerSourceType typeName) {
//   final name = typeName;
//   if (name == DocContainerSourceType.ppt) {
//     return DocTypeEnum.DOC_TYPE_PPTX;
//   } else if (name == DocContainerSourceType.superboard) {
//     return DocTypeEnum.DOC_TYPE_SUPERBOARD;
//   } else if (name == DocContainerSourceType.word) {
//     return DocTypeEnum.DOC_TYPE_WORD;
//   } else if (name == DocContainerSourceType.pdf) {
//     return DocTypeEnum.DOC_TYPE_PDF;
//   } else {
//     assert(false, "未知类型");
//     return DocTypeEnum.DOC_TYPE_UNDEF;
//   }
// }

//服务端要求请求参数用数值，理由是减少数据库存储量，需要重映射字符串到对应的数值
//我佛慈悲
int type2Index(DocTypeEnum docType) {
  switch (docType) {
    case DocTypeEnum.DOC_TYPE_PPTX:
      return 101;
    case DocTypeEnum.DOC_TYPE_PDF:
      return 2;
    case DocTypeEnum.DOC_TYPE_WORD:
      return 1;
    case DocTypeEnum.DOC_TYPE_EXERCISE:
      return 3;
    case DocTypeEnum.DOC_TYPE_THUMBNAIL:
      return 6;
    case DocTypeEnum.DOC_TYPE_SUPERBOARD:
      return 5;
    case DocTypeEnum.DOC_TYPE_VIDEO_MP4_H264:
      return 201;
    default:
      return 0;
  }
}

//发送请求生成视频缩略图
Future<ndclient.ClientCustomMessageAck> convertRequest(
  ndclient.NdDartClient client,
  int id,
  String source,
  DocTypeEnum doc_type,
  String? container_id,
) {
  ndclient.ConvertRequest params = ndclient.ConvertRequest(
    id: id.toString(),
    source: source,
    doc_type: type2Index(doc_type),
    container_id: container_id,
  );
  return ndclient.NdUtils.convertRequest(client, params);
}

Future<ConvertResult?> getConvertResult(
  IDocCooperativeApi doc,
  String resourceId,
) async {
  final env = doc.env;
  if (env == null || doc.roomId == null) {
    return null;
  }
  final baseServerUrl = env.docCenterUrl;
  final roomId = doc.roomId;

  final requestUrl =
      '${baseServerUrl}/v0.1/visitor/rooms/$roomId/node/$resourceId/task_result?task_detail=1';
  print("req convert start: $requestUrl");
  try {
    Response response =
        await Dio(BaseOptions(receiveDataWhenStatusError: true)).get(
      requestUrl,
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
    final status = params['status'] ?? 2;
    if (status != 1) {
      logger.e("getConvertResult result:${json.encode(params)}");
      return null;
    }
    return ConvertResult.fromJson(params);
  } on DioError catch (e) {
    logger.e("getConvertResult.DioError", e.response);
  } catch (e) {
    logger.e("getConvertResult", e);
  }
  return null;
}
