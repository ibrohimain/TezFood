import '../../../data/services/api_client.dart';
import '../../../domain/models.dart';
import '../../../data/repositories/tez_repository.dart';
import '../../safe_notifier.dart';

class MenuViewModel extends SafeNotifier {
  MenuViewModel(this._repository);

  final TezRepository _repository;

  bool loading = true;
  String? error;
  List<Catalog> catalogs = [];
  List<Product> products = [];
  int? catalogId;
  String query = '';

  List<Product> get visible {
    final text = query.trim().toLowerCase();
    final sorted = [...products]..sort((a, b) {
        final catalogA = _orderOf(a.catalogId);
        final catalogB = _orderOf(b.catalogId);
        if (catalogA != catalogB) return catalogA.compareTo(catalogB);
        return a.name.compareTo(b.name);
      });
    return sorted.where((product) {
      if (catalogId != null && product.catalogId != catalogId) return false;
      if (text.isEmpty) return true;
      final inName = product.name.toLowerCase().contains(text);
      final inFood = product.ingredients.any((item) => item.name.toLowerCase().contains(text));
      return inName || inFood;
    }).toList();
  }

  int _orderOf(int id) {
    for (final catalog in catalogs) {
      if (catalog.id == id) return catalog.sortOrder;
    }
    return 999;
  }

  String catalogName(int id) {
    for (final catalog in catalogs) {
      if (catalog.id == id) return catalog.name;
    }
    return '';
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      catalogs = await _repository.catalogs();
      products = await _repository.products();
    } on ApiException catch (error) {
      this.error = error.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void selectCatalog(int? id) {
    catalogId = id;
    notifyListeners();
  }

  void search(String value) {
    query = value;
    notifyListeners();
  }
}
