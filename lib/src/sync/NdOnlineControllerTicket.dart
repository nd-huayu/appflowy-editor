//   {
//   "server": {
//     "id": "62ba7144ba2e5211bc8c3a1d",
//     "name": "开发本地1",
//     "host": "192.168.56.228",
//     "ip": "192.168.56.228",
//     "intranet_ip": "192.168.56.228",
//     "restful_port": "21090",
//     "socket_port": "21080"
//   },
//   "ticket": "tlMr3D7AhBWe7tFTfn5KFB1mrbnzRtdr27zAx70P5j4SurlBy3Sk1x/+0VwfdK07",
//   "connect_id": "62ca69cc356efad8066f2ef4"
// }

part of 'NdOnlineController.dart';

class Server {
  final String id;
  final String name;
  final String host;
  final String ip;
  final String intranet_ip;
  final String restful_port;
  final String socket_port;

  const Server(this.id, this.name, this.host, this.ip, this.intranet_ip,
      this.restful_port, this.socket_port);

  factory Server.fromJson(Map<String, dynamic> params) {
    return Server(
      params['id'],
      params['name'],
      params['host'],
      params['ip'],
      params['intranet_ip'],
      params['restful_port'],
      params['socket_port'],
    );
  }
}

const Permission_OWN = 1;
const Permission_ONLY_READ = 2;
const Permission_Edit = 3;
const Permission_NO = 4;

class Ticketer {
  final Server server;
  final String ticket;
  final int room_id;
  final String connect_id;
  final int permission;
  const Ticketer(
    this.server,
    this.ticket,
    this.room_id,
    this.connect_id,
    this.permission,
  );

  factory Ticketer.fromJson(Map<String, dynamic> params) {
    return Ticketer(
      Server.fromJson(params['server']),
      params['ticket'],
      params['room_id'],
      params['connect_id'],
      params['permission'] ?? Permission_ONLY_READ,
    );
  }
}

class ConnectInfo {
  Ticketer ticketer;
  String documentId;
  String deviceId;
  int userId;
  int platform;

  ConnectInfo(
    this.ticketer,
    this.documentId,
    this.deviceId,
    this.userId,
    this.platform,
  );
}

Future<ConnectInfo?> getTicketAutoUrl(
  String docurl,
  Env env,
  int userId,
  String documentId,
  String deviceId,
  String? user_type,
  String? from,
) async {
  final platform = 1;

  final baseServerUrl = env.docCenterUrl;
  String ticketUrl =
      "${baseServerUrl}/v0.1/visitor/connect/ticket/${userId}/${documentId}?platform=${platform}&identity=${deviceId}&user_type=${user_type}";
  if (from != null) {
    ticketUrl = ticketUrl + "&from=$from";
  }
  logger.w('get ticket:${ticketUrl}');

  try {
    Response response =
        await Dio(BaseOptions(receiveDataWhenStatusError: true)).get(
      ticketUrl,
      options: Options(
        followRedirects: true,
        responseType: ResponseType.json,
        headers: {
          'Cache-Control': 'no-cache',
          'Sdp-App-Id': getSdpAppId(env),
        },
      ),
    );

    logger.w('get ticket response:${response.data}');
    if (response.statusCode != 200) {
      return null;
    }

    final ticketer = Ticketer.fromJson(response.data);
    return ConnectInfo(ticketer, documentId, deviceId, userId, platform);
  } on DioError catch (e) {
    logger.e("getTicketAutoUrl.DioError", e.response);
  } catch (e) {
    logger.e("getTicketAutoUrl", e);
  }
  return null;
}
