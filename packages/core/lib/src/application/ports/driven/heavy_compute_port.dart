abstract interface class HeavyComputePort {
  Future<List<int>> compressImage(String path, {required int quality});
}
