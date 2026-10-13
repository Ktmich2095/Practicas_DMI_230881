abstract class VideoStatisticsRepository {
  Future<Map<String, int>> readViewIncrements();
  Future<void> saveViewIncrements(Map<String, int> increments);
}
