abstract class IntroAudioRepository {
  Future<void> playOnce(String asset);
  Future<void> stop();
  Future<void> dispose();
}
