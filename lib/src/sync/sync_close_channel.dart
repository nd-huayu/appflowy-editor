part of 'NdOnlineController.dart';

class AutoCloseChannel {
  final ndclient.NdClient dartClient;
  final ndclient.NdChannel channel;
  final IDiffSender sender;
  AutoCloseChannel(this.dartClient, this.channel, this.sender);
  void closeChannel() {
    dartClient.close();
    channel.close();
    sender.close();
  }
}
