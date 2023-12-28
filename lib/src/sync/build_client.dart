import 'package:autosync/channel.dart' as ndclient;

ndclient.NdClient buildClient(
  int roomId,
  int userId,
  String connectId,
  String ticket,
  int platform,
  String user_type,
  int aid,
) {
  // final packageInfo = await PackageInfo.fromPlatform();
  final version = '1'; // packageInfo.buildNumber;
  ndclient.UserLoginInfo loginInfo = ndclient.UserLoginInfo(
      connectId, userId, "000000", ticket, user_type, aid);
  ndclient.ClientPlatformInfo platformInfo =
      ndclient.ClientPlatformInfo(version, platform);
  return ndclient.NdDartClient(loginInfo, platformInfo);
}
