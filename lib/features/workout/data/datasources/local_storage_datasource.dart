abstract class LocalStorageDataSource {
  Future<void> saveWorkoutJson(Map<String, dynamic> json);
  Future<List<Map<String, dynamic>>> loadWorkoutsJson();
}

class LocalStorageDataSourceImpl implements LocalStorageDataSource {
  final List<Map<String, dynamic>> _mem = [];

  @override
  Future<void> saveWorkoutJson(Map<String, dynamic> json) async {
    _mem.add(json);
  }

  @override
  Future<List<Map<String, dynamic>>> loadWorkoutsJson() async {
    return _mem;
  }
}
