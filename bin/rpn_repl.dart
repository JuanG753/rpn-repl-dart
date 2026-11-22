import 'dart:io';
import 'package:rpn_repl/environment.dart';
import 'package:rpn_repl/errors.dart';
import 'package:rpn_repl/evaluator.dart';
import 'package:rpn_repl/tokens.dart';

void main() {
  final env = Environment();
  final stack = EvaluationStack();

  print('================================================================');
  print('  Mini-REPL en Notación Polaca Inversa (RPN) — Dart 3');
  print('  Asignatura: CAO604 Lenguajes de Programación');
  print('  Escribe "help" para ver comandos o "exit" para terminar.');
  print('================================================================');

  while (true) {
    // Prompt dinámico según el nivel de alcance actual
    stdout.write(env.formatScopePrompt(env.scopeDepth));
    final line = stdin.readLineSync();

    // Detección de EOF (Ctrl+D o tubería cerrada)
    if (line == null) {
      print('\n[EOF detectado] Finalizando sesión de RPN REPL. ¡Hasta pronto!');
      break;
    }

    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    try {
      final tokens = tokenize(trimmed);
      final outcome = evaluateTokens(tokens, stack, env);

      if (outcome.message != null) {
        print(outcome.message);
      }

      if (outcome.result != null) {
        print('=> ${outcome.result}');
      }

      if (outcome.shouldExit) {
        break;
      }
    } on RpnException catch (e) {
      // Garantizar que la pila se limpie ante cualquier error en la expresión
      stack.clear();
      print('Error de ejecución [${e.runtimeType}]: ${e.message}');
    } catch (e) {
      stack.clear();
      print('Error no controlado: $e');
    }
  }
}
