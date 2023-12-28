import 'package:universal_html/html.dart';

import 'package:flutter/foundation.dart';

enum Env {
  Unknown,
  Product,
  Preproduction,
  Debug,
  Dev,
  Pressure,
  TestK8s,
  LIY,
  Metting, //网龙会议
  XStudy,
  TestXstudy,
}

final DocCenterServerUrls = {
  Env.Unknown: '{proto}://doc-center.beta.101.com', //大概率是native平台
  Env.Product: '{proto}://doc-center.sdp.101.com',
  Env.Preproduction: '{proto}://doc-center.beta.101.com',
  // Env.Preproduction: '{proto}://doc-center.pre1.ndaeweb.com',
  Env.Debug: '{proto}://doc-center.debug.ndaeweb.com',
  Env.Dev: '{proto}://192.168.56.228:38080',
  Env.Pressure: '{proto}://doc-center.qa.101.com', //压测环境
  Env.TestK8s: '{proto}://testk8s-doc-center.sdp.101.com',
  Env.LIY: '{proto}://192.168.56.132:8080',
  Env.Metting: '{proto}://editor-connect-manage.beta.101.com',
  Env.XStudy: '{proto}://doc-center.ykt.eduyun.cn',
  Env.TestXstudy: '{proto}://doc-center-gray.ykt.eduyun.cn',
};

final CsServerUrls = {
  Env.Product: '{proto}://cdncs.101.com',
  Env.Preproduction: '{proto}://betacs.101.com',
  Env.Unknown: '{proto}://betacs.101.com',
  Env.Dev: '{proto}://betacs.101.com',
  Env.Debug: '{proto}://betacs.101.com',
  Env.XStudy: '{proto}://cdncs.ykt.cbern.com.cn',
  Env.TestXstudy: '{proto}://cdncs.ykt.cbern.com.cn',
  Env.Metting: '{proto}://betacs.101.com',
};

/// 恢复服务接口的 base 地址,
/// 为啥又搞一个? 服务端接口无法复用文档中心服务.
final RecoverServerUrls = {
  Env.Unknown: '{proto}://editor-connect-manage.sdp.101.com', //大概率是native平台
  Env.Product: '{proto}://editor-connect-manage.sdp.101.com',
  Env.Preproduction: '{proto}://editor-connect-manage.beta.101.com',
  Env.Debug: '{proto}://editor-connect-manage.debug.ndaeweb.com',
};
bool isCsUri(Uri? uri) {
  if (uri != null) {
    String host = uri.host;
    if (host.contains('cs.101.com') || host.contains('cs.ykt.cbern.com.cn')) {
      return true;
    }
  }

  return false;
}

bool isCsUrl(String url) => isCsUri(Uri.tryParse(url));

//资源上传环境配置，上传图片音视频的环境
abstract class UploadEnv {
  const UploadEnv();
  String get csTokenUrl {
    if (EnvExtension.isHttps()) {
      return getCsTokenUrl().replaceFirst('{proto}', 'https');
    } else {
      return getCsTokenUrl().replaceFirst('{proto}', 'http');
    }
  }

  String get csPath => getCsPath();
  String get serviceName => getServerName();
  String get uploadUrl {
    if (EnvExtension.isHttps()) {
      return getUploadUrl().replaceFirst('{proto}', 'https');
    } else {
      return getUploadUrl().replaceFirst('{proto}', 'http');
    }
  }

  String get cdnDownloadUrl {
    if (EnvExtension.isHttps()) {
      return getCdnDownloadUrl().replaceFirst('{proto}', 'https');
    } else {
      return getCdnDownloadUrl().replaceFirst('{proto}', 'http');
    }
  }

  String getCsTokenUrl();
  String getCsPath();
  String getServerName();
  String getUploadUrl();
  String getCdnDownloadUrl();
}

class _ProductionUploadEnv extends UploadEnv {
  static _ProductionUploadEnv instance = _ProductionUploadEnv._();
  const _ProductionUploadEnv._();
  @override
  String getCsTokenUrl() =>
      "{proto}://doc-center.sdp.101.com/v0.1/visitor/cs/token";
  @override
  String getCsPath() => '/ndr_4ad_02491e/ppt_message/ppt';
  @override
  String getServerName() => 'ndr_4ad_02491e';
  @override
  String getUploadUrl() => "{proto}://cs.101.com/v0.1/upload";
  @override
  String getCdnDownloadUrl() => "{proto}://cdncs.101.com/v0.1";
}

class _PreproductionUploadEnv extends UploadEnv {
  static _PreproductionUploadEnv instance = _PreproductionUploadEnv._();
  const _PreproductionUploadEnv._();
  @override
  String getCsTokenUrl() =>
      "{proto}://doc-center.beta.101.com/v0.1/visitor/cs/token";
  @override
  String getCsPath() => '/preproduction_ndr_38a_49f75d/ppt_message/ppt';
  @override
  String getServerName() => 'preproduction_ndr_38a_49f75d';
  @override
  String getUploadUrl() => "{proto}://betacs.101.com/v0.1/upload";
  @override
  String getCdnDownloadUrl() => "{proto}://betacs.101.com/v0.1";
}

class _DebugUploadEnv extends _PreproductionUploadEnv {
  static _DebugUploadEnv instance = _DebugUploadEnv._();
  const _DebugUploadEnv._() : super._();
  @override
  String getCsTokenUrl() =>
      "{proto}://doc-center.debug.ndaeweb.com/v0.1/visitor/cs/token";
}

class _MettingUploadEnv extends _PreproductionUploadEnv {
  static _MettingUploadEnv instance = _MettingUploadEnv._();
  const _MettingUploadEnv._() : super._();
}

class _XStudyloadEnv extends UploadEnv {
  static _XStudyloadEnv instance = _XStudyloadEnv._();
  const _XStudyloadEnv._();
  @override
  String getCsTokenUrl() =>
      "{proto}://doc-center.ykt.eduyun.cn/v0.1/visitor/cs/token";

  @override
  String getCdnDownloadUrl() {
    return "{proto}://cdncs.ykt.cbern.com.cn/v0.1";
  }

  @override
  String getCsPath() {
    return "/ndr_2d0_9ee3cd/ppt_message/ppt";
  }

  @override
  String getServerName() {
    return "ndr_2d0_9ee3cd";
  }

  @override
  String getUploadUrl() {
    return "{proto}://sdpcs.ykt.eduyun.cn/v0.1/upload";
  }
}

class _TestXStudyUploadEnv extends _XStudyloadEnv {
  static _TestXStudyUploadEnv instance = _TestXStudyUploadEnv._();
  const _TestXStudyUploadEnv._() : super._();
  @override
  String getCsPath() {
    return "/ndr_2cb_b6f381/ppt_message/ppt";
  }

  @override
  String getServerName() {
    return "ndr_2cb_b6f381";
  }
}

extension EnvExtension on Env {
  static Env fromString(String env) {
    switch (env.toLowerCase()) {
      case "product":
        return Env.Product;
      case "preproduction":
        return Env.Preproduction;
      case "debug":
        return Env.Debug;
      case "dev":
        return Env.Dev;
      case "pressure":
        return Env.Pressure;
      case "testk8s":
        return Env.TestK8s;
      case "liy":
        return Env.LIY;
      case "metting":
        return Env.Metting;
      case "xstudy":
        return Env.XStudy;
      case "testxstudy":
        return Env.TestXstudy;
      default:
        return Env.Unknown;
    }
  }

  static Env autoSelect(String csurl) {
    final superboardUrl = ''; //AppConfig.selfHref;
    final env1 = fromUrl(superboardUrl);
    final env2 = fromCsUrl(csurl);

    if (env1 == Env.Unknown) {
      //大概率是native环境，此时根据cs地址判断
      return env2;
    }

    // if (env2 == Env.Product) {
    //   //生产cs地址，只能连接生产协同服务进行落盘
    //   return env2;
    // }

    return env1;
  }

  static bool isHttps() {
    if (kIsWeb) {
      final location = document.window?.location as Location?;
      if (location?.href.startsWith('https:') == true) {
        return true;
      }
    }
    return false;
  }

  static Env fromUrl(String url) {
    final safeurl = url.toLowerCase();
    if (safeurl.contains("test-superboard.sdp.101.com") ||
        safeurl.contains("test-superboard.sdp.ndaeweb.com")) {
      return Env.TestK8s;
    }
    if (safeurl.contains("dev.ndaeweb.com") || url.contains("172.24.133.103")) {
      return Env.Dev;
    }
    if (safeurl.contains("debug.ndaeweb.com")) {
      return Env.Debug;
    }
    if (safeurl.contains("beta.ndaeweb.com") || url.contains("beta.101.com")) {
      return Env.Preproduction;
    }
    if (safeurl.contains("sdp.101.com")) {
      return Env.Product;
    }
    if (safeurl.contains("ykt.cbern.com.cn")) {
      return Env.XStudy;
    }
    if (safeurl.contains("ykt.eduyun.cn")) {
      return Env.XStudy;
    }
    return Env.Unknown;
  }

  static Env fromCsUrl(String csUrl) {
    final safeurl = csUrl.toLowerCase();
    if (safeurl.contains("ykt.cbern.com.cn")) {
      return Env.XStudy;
    }
    if (safeurl.contains("ykt.eduyun.cn")) {
      return Env.XStudy;
    }
    if (safeurl.contains("betacs.101.com")) {
      return Env.Preproduction;
    }
    if (safeurl.contains("cdncs.101.com") || safeurl.contains("/cs.101.com")) {
      return Env.Product;
    }

    return Env.Unknown;
  }

  String get docCenterUrl {
    final baurl =
        DocCenterServerUrls[this] ?? DocCenterServerUrls[Env.Product]!;
    if (isHttps() || this == Env.Product) {
      return baurl.replaceFirst('{proto}', 'https');
    } else {
      return baurl.replaceFirst('{proto}', 'http');
    }
  }

  String get csBaseUrl {
    final baurl = CsServerUrls[this] ?? CsServerUrls[Env.Product]!;
    if (isHttps()) {
      return baurl.replaceFirst('{proto}', 'https');
    } else {
      return baurl.replaceFirst('{proto}', 'http');
    }
  }

  String get fontCsBaseUrl {
    String baurl = CsServerUrls[Env.Product]!;
    if (this == Env.XStudy) {
      baurl = CsServerUrls[Env.XStudy]!;
    }
    if (isHttps()) {
      return baurl.replaceFirst('{proto}', 'https');
    } else {
      return baurl.replaceFirst('{proto}', 'http');
    }
  }

  UploadEnv get uploadEnv {
    if (this == Env.Product) {
      return _ProductionUploadEnv.instance;
    } else if (this == Env.Debug) {
      return _DebugUploadEnv.instance;
    } else if (this == Env.XStudy) {
      return _XStudyloadEnv.instance;
    } else if (this == Env.TestXstudy) {
      return _TestXStudyUploadEnv.instance;
    } else if (this == Env.Metting) {
      return _MettingUploadEnv.instance;
    }
    return _PreproductionUploadEnv.instance;
  }

  String get recoverBaseUrl {
    final base = RecoverServerUrls[this] ?? RecoverServerUrls[Env.Product]!;
    if (isHttps() || this == Env.Product) {
      return base.replaceFirst('{proto}', 'https');
    } else {
      return base.replaceFirst('{proto}', 'http');
    }
  }
}

String getSdpAppId(Env env) {
  if (env == Env.Product || env == Env.TestK8s) {
    return '0ad3a484-aa38-45eb-ad70-0417317feacd';
  }
  if (env == Env.XStudy || env == Env.TestXstudy) {
    return 'e5649925-441d-4a53-b525-51a2f1c4e0a8';
  }
  return '89b0e510-ae6a-48a6-8c20-606e5aa98666';
}
