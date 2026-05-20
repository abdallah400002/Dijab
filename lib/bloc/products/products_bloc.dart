import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/product_repository.dart';
import 'products_event.dart';
import 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductRepository _productRepository;

  ProductsBloc(this._productRepository) : super(ProductsInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<LoadProductsByCategory>(_onLoadProductsByCategory);
    on<RefreshProducts>(_onRefreshProducts);
  }

  void _onLoadProducts(LoadProducts event, Emitter<ProductsState> emit) async {
    emit(ProductsLoading());
    try {
      await emit.forEach(
        _productRepository.getAllProducts(),
        onData: (products) => ProductsLoaded(products),
        onError: (error, stackTrace) => ProductsError(error.toString()),
      );
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  void _onLoadProductsByCategory(
    LoadProductsByCategory event,
    Emitter<ProductsState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      await emit.forEach(
        _productRepository.getProductsByCategory(event.category),
        onData: (products) => ProductsLoaded(products),
        onError: (error, stackTrace) => ProductsError(error.toString()),
      );
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  void _onRefreshProducts(
    RefreshProducts event,
    Emitter<ProductsState> emit,
  ) async {
    emit(ProductsLoading());
    add(const LoadProducts());
  }
}
