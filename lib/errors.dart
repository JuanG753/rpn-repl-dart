/// Jerarquía sellada de excepciones tipadas del evaluador RPN.
///
/// Ilustra el uso de `sealed class` y `final class` en Dart 3 para
/// construir jerarquías cerradas y exhaustivas de errores en tiempo de ejecución.
sealed class RpnException implements Exception {
  final String message;

  const RpnException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Error léxico cuando se ingresa un token que no corresponde a ningún literal,
/// operador, comando o identificador válido.
final class LexicalException extends RpnException {
  const LexicalException(super.message);
}

/// Error cuando una operación intenta desapilar más elementos de los existentes.
final class StackUnderflowException extends RpnException {
  const StackUnderflowException(super.message);
}

/// Error cuando se intenta resolver un identificador que no existe en el entorno actual.
final class UndefinedVariableException extends RpnException {
  const UndefinedVariableException(super.message);
}

/// Error cuando los operandos no son compatibles con el operador especificado.
final class TypeMismatchException extends RpnException {
  const TypeMismatchException(super.message);
}

/// Error aritmético por división entre cero (entera o real).
final class ZeroDivisionException extends RpnException {
  const ZeroDivisionException(super.message);
}

/// Error en la gestión de alcances (por ejemplo, intentar cerrar el alcance global con `end`).
final class ScopeException extends RpnException {
  const ScopeException(super.message);
}

/// Error cuando una expresión finaliza dejando múltiples elementos sobrantes sin consumir en la pila.
final class LeftoverElementsException extends RpnException {
  const LeftoverElementsException(super.message);
}

/// Error cuando el destino de una asignación `=` no es un identificador de variable válido.
final class InvalidAssignmentException extends RpnException {
  const InvalidAssignmentException(super.message);
}
