import '../../../data/repositories/tez_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../domain/models.dart';
import '../../safe_notifier.dart';

class ProductsViewModel extends SafeNotifier {
  ProductsViewModel(this._repository);

  final TezRepository _repository;

  bool loading = true;
  String? error;
  String query = '';
  List<Catalog> catalogs = [];
  List<Product> products = [];
  Map<int, int> soldToday = {};

  List<Product> get visible {
    final text = query.trim().toLowerCase();
    return products.where((product) {
      if (text.isEmpty) return true;
      return product.name.toLowerCase().contains(text);
    }).toList();
  }

  String catalogName(int id) {
    for (final catalog in catalogs) {
      if (catalog.id == id) return catalog.name;
    }
    return 'Katalogsiz';
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      catalogs = await _repository.catalogs();
      products = await _repository.products();
      final today = DateTime.now();
      final report = await _repository.report(today, today);
      soldToday = {for (final item in report.products) item.productId: item.quantity};
    } on ApiException catch (error) {
      this.error = error.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void search(String value) {
    query = value;
    notifyListeners();
  }

  Future<String?> remove(Product product) async {
    try {
      await _repository.deleteProduct(product.id);
      await load();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }
}
