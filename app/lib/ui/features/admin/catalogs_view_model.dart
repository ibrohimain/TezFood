import '../../../data/repositories/tez_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../domain/models.dart';
import '../../safe_notifier.dart';

class CatalogsViewModel extends SafeNotifier {
  CatalogsViewModel(this._repository);

  final TezRepository _repository;

  bool loading = true;
  String? error;
  List<Catalog> catalogs = [];
  Map<int, int> counts = {};

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      catalogs = await _repository.catalogs();
      final products = await _repository.products();
      counts = {};
      for (final product in products) {
        counts[product.catalogId] = (counts[product.catalogId] ?? 0) + 1;
      }
    } on ApiException catch (error) {
      this.error = error.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> create(String name) => _run(() => _repository.createCatalog(name));

  Future<String?> rename(Catalog catalog, String name) {
    return _run(() => _repository.renameCatalog(catalog.id, name));
  }

  Future<String?> remove(Catalog catalog) => _run(() => _repository.deleteCatalog(catalog.id));

  Future<String?> move(Catalog catalog, String direction) {
    return _run(() => _repository.moveCatalog(catalog.id, direction));
  }

  Future<String?> _run(Future<Object?> Function() action) async {
    try {
      await action();
      await load();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }
}
