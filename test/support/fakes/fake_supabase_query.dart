import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Fake filter builder générique qui implémente PostgrestFilterBuilder<T>.
///
/// - Chainable: eq(), lte(), order(), in_() retournent le même builder.
/// - Thenable: permet `await query` via then().
/// - maybeSingle(): géré via noSuchMethod pour le fallback snapshot.
class FakeFilterBuilder<T> implements PostgrestFilterBuilder<T> {
  FakeFilterBuilder(this._result);

  final T _result;

  @override
  PostgrestFilterBuilder<T> eq(String column, Object? value) => this;

  @override
  PostgrestFilterBuilder<T> lte(String column, dynamic value) => this;

  @override
  PostgrestFilterBuilder<T> order(
    String column, {
    bool ascending = true,
    bool? nullsFirst,
    String? foreignTable,
  }) =>
      this;

  @override
  FakeFilterBuilder<T> in_(String column, List values) {
    return this;
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(T value) onValue, {
    Function? onError,
  }) {
    return Future<T>.value(_result).then(onValue, onError: onError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Gérer maybeSingle() pour le fallback snapshot
    if (invocation.isMethod && invocation.memberName == #maybeSingle) {
      final dynamic v = _result;

      if (v is List) {
        if (v.isEmpty) {
          return FakeFilterBuilder<Map<String, dynamic>?>(null) as dynamic;
        }
        return FakeFilterBuilder<Map<String, dynamic>?>(
          v.first as Map<String, dynamic>?,
        ) as dynamic;
      }

      return FakeFilterBuilder<Map<String, dynamic>?>(
        v as Map<String, dynamic>?,
      ) as dynamic;
    }
    return super.noSuchMethod(invocation);
  }
}

/// Wrapper pour from() qui implémente SupabaseQueryBuilder.
class FakeSupabaseTableBuilder implements SupabaseQueryBuilder {
  FakeSupabaseTableBuilder(this.rowsToReturn);

  final List<Map<String, dynamic>> rowsToReturn;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Intercepter select<T>() et retourner le filterBuilder typé
    if (invocation.isMethod && invocation.memberName == #select) {
      if (invocation.typeArguments.isNotEmpty) {
        return FakeFilterBuilder<List<Map<String, dynamic>>>(
          rowsToReturn as dynamic,
        ) as dynamic;
      }
      return FakeFilterBuilder<List<Map<String, dynamic>>>(
        rowsToReturn as dynamic,
      );
    }

    // Pour toutes les autres méthodes/getters, retourner this
    if (invocation.isGetter || invocation.isMethod) {
      return this;
    }

    throw UnimplementedError(
      'Méthode non implémentée: ${invocation.memberName}',
    );
  }
}

/// Fake Supabase client qui retourne des données contrôlées via from(view/table).
class FakeSupabaseClient extends SupabaseClient {
  final Map<String, List<Map<String, dynamic>>> _viewData = {};
  String? capturedViewName;
  final List<String> fromCalls = [];

  FakeSupabaseClient() : super('https://example.com', 'anon-key');

  void setViewData(String viewName, List<Map<String, dynamic>> data) {
    _viewData[viewName] = data;
  }

  @override
  SupabaseQueryBuilder from(String viewName) {
    fromCalls.add(viewName);
    capturedViewName = viewName;
    final rows = _viewData[viewName] ?? [];
    return FakeSupabaseTableBuilder(rows);
  }
}
