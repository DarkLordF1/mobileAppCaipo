import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class BaseRepository<T> {
  /// Fetches a single entity by its ID
  Future<Either<Failure, T>> getById(String id);

  /// Fetches a list of entities based on query parameters
  Future<Either<Failure, List<T>>> getList([Map<String, dynamic>? params]);

  /// Creates a new entity
  Future<Either<Failure, T>> create(Map<String, dynamic> data);

  /// Updates an existing entity
  Future<Either<Failure, T>> update(String id, Map<String, dynamic> data);

  /// Deletes an entity by its ID
  Future<Either<Failure, bool>> delete(String id);
} 