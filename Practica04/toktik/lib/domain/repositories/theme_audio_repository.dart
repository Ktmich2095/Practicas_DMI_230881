abstract class ThemeAudioRepository {
  Future<void> play(String asset);
  Future<void> stop();
  Future<void> dispose();
}
