import 'package:equatable/equatable.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object> get props => [];
}

class LoadProducts extends ProductsEvent {
  const LoadProducts();
}

class LoadProductsByCategory extends ProductsEvent {
  final String category;

  const LoadProductsByCategory(this.category);

  @override
  List<Object> get props => [category];
}

class RefreshProducts extends ProductsEvent {
  const RefreshProducts();
}
