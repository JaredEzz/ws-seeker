import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_shared/ws_seeker_shared.dart';
import '../../repositories/product_repository.dart';

// Events
sealed class ProductsEvent {
  const ProductsEvent();
}

final class ProductsFetchRequested extends ProductsEvent {
  final ProductLanguage language;
  const ProductsFetchRequested({required this.language});
}

final class ProductCreateRequested extends ProductsEvent {
  final Map<String, dynamic> data;
  const ProductCreateRequested({required this.data});
}

final class ProductUpdateRequested extends ProductsEvent {
  final String productId;
  final Map<String, dynamic> data;
  const ProductUpdateRequested({required this.productId, required this.data});
}

final class ProductDeleteRequested extends ProductsEvent {
  final String productId;
  const ProductDeleteRequested({required this.productId});
}

// States
sealed class ProductsState {
  const ProductsState();
}

final class ProductsInitial extends ProductsState {
  const ProductsInitial();
}

final class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

final class ProductsLoaded extends ProductsState {
  final List<Product> products;
  final ProductLanguage language;
  const ProductsLoaded({required this.products, required this.language});
}

final class ProductsFailure extends ProductsState {
  final String message;
  const ProductsFailure({required this.message});
}

/// Emitted briefly after a successful create/update/delete, then auto-reloads.
final class ProductActionSuccess extends ProductsState {
  final String message;
  const ProductActionSuccess({required this.message});
}

// BLoC
class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductRepository _productRepository;
  ProductLanguage _lastLanguage = ProductLanguage.japanese;

  ProductsBloc({required ProductRepository productRepository})
      : _productRepository = productRepository,
        super(const ProductsInitial()) {
    on<ProductsFetchRequested>(_onFetchRequested);
    on<ProductCreateRequested>(_onCreateRequested);
    on<ProductUpdateRequested>(_onUpdateRequested);
    on<ProductDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onFetchRequested(
    ProductsFetchRequested event,
    Emitter<ProductsState> emit,
  ) async {
    _lastLanguage = event.language;
    emit(const ProductsLoading());
    try {
      final products = await _productRepository.getProducts(event.language);
      emit(ProductsLoaded(products: products, language: event.language));
    } catch (e) {
      emit(ProductsFailure(message: e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    ProductCreateRequested event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      await _productRepository.createProduct(event.data);
      emit(const ProductActionSuccess(message: 'Product created'));
      // Reload products
      add(ProductsFetchRequested(language: _lastLanguage));
    } catch (e) {
      emit(ProductsFailure(message: e.toString()));
    }
  }

  Future<void> _onUpdateRequested(
    ProductUpdateRequested event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      await _productRepository.updateProduct(event.productId, event.data);
      emit(const ProductActionSuccess(message: 'Product updated'));
      add(ProductsFetchRequested(language: _lastLanguage));
    } catch (e) {
      emit(ProductsFailure(message: e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    ProductDeleteRequested event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      await _productRepository.deleteProduct(event.productId);
      emit(const ProductActionSuccess(message: 'Product deleted'));
      add(ProductsFetchRequested(language: _lastLanguage));
    } catch (e) {
      emit(ProductsFailure(message: e.toString()));
    }
  }
}
