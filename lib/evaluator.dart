import 'environment.dart';
import 'errors.dart';
import 'tokens.dart';
import 'values.dart';

/// Pila de evaluación para el motor de Notación Polaca Inversa.
///
/// Encapsula las operaciones LIFO (`push`, `pop`) y provee métodos de alto
/// nivel que retornan **Records** de Dart 3 para operaciones binarias.
class EvaluationStack {
  final List<StackEntry> _items = [];

  /// Inserta una entrada genérica ([ValueEntry] o [VariableEntry]) en el tope de la pila.
  void push(StackEntry entry) {
    _items.add(entry);
  }

  /// Empaqueta e inserta un [Value] concreto como [ValueEntry] en el tope.
  void pushValue(Value value) {
    _items.add(ValueEntry(value));
  }

  /// Empaqueta e inserta el nombre de un identificador como [VariableEntry].
  void pushVariable(String name) {
    _items.add(VariableEntry(name));
  }

  /// Extrae el elemento superior de la pila.
  ///
  /// Lanza [StackUnderflowException] si la pila está vacía.
  StackEntry pop() {
    if (_items.isEmpty) {
      throw const StackUnderflowException(
        'Pila vacía: no se pueden extraer operandos.',
      );
    }
    return _items.removeLast();
  }

  /// Extrae los dos operandos superiores requeridos por un operador binario en RPN.
  ///
  /// En RPN, el tope de la pila corresponde al operando derecho (`right`)
  /// y el elemento inmediatamente anterior al operando izquierdo (`left`).
  ///
  /// Retorna un **Record de Dart 3**: `(StackEntry left, StackEntry right)`,
  /// evidenciando la equivalencia estructural frente a la equivalencia nominal.
  (StackEntry left, StackEntry right) popBinaryOperands(String opName) {
    if (_items.length < 2) {
      throw StackUnderflowException(
        'Stack underflow en operación "$opName": se requieren 2 operandos pero hay ${_items.length}.',
      );
    }
    final right = pop();
    final left = pop();
    return (left, right);
  }

  /// Cantidad actual de elementos en la pila.
  int get length => _items.length;

  /// Indica si la pila no contiene elementos.
  bool get isEmpty => _items.isEmpty;

  /// Indica si la pila contiene uno o más elementos.
  bool get isNotEmpty => _items.isNotEmpty;

  /// Limpia todos los elementos de la pila.
  void clear() => _items.clear();

  /// Vista inmutable de los elementos actuales de la pila (de la base al tope).
  List<StackEntry> get items => List.unmodifiable(_items);
}

/// Resultado de la evaluación de una línea o secuencia de comandos en el REPL.
///
/// Demuestra el uso de parámetros nombrados con valores por defecto en Dart 3.
final class CommandOutcome {
  /// Valor resultante tras evaluar una expresión RPN válida.
  final Value? result;

  /// Mensaje informativo o salida de un comando de entorno (ej. `vars`, `begin`).
  final String? message;

  /// Señal para indicar al bucle REPL que debe finalizar su ejecución.
  final bool shouldExit;

  const CommandOutcome({
    this.result,
    this.message,
    this.shouldExit = false,
  });
}

/// Resuelve una entrada de la pila ([StackEntry]) a su valor concreto ([Value]).
///
/// Si la entrada es un [ValueEntry], retorna directamente su valor.
/// Si es un [VariableEntry], consulta el identificador en el [Environment] recibido.
///
/// Lanza [UndefinedVariableException] si la variable no existe en el entorno.
Value resolveEntry(StackEntry entry, Environment env) {
  switch (entry) {
    case ValueEntry(:final value):
      return value;
    case VariableEntry(:final name):
      final resolved = env.lookup(name);
      if (resolved == null) {
        throw UndefinedVariableException(
          'Variable no definida: "$name".',
        );
      }
      return resolved;
  }
}

/// Aplica una operación binaria aritmética o relacional sobre dos valores resueltos.
///
/// Demuestra el uso de `switch` con *pattern matching* exhaustivo sobre un Record
/// ternario `(op, left, right)` en Dart 3, aplicando chequeo de tipos estricto
/// en tiempo de ejecución.
Value applyOperation(OperatorType op, Value left, Value right) {
  return switch ((op, left, right)) {
    // -------------------------------------------------------------------------
    // Operador de Suma (+)
    // -------------------------------------------------------------------------
    (OperatorType.add, IntValue(value: final a), IntValue(value: final b)) =>
      IntValue(a + b),
    (OperatorType.add, IntValue(value: final a), DoubleValue(value: final b)) =>
      DoubleValue(a + b),
    (OperatorType.add, DoubleValue(value: final a), IntValue(value: final b)) =>
      DoubleValue(a + b),
    (OperatorType.add, DoubleValue(value: final a), DoubleValue(value: final b)) =>
      DoubleValue(a + b),

    // -------------------------------------------------------------------------
    // Operador de Resta (-)
    // -------------------------------------------------------------------------
    (OperatorType.subtract, IntValue(value: final a), IntValue(value: final b)) =>
      IntValue(a - b),
    (OperatorType.subtract, IntValue(value: final a), DoubleValue(value: final b)) =>
      DoubleValue(a - b),
    (OperatorType.subtract, DoubleValue(value: final a), IntValue(value: final b)) =>
      DoubleValue(a - b),
    (OperatorType.subtract, DoubleValue(value: final a), DoubleValue(value: final b)) =>
      DoubleValue(a - b),

    // -------------------------------------------------------------------------
    // Operador de Multiplicación (*)
    // -------------------------------------------------------------------------
    (OperatorType.multiply, IntValue(value: final a), IntValue(value: final b)) =>
      IntValue(a * b),
    (OperatorType.multiply, IntValue(value: final a), DoubleValue(value: final b)) =>
      DoubleValue(a * b),
    (OperatorType.multiply, DoubleValue(value: final a), IntValue(value: final b)) =>
      DoubleValue(a * b),
    (OperatorType.multiply, DoubleValue(value: final a), DoubleValue(value: final b)) =>
      DoubleValue(a * b),

    // -------------------------------------------------------------------------
    // Operador de División (/) y control de división por cero
    // -------------------------------------------------------------------------
    (OperatorType.divide, IntValue() || DoubleValue(), IntValue(value: 0)) =>
      throw const ZeroDivisionException('División entera por cero no permitida.'),
    (OperatorType.divide, IntValue() || DoubleValue(), DoubleValue(value: 0.0)) =>
      throw const ZeroDivisionException('División real por cero no permitida.'),
    (OperatorType.divide, IntValue(value: final a), IntValue(value: final b)) =>
      a % b == 0 ? IntValue(a ~/ b) : DoubleValue(a / b),
    (OperatorType.divide, IntValue(value: final a), DoubleValue(value: final b)) =>
      DoubleValue(a / b),
    (OperatorType.divide, DoubleValue(value: final a), IntValue(value: final b)) =>
      DoubleValue(a / b),
    (OperatorType.divide, DoubleValue(value: final a), DoubleValue(value: final b)) =>
      DoubleValue(a / b),

    // -------------------------------------------------------------------------
    // Comparaciones Relacionales (<, >)
    // -------------------------------------------------------------------------
    (OperatorType.lessThan, IntValue(value: final a), IntValue(value: final b)) =>
      BoolValue(a < b),
    (OperatorType.lessThan, IntValue(value: final a), DoubleValue(value: final b)) =>
      BoolValue(a < b),
    (OperatorType.lessThan, DoubleValue(value: final a), IntValue(value: final b)) =>
      BoolValue(a < b),
    (OperatorType.lessThan, DoubleValue(value: final a), DoubleValue(value: final b)) =>
      BoolValue(a < b),

    (OperatorType.greaterThan, IntValue(value: final a), IntValue(value: final b)) =>
      BoolValue(a > b),
    (OperatorType.greaterThan, IntValue(value: final a), DoubleValue(value: final b)) =>
      BoolValue(a > b),
    (OperatorType.greaterThan, DoubleValue(value: final a), IntValue(value: final b)) =>
      BoolValue(a > b),
    (OperatorType.greaterThan, DoubleValue(value: final a), DoubleValue(value: final b)) =>
      BoolValue(a > b),

    // -------------------------------------------------------------------------
    // Comparaciones de Igualdad (==, !=) con tipado estricto
    // -------------------------------------------------------------------------
    (OperatorType.equal, IntValue(value: final a), IntValue(value: final b)) =>
      BoolValue(a == b),
    (OperatorType.equal, IntValue(value: final a), DoubleValue(value: final b)) =>
      BoolValue(a == b),
    (OperatorType.equal, DoubleValue(value: final a), IntValue(value: final b)) =>
      BoolValue(a == b),
    (OperatorType.equal, DoubleValue(value: final a), DoubleValue(value: final b)) =>
      BoolValue(a == b),
    (OperatorType.equal, BoolValue(value: final a), BoolValue(value: final b)) =>
      BoolValue(a == b),

    (OperatorType.notEqual, IntValue(value: final a), IntValue(value: final b)) =>
      BoolValue(a != b),
    (OperatorType.notEqual, IntValue(value: final a), DoubleValue(value: final b)) =>
      BoolValue(a != b),
    (OperatorType.notEqual, DoubleValue(value: final a), IntValue(value: final b)) =>
      BoolValue(a != b),
    (OperatorType.notEqual, DoubleValue(value: final a), DoubleValue(value: final b)) =>
      BoolValue(a != b),
    (OperatorType.notEqual, BoolValue(value: final a), BoolValue(value: final b)) =>
      BoolValue(a != b),

    // -------------------------------------------------------------------------
    // Fallback exhaustivo: cualquier otra combinación genera un error de tipos
    // -------------------------------------------------------------------------
    (final op, final l, final r) => throw TypeMismatchException(
      'Error de tipos: el operador "${op.symbol}" no es aplicable entre operandos de tipo ${l.typeName} y ${r.typeName}.',
    ),
  };
}

/// Ejecuta un operador binario sobre la pila de evaluación y el entorno.
///
/// Recibe explícitamente [EvaluationStack] y [Environment], demostrando el paso
/// por referencia de objetos mutables (*call-by-sharing*) en Dart.
void executeBinaryOp(
  OperatorType op,
  EvaluationStack stack,
  Environment env,
) {
  final (leftEntry, rightEntry) = stack.popBinaryOperands(op.symbol);
  final leftValue = resolveEntry(leftEntry, env);
  final rightValue = resolveEntry(rightEntry, env);
  final result = applyOperation(op, leftValue, rightValue);
  stack.pushValue(result);
}

/// Ejecuta la asignación postfija de variable `=` (ej. `x 10 =` o `x 5 2 + =`).
///
/// Extrae el valor a asignar (tope) y el identificador destino (segundo elemento).
/// Actualiza el [Environment] en el alcance actual y vuelve a colocar el valor
/// asignado en la pila para que pueda ser utilizado como resultado de la expresión.
void executeAssignment(
  EvaluationStack stack,
  Environment env,
) {
  if (stack.length < 2) {
    throw const StackUnderflowException(
      'Stack underflow en asignación "=": se requieren un identificador y un valor.',
    );
  }
  final valueEntry = stack.pop();
  final targetEntry = stack.pop();

  if (targetEntry is! VariableEntry) {
    throw const InvalidAssignmentException(
      'El destino de la asignación "=" debe ser un identificador de variable válido.',
    );
  }

  final resolvedValue = resolveEntry(valueEntry, env);
  env.define(targetEntry.name, resolvedValue);
  stack.pushValue(resolvedValue);
}

/// Evalúa una lista de tokens en el contexto de la pila y el entorno dados.
///
/// Demuestra el paso explícito de referencias ([EvaluationStack], [Environment])
/// y la orquestación del análisis semántico en RPN.
CommandOutcome evaluateTokens(
  List<Token> tokens,
  EvaluationStack stack,
  Environment env,
) {
  if (tokens.isEmpty) {
    return const CommandOutcome();
  }

  // Manejo de comandos unitarios del REPL
  if (tokens.length == 1 && tokens.first is CommandToken) {
    final cmd = (tokens.first as CommandToken).commandType;
    switch (cmd) {
      case CommandType.begin:
        env.beginScope();
        return CommandOutcome(
          message: 'Alcance local abierto (nivel #${env.scopeDepth}).',
        );
      case CommandType.end:
        env.endScope();
        final currentLevel =
            env.scopeDepth == 0 ? 'global' : 'nivel #${env.scopeDepth}';
        return CommandOutcome(
          message: 'Alcance local cerrado (alcance activo: $currentLevel).',
        );
      case CommandType.vars:
        final vars = env.activeVariables;
        if (vars.isEmpty) {
          return const CommandOutcome(message: 'No hay variables definidas.');
        }
        final buffer = StringBuffer('Variables activas en memoria:\n');
        for (final v in vars) {
          buffer.writeln('  • ${v.name}: ${v.value.typeName} = ${v.value} (${v.scopeLabel})');
        }
        return CommandOutcome(message: buffer.toString().trimRight());
      case CommandType.clear:
        stack.clear();
        return const CommandOutcome(message: 'Pila de evaluación limpiada.');
      case CommandType.exit:
        return const CommandOutcome(
          message: 'Finalizando sesión de RPN REPL. ¡Hasta pronto!',
          shouldExit: true,
        );
      case CommandType.help:
        return const CommandOutcome(message: _helpMessage);
      case CommandType.assign:
        throw const StackUnderflowException(
          'Stack underflow: el operador de asignación "=" requiere operandos en la pila.',
        );
    }
  }

  // Procesamiento secuencial de tokens en RPN
  for (final token in tokens) {
    switch (token) {
      case NumberToken(:final value, :final isInteger):
        stack.pushValue(
          isInteger ? IntValue(value as int) : DoubleValue(value as double),
        );
      case BooleanToken(:final value):
        stack.pushValue(BoolValue(value));
      case IdentifierToken(:final name):
        stack.pushVariable(name);
      case OperatorToken(:final operatorType):
        executeBinaryOp(operatorType, stack, env);
      case CommandToken(:final commandType):
        switch (commandType) {
          case CommandType.assign:
            executeAssignment(stack, env);
          case CommandType.begin:
            env.beginScope();
          case CommandType.end:
            env.endScope();
          case CommandType.clear:
            stack.clear();
          case CommandType.exit:
            return const CommandOutcome(shouldExit: true);
          case CommandType.vars:
          case CommandType.help:
            // No causan error si aparecen en medio del flujo
            break;
        }
    }
  }

  // Si la pila quedó vacía (por ejemplo, tras un comando o clear)
  if (stack.isEmpty) {
    return const CommandOutcome();
  }

  // Una expresión RPN completa y válida debe dejar exactamente 1 resultado en la pila.
  if (stack.length > 1) {
    final count = stack.length;
    stack.clear();
    throw LeftoverElementsException(
      'Expresión inválida: quedaron $count elementos sobrantes en la pila tras la evaluación.',
    );
  }

  // Extraemos el resultado final y resolvemos si era una referencia de variable
  final topEntry = stack.pop();
  final finalValue = resolveEntry(topEntry, env);
  return CommandOutcome(result: finalValue);
}

const String _helpMessage = '''
Comandos disponibles en RPN REPL:
  • <expr>      : Evalúa una expresión en Notación Polaca Inversa (ej. "5 3 + 2 *")
  • <id> <val> =: Asigna o actualiza una variable (ej. "x 10 =" o "x 5 2 + =")
  • vars        : Lista todas las variables activas, sus tipos, valores y alcances
  • begin       : Abre un nuevo bloque de alcance local (anidable)
  • end         : Cierra el alcance local actual y restaura el alcance previo
  • clear       : Limpia los elementos de la pila de evaluación
  • exit        : Cierra la sesión interactiva del REPL
  • help        : Muestra este mensaje de ayuda''';
