import 'package:rpn_repl/environment.dart';
import 'package:rpn_repl/errors.dart';
import 'package:rpn_repl/evaluator.dart';
import 'package:rpn_repl/tokens.dart';
import 'package:rpn_repl/values.dart';
import 'package:test/test.dart';

void main() {
  late Environment env;
  late EvaluationStack stack;

  setUp(() {
    env = Environment();
    stack = EvaluationStack();
  });

  CommandOutcome eval(String input) {
    final tokens = tokenize(input);
    return evaluateTokens(tokens, stack, env);
  }

  group('1. Operaciones Aritméticas (Int y Float)', () {
    test('Suma entera: "3 4 +" => 7', () {
      final outcome = eval('3 4 +');
      expect(outcome.result, equals(const IntValue(7)));
      expect(outcome.result?.typeName, equals('Int'));
    });

    test('Resta entera: "10 4 -" => 6', () {
      final outcome = eval('10 4 -');
      expect(outcome.result, equals(const IntValue(6)));
    });

    test('Multiplicación entera: "6 7 *" => 42', () {
      final outcome = eval('6 7 *');
      expect(outcome.result, equals(const IntValue(42)));
    });

    test('División exacta de enteros: "10 2 /" => 5 (IntValue)', () {
      final outcome = eval('10 2 /');
      expect(outcome.result, equals(const IntValue(5)));
      expect(outcome.result?.typeName, equals('Int'));
    });

    test('División con decimales de enteros: "5 2 /" => 2.5 (DoubleValue)', () {
      final outcome = eval('5 2 /');
      expect(outcome.result, equals(const DoubleValue(2.5)));
      expect(outcome.result?.typeName, equals('Float'));
    });

    test('Operaciones mixtas Int y Float: "5 2.5 +" => 7.5', () {
      final outcome = eval('5 2.5 +');
      expect(outcome.result, equals(const DoubleValue(7.5)));
      expect(outcome.result?.typeName, equals('Float'));
    });

    test('Resta mixta Float e Int: "5.5 2 -" => 3.5', () {
      final outcome = eval('5.5 2 -');
      expect(outcome.result, equals(const DoubleValue(3.5)));
    });

    test('Multiplicación mixta: "4 2.5 *" => 10.0', () {
      final outcome = eval('4 2.5 *');
      expect(outcome.result, equals(const DoubleValue(10.0)));
    });

    test('División entre floats: "7.5 2.5 /" => 3.0', () {
      final outcome = eval('7.5 2.5 /');
      expect(outcome.result, equals(const DoubleValue(3.0)));
    });

    test('Expresión aritmética compleja: "15 7 1 1 + - / 3 * 2 1 1 + + -" => 5', () {
      // (15 / (7 - (1 + 1))) * 3 - (2 + (1 + 1)) = (15 / 5) * 3 - 4 = 9 - 4 = 5
      final outcome = eval('15 7 1 1 + - / 3 * 2 1 1 + + -');
      expect(outcome.result, equals(const IntValue(5)));
    });
  });

  group('2. Comparaciones Lógicas y de Igualdad', () {
    test('Menor que: "3 5 <" => true y "5 3 <" => false', () {
      expect(eval('3 5 <').result, equals(const BoolValue(true)));
      expect(eval('5 3 <').result, equals(const BoolValue(false)));
    });

    test('Mayor que: "10 2 >" => true y "2 10 >" => false', () {
      expect(eval('10 2 >').result, equals(const BoolValue(true)));
      expect(eval('2 10 >').result, equals(const BoolValue(false)));
    });

    test('Comparación numérica mixta: "3 4.5 <" => true', () {
      expect(eval('3 4.5 <').result, equals(const BoolValue(true)));
      expect(eval('5.0 2 >').result, equals(const BoolValue(true)));
    });

    test('Igualdad entera: "5 5 ==" => true y "5 4 ==" => false', () {
      expect(eval('5 5 ==').result, equals(const BoolValue(true)));
      expect(eval('5 4 ==').result, equals(const BoolValue(false)));
    });

    test('Igualdad mixta Int y Float: "5 5.0 ==" => true', () {
      expect(eval('5 5.0 ==').result, equals(const BoolValue(true)));
    });

    test('Desigualdad numérica: "5 4 !=" => true y "5 5 !=" => false', () {
      expect(eval('5 4 !=').result, equals(const BoolValue(true)));
      expect(eval('5 5 !=').result, equals(const BoolValue(false)));
    });

    test('Igualdad y desigualdad booleana: "true true ==" y "true false !="', () {
      expect(eval('true true ==').result, equals(const BoolValue(true)));
      expect(eval('true false ==').result, equals(const BoolValue(false)));
      expect(eval('true false !=').result, equals(const BoolValue(true)));
    });
  });

  group('3. Errores de Tipo (TypeMismatchException)', () {
    test('Suma inválida: "5 true +" lanza TypeMismatchException', () {
      expect(
        () => eval('5 true +'),
        throwsA(isA<TypeMismatchException>()),
      );
    });

    test('Comparación inválida: "true 3 <" lanza TypeMismatchException', () {
      expect(
        () => eval('true 3 <'),
        throwsA(isA<TypeMismatchException>()),
      );
    });

    test('Igualdad entre tipos incompatibles: "5 true ==" lanza TypeMismatchException', () {
      expect(
        () => eval('5 true =='),
        throwsA(isA<TypeMismatchException>()),
      );
    });

    test('Desigualdad entre tipos incompatibles: "false 2.5 !=" lanza TypeMismatchException', () {
      expect(
        () => eval('false 2.5 !='),
        throwsA(isA<TypeMismatchException>()),
      );
    });

    test('División con tipo incompatible y divisor cero: "true 0 /" lanza TypeMismatchException', () {
      expect(
        () => eval('true 0 /'),
        throwsA(isA<TypeMismatchException>()),
      );
    });
  });

  group('4. División por Cero (ZeroDivisionException)', () {
    test('División entera por cero: "10 0 /" lanza ZeroDivisionException', () {
      expect(
        () => eval('10 0 /'),
        throwsA(isA<ZeroDivisionException>()),
      );
    });

    test('División real por cero: "5.0 0.0 /" lanza ZeroDivisionException', () {
      expect(
        () => eval('5.0 0.0 /'),
        throwsA(isA<ZeroDivisionException>()),
      );
    });

    test('División mixta por cero: "5 0.0 /" lanza ZeroDivisionException', () {
      expect(
        () => eval('5 0.0 /'),
        throwsA(isA<ZeroDivisionException>()),
      );
    });
  });

  group('5. Stack Underflow (StackUnderflowException)', () {
    test('Operador sin operandos: "+" lanza StackUnderflowException', () {
      expect(
        () => eval('+'),
        throwsA(isA<StackUnderflowException>()),
      );
    });

    test('Operador binario con un solo operando: "5 +" lanza StackUnderflowException', () {
      expect(
        () => eval('5 +'),
        throwsA(isA<StackUnderflowException>()),
      );
    });

    test('Asignación con un solo operando: "x =" lanza StackUnderflowException', () {
      expect(
        () => eval('x ='),
        throwsA(isA<StackUnderflowException>()),
      );
    });

    test('Asignación sin operandos: "=" lanza StackUnderflowException', () {
      expect(
        () => eval('='),
        throwsA(isA<StackUnderflowException>()),
      );
    });
  });

  group('6. Tokens Inválidos (LexicalException)', () {
    test('Token léxico inválido: "@invalid" lanza LexicalException', () {
      expect(
        () => eval('@invalid'),
        throwsA(isA<LexicalException>()),
      );
    });

    test('Símbolo no soportado en medio de expresión: "5 2 & +" lanza LexicalException', () {
      expect(
        () => eval('5 2 & +'),
        throwsA(isA<LexicalException>()),
      );
    });
  });

  group('7. Asignación y Resolución de Variables', () {
    test('Asignación directa: "x 10 =" define x y retorna 10', () {
      final outcome = eval('x 10 =');
      expect(outcome.result, equals(const IntValue(10)));
      expect(env.lookup('x'), equals(const IntValue(10)));
    });

    test('Asignación con expresión postfija: "x 5 2 + =" define x con 7', () {
      final outcome = eval('x 5 2 + =');
      expect(outcome.result, equals(const IntValue(7)));
      expect(env.lookup('x'), equals(const IntValue(7)));
    });

    test('Uso de variable en cálculo posterior: "x 3 *"', () {
      eval('x 10 =');
      final outcome = eval('x 3 *');
      expect(outcome.result, equals(const IntValue(30)));
    });

    test('Reasignación de variable en el mismo alcance', () {
      eval('x 10 =');
      eval('x 25 =');
      expect(env.lookup('x'), equals(const IntValue(25)));
      final outcome = eval('x 2 +');
      expect(outcome.result, equals(const IntValue(27)));
    });

    test('Variable no definida: "y 5 +" lanza UndefinedVariableException', () {
      expect(
        () => eval('y 5 +'),
        throwsA(isA<UndefinedVariableException>()),
      );
    });

    test('Destino de asignación no válido: "5 10 =" lanza InvalidAssignmentException', () {
      expect(
        () => eval('5 10 ='),
        throwsA(isA<InvalidAssignmentException>()),
      );
    });
  });

  group('8. Comando vars y Formateo de Alcances', () {
    test('vars sin variables muestra mensaje informativo', () {
      final outcome = eval('vars');
      expect(outcome.message, contains('No hay variables definidas.'));
    });

    test('vars lista variables con valor, tipo y etiqueta de alcance', () {
      eval('a 10 =');
      eval('b 3.14 =');
      eval('c true =');
      final outcome = eval('vars');
      expect(outcome.message, contains('• a: Int = 10 (global)'));
      expect(outcome.message, contains('• b: Float = 3.14 (global)'));
      expect(outcome.message, contains('• c: Bool = true (global)'));
    });
  });

  group('9. Alcances Anidados y Shadowing Estricto (begin / end)', () {
    test('Shadowing anidado en 3 niveles de alcance', () {
      // Alcance global (nivel 0)
      eval('x 10 =');
      expect(eval('x').result, equals(const IntValue(10)));
      expect(env.scopeDepth, equals(0));

      // Abre alcance local nivel 1
      eval('begin');
      expect(env.scopeDepth, equals(1));
      expect(env.formatScopePrompt(env.scopeDepth), equals('rpn[local-1]> '));
      // Consulta x antes de hacer shadowing (hereda valor global)
      expect(eval('x').result, equals(const IntValue(10)));

      // Sombra x en nivel 1
      eval('x 20 =');
      expect(eval('x').result, equals(const IntValue(20)));

      // Abre alcance local nivel 2
      eval('begin');
      expect(env.scopeDepth, equals(2));
      expect(env.formatScopePrompt(env.scopeDepth), equals('rpn[local-2]> '));

      // Sombra x en nivel 2
      eval('x 30 =');
      expect(eval('x').result, equals(const IntValue(30)));

      // Comprueba vars en nivel 2 (debe mostrar el x de local #2)
      final varsOutcome2 = eval('vars');
      expect(varsOutcome2.message, contains('• x: Int = 30 (local #2)'));

      // Cierra nivel 2
      eval('end');
      expect(env.scopeDepth, equals(1));
      // Se restaura el valor de nivel 1
      expect(eval('x').result, equals(const IntValue(20)));

      // Cierra nivel 1
      eval('end');
      expect(env.scopeDepth, equals(0));
      expect(env.formatScopePrompt(env.scopeDepth), equals('rpn> '));
      // Se restaura el valor del alcance global original
      expect(eval('x').result, equals(const IntValue(10)));
    });

    test('Error al ejecutar "end" en el alcance global lanza ScopeException', () {
      expect(env.scopeDepth, equals(0));
      expect(
        () => eval('end'),
        throwsA(isA<ScopeException>()),
      );
    });
  });

  group('10. Elementos Sobrantes en Pila (LeftoverElementsException)', () {
    test('Expresión con elementos sobrantes: "5 2 3 +" lanza LeftoverElementsException', () {
      expect(
        () => eval('5 2 3 +'),
        throwsA(isA<LeftoverElementsException>()),
      );
      // La pila debe haberse limpiado automáticamente
      expect(stack.isEmpty, isTrue);
    });

    test('Expresión con 3 números sin operadores: "1 2 3" lanza LeftoverElementsException', () {
      expect(
        () => eval('1 2 3'),
        throwsA(isA<LeftoverElementsException>()),
      );
      expect(stack.isEmpty, isTrue);
    });
  });
}
