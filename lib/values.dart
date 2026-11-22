/// Jerarquía de tipos del evaluador RPN.
///
/// Demuestra el sistema de tipos de Dart 3, utilizando `sealed class` para
/// definir un conjunto finito y exhaustivo de tipos en tiempo de ejecución
/// (`IntValue`, `DoubleValue`, `BoolValue`).
sealed class Value {
  const Value();

  /// Nombre amigable del tipo para mensajes de diagnóstico y el comando `vars`.
  String get typeName;

  /// Valor primitivo subyacente.
  Object get rawValue;
}

/// Representa un valor entero en el evaluador RPN.
final class IntValue extends Value {
  final int value;

  const IntValue(this.value);

  @override
  String get typeName => 'Int';

  @override
  int get rawValue => value;

  @override
  String toString() => value.toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IntValue && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Representa un valor de punto flotante de doble precisión (Float) en el evaluador RPN.
final class DoubleValue extends Value {
  final double value;

  const DoubleValue(this.value);

  @override
  String get typeName => 'Float';

  @override
  double get rawValue => value;

  @override
  String toString() => value.toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DoubleValue && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Representa un valor booleano (Bool) en el evaluador RPN.
final class BoolValue extends Value {
  final bool value;

  const BoolValue(this.value);

  @override
  String get typeName => 'Bool';

  @override
  bool get rawValue => value;

  @override
  String toString() => value.toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BoolValue && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Elementos que pueden residir en la pila de evaluación (`EvaluationStack`).
///
/// Puede ser un valor ya evaluado (`ValueEntry`) o una referencia a un identificador
/// pendiente de resolución o asignación (`VariableEntry`).
sealed class StackEntry {
  const StackEntry();
}

/// Entrada en la pila que almacena un valor concreto.
final class ValueEntry extends StackEntry {
  final Value value;

  const ValueEntry(this.value);

  @override
  String toString() => 'ValueEntry($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ValueEntry && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Entrada en la pila que almacena el nombre de una variable.
///
/// Permite sintaxis postfija para asignación como `x 10 =`, donde `x` se apila
/// inicialmente como identificador antes de resolverse o vincularse a un valor.
final class VariableEntry extends StackEntry {
  final String name;

  const VariableEntry(this.name);

  @override
  String toString() => 'VariableEntry($name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is VariableEntry && name == other.name;

  @override
  int get hashCode => name.hashCode;
}
