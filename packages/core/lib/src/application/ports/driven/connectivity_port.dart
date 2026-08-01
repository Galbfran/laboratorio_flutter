abstract interface class ConnectivityPort {
  Future<bool> isConnected();
  Stream<bool> watchIsConnected();
}
