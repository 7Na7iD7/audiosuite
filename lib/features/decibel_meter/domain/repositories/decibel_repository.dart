abstract interface class DecibelRepository {
  Future<Stream<double>> start();

  Future<void> stop();
}
