import 'errors.dart';

/// Operadores aritméticos y de comparación soportados por el evaluador RPN.
enum OperatorType {
  add('+'),
  subtract('-'),
  multiply('*'),
  divide('/'),
  equal('=='),
  notEqual('!='),
  lessThan('<'),
  greaterThan('>');

  final String symbol;

  const OperatorType(this.symbol);

  /// Obtiene el [OperatorType] a partir de su símbolo textual o retorna `null` si no coincide.
  static OperatorType? fromSymbol(String symbol) {
    for (final op in OperatorType.values) {
      if (op.symbol == symbol) return op;
    }
    return null;
  }
}

/// Comandos del REPL y operadores de asignación de variables.
enum CommandType {
  vars('vars'),
  begin('begin'),
  end('end'),
  assign('='),
  clear('clear'),
  exit('exit'),
  help('help');

  final String keyword;

  const CommandType(this.keyword);

  /// Obtiene el [CommandType] a partir de su palabra clave o retorna `null` si no coincide.
  static CommandType? fromKeyword(String keyword) {
    for (final cmd in CommandType.values) {
      if (cmd.keyword == keyword) return cmd;
    }
    return null;
  }
}

/// Jerarquía sellada de tokens producidos por el analizador léxico ([tokenize]).
sealed class Token {
  const Token();
}

/// Token numérico (entero o punto flotante).
final class NumberToken extends Token {
  final num value;
  final bool isInteger;

  const NumberToken.integer(int val)
      : value = val,
        isInteger = true;

  const NumberToken.floating(double val)
      : value = val,
        isInteger = false;

  @override
  String toString() => 'NumberToken($value)';
}

/// Token de valor booleano (`true` o `false`).
final class BooleanToken extends Token {
  final bool value;

  const BooleanToken(this.value);

  @override
  String toString() => 'BooleanToken($value)';
}

/// Token que representa un operador aritmético o relacional.
final class OperatorToken extends Token {
  final OperatorType operatorType;

  const OperatorToken(this.operatorType);

  @override
  String toString() => 'OperatorToken(${operatorType.symbol})';
}

/// Token que representa un comando del entorno o asignador (`begin`, `end`, `vars`, `=`, etc.).
final class CommandToken extends Token {
  final CommandType commandType;

  const CommandToken(this.commandType);

  @override
  String toString() => 'CommandToken(${commandType.keyword})';
}

/// Token que representa un identificador de variable (ej. `x`, `total_1`).
final class IdentifierToken extends Token {
  final String name;

  const IdentifierToken(this.name);

  @override
  String toString() => 'IdentifierToken($name)';
}

/// Convierte una línea de entrada de texto en una lista de tokens separando por espacios.
///
/// Lanza [LexicalException] si algún segmento no corresponde a ningún literal,
/// operador, comando o identificador válido.
List<Token> tokenize(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return const [];

  final segments = trimmed.split(RegExp(r'\s+'));
  final tokens = <Token>[];

  final identifierRegex = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');

  for (final segment in segments) {
    // 1. Booleanos literales
    if (segment == 'true') {
      tokens.add(const BooleanToken(true));
      continue;
    }
    if (segment == 'false') {
      tokens.add(const BooleanToken(false));
      continue;
    }

    // 2. Comandos reconocidos y asignación "="
    final command = CommandType.fromKeyword(segment);
    if (command != null) {
      tokens.add(CommandToken(command));
      continue;
    }

    // 3. Operadores aritméticos o relacionales
    final op = OperatorType.fromSymbol(segment);
    if (op != null) {
      tokens.add(OperatorToken(op));
      continue;
    }

    // 4. Números enteros (e.g. 42, -5)
    final intVal = int.tryParse(segment);
    if (intVal != null) {
      tokens.add(NumberToken.integer(intVal));
      continue;
    }

    // 5. Números de punto flotante (e.g. 3.14, -0.5)
    final doubleVal = double.tryParse(segment);
    if (doubleVal != null) {
      tokens.add(NumberToken.floating(doubleVal));
      continue;
    }

    // 6. Identificadores de variables (letras/guión bajo seguido de alfanuméricos)
    if (identifierRegex.hasMatch(segment)) {
      tokens.add(IdentifierToken(segment));
      continue;
    }

    // 7. Carácter o secuencia no permitida
    throw LexicalException(
      'Token léxico no reconocido o inválido: "$segment".',
    );
  }

  return tokens;
}
