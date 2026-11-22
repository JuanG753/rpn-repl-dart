import 'errors.dart';
import 'values.dart';

/// Información descriptiva de una variable activa en memoria.
final class VariableInfo {
  final String name;
  final Value value;
  final String scopeLabel;
  final int scopeLevel;

  const VariableInfo({
    required this.name,
    required this.value,
    required this.scopeLabel,
    required this.scopeLevel,
  });

  @override
  String toString() => '$name: ${value.typeName} = $value ($scopeLabel)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariableInfo &&
          name == other.name &&
          value == other.value &&
          scopeLabel == other.scopeLabel &&
          scopeLevel == other.scopeLevel;

  @override
  int get hashCode => Object.hash(name, value, scopeLabel, scopeLevel);
}

/// Contrato de abstracción para la gestión de alcances y tablas de símbolos.
///
/// Usa `abstract interface class` (introducido en Dart 3) para definir una
/// interfaz pura que solo puede ser implementada (`implements`), no extendida.
abstract interface class ScopeManager {
  /// Profundidad del alcance actual (0 = global, 1..N = locales).
  int get scopeDepth;

  /// Abre un nuevo bloque de alcance local.
  void beginScope();

  /// Cierra el bloque de alcance local más interno.
  void endScope();

  /// Declara o actualiza una vinculación de variable en el alcance actual.
  void define(String name, Value value);

  /// Resuelve el valor de una variable buscando desde el alcance interno al exterior.
  Value? lookup(String name);

  /// Indica si la variable existe en algún nivel de alcance visible.
  bool contains(String name);

  /// Obtiene la lista de variables visibles activas respetando el shadowing.
  List<VariableInfo> get activeVariables;
}

/// Mixin responsable del formateo visual y etiquetas de los niveles de alcance.
///
/// Demuestra la composición de comportamiento desacoplada en Dart mediante mixins.
mixin ScopeFormatter {
  /// Genera el prompt dinámico para la consola interactiva.
  String formatScopePrompt(int depth) {
    if (depth <= 0) {
      return 'rpn> ';
    }
    return 'rpn[local-$depth]> ';
  }

  /// Genera la etiqueta textual del nivel de alcance para el comando `vars`.
  String formatScopeLevel(int depth) {
    if (depth <= 0) {
      return 'global';
    }
    return 'local #$depth';
  }
}

/// Implementación del entorno de ejecución con soporte para múltiples alcances anidados.
///
/// Mantiene una pila de mapas de símbolos `_scopes`. Implementa *shadowing* estricto
/// y gestiona el ciclo de vida de variables locales, permitiendo la recolección
/// de basura de los mapas desapilados al ejecutar `endScope`.
class Environment with ScopeFormatter implements ScopeManager {
  /// Pila de tablas de símbolos. El índice 0 corresponde al alcance global.
  final List<Map<String, Value>> _scopes = [<String, Value>{}];

  @override
  int get scopeDepth => _scopes.length - 1;

  @override
  void beginScope() {
    _scopes.add(<String, Value>{});
  }

  @override
  void endScope() {
    if (_scopes.length <= 1) {
      throw const ScopeException(
        'Operación inválida: no es posible cerrar el alcance global con "end".',
      );
    }
    // Al remover el último mapa, las variables locales dejan de ser alcanzables
    // en el grafo de referencias, quedando disponibles para el GC generacional de Dart.
    _scopes.removeLast();
  }

  @override
  void define(String name, Value value) {
    // Shadowing estricto: toda asignación en el alcance actual escribe en el mapa
    // del alcance más interno (_scopes.last), sin mutar vinculaciones homónimas
    // de alcances superiores o del alcance global.
    _scopes.last[name] = value;
  }

  @override
  Value? lookup(String name) {
    // Resolución léxica: recorre desde el alcance más interno hacia el global.
    for (int i = _scopes.length - 1; i >= 0; i--) {
      final scope = _scopes[i];
      if (scope.containsKey(name)) {
        return scope[name];
      }
    }
    return null;
  }

  @override
  bool contains(String name) => lookup(name) != null;

  @override
  List<VariableInfo> get activeVariables {
    final seen = <String>{};
    final result = <VariableInfo>[];

    // Recorre de más interno a más externo para capturar variables con shadowing
    for (int i = _scopes.length - 1; i >= 0; i--) {
      final scope = _scopes[i];
      for (final entry in scope.entries) {
        if (!seen.contains(entry.key)) {
          seen.add(entry.key);
          result.add(
            VariableInfo(
              name: entry.key,
              value: entry.value,
              scopeLabel: formatScopeLevel(i),
              scopeLevel: i,
            ),
          );
        }
      }
    }

    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }
}
