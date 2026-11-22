# rpn_repl — Mini-REPL en Notación Polaca Inversa (RPN)

Aplicación de consola interactiva en **Dart 3** (`sdk: ^3.0.0`) para la evaluación de expresiones matemáticas y lógicas en **Notación Polaca Inversa (Postfija / RPN)** basada en una pila.

Este proyecto fue diseñado para la asignatura **CAO604: Lenguajes de Programación** y sirve como evidencia de los 4 pilares fundamentales del diseño del lenguaje Dart:
1. **Nombres, vinculación, control de flujo y alcance:** identificadores, resolución léxica, pila de ámbitos con *shadowing* estricto y comandos `begin`/`end`.
2. **Sistema de tipos y chequeo:** jerarquía con `sealed class`, registros (*records*) para equivalencia estructural frente a la equivalencia nominal, y detección rigurosa de errores de tipo.
3. **Subrutinas, paso de parámetros y manejo de memoria:** paso explícito de referencias (*call-by-sharing*), mutabilidad, parámetros nombrados con valores por defecto y ciclo de vida de objetos con el *Garbage Collector* generacional de Dart.
4. **Abstracción de datos y POO:** nuevos modificadores de clase de Dart 3 (`abstract interface class`, `mixin`, `sealed`, `final`), encapsulamiento e inmutabilidad.

---

## 1. Requisitos previos

- **Dart SDK**: Versión `^3.0.0` (o superior). Verifícalo con:
  ```bash
  dart --version
  ```

---

## 2. Instalación y dependencias

Para descargar las dependencias del proyecto (`test`, `lints`):

```bash
dart pub get
```

---

## 3. Instrucciones de ejecución y compilación

### 3.1. Ejecución interactiva en modo JIT (Just-In-Time)
Para iniciar el REPL en modo desarrollo:

```bash
dart run bin/rpn_repl.dart
```

### 3.2. Compilación a binario nativo AOT (Ahead-Of-Time)
Dart 3 permite compilar directamente a código máquina nativo independiente:

```bash
dart compile exe bin/rpn_repl.dart -o rpn_repl
./rpn_repl
```

### 3.3. Análisis estático de código
Para comprobar la ausencia de advertencias y conformidad con las reglas de estilo de Dart 3:

```bash
dart analyze
```

### 3.4. Ejecución de la suite de pruebas unitarias
Para correr la batería completa de tests automatizados:

```bash
dart test
```

---

## 4. Guía de uso y sesión de prueba en RPN

A continuación se presenta una sesión interactiva representativa que recorre las principales capacidades y el control de errores del evaluador:

```text
================================================================
  Mini-REPL en Notación Polaca Inversa (RPN) — Dart 3
  Asignatura: CAO604 Lenguajes de Programación
  Escribe "help" para ver comandos o "exit" para terminar.
================================================================

# 1. Aritmética entera y precedencia postfija: (5 + 3) * 2 = 16
rpn> 5 3 + 2 *
=> 16

# 2. Operaciones con punto flotante (Float) y tipos mixtos:
rpn> 5 2 /
=> 2.5
rpn> 7.5 2.5 /
=> 3.0

# 3. Comparaciones lógicas y de igualdad:
rpn> 10 2 >
=> true
rpn> 5 5 ==
=> true
rpn> true false !=
=> true

# 4. Declaración y asignación de variables (x = 10):
rpn> x 10 =
=> 10
rpn> x 5 +
=> 15

# 5. Asignación mediante expresión postfija (y = 5 + 2 = 7):
rpn> y 5 2 + =
=> 7
rpn> x y *
=> 70

# 6. Listado de variables activas en memoria:
rpn> vars
Variables activas en memoria:
  • x: Int = 10 (global)
  • y: Int = 7 (global)

# 7. Alcances locales (scoping) y sombreado estricto (shadowing):
rpn> begin
Alcance local abierto (nivel #1).
rpn[local-1]> x 20 =
=> 20
rpn[local-1]> x
=> 20
rpn[local-1]> vars
Variables activas en memoria:
  • x: Int = 20 (local #1)
  • y: Int = 7 (global)

# Anidamiento a nivel 2:
rpn[local-1]> begin
Alcance local abierto (nivel #2).
rpn[local-2]> x 99 =
=> 99
rpn[local-2]> x
=> 99

# Cierre de alcances y restauración de valores previos:
rpn[local-2]> end
Alcance local cerrado (alcance activo: nivel #1).
rpn[local-1]> x
=> 20

rpn[local-1]> end
Alcance local cerrado (alcance activo: global).
rpn> x
=> 10

# 8. Verificación de manejo controlado de errores (sin abortar el REPL):
# Error de tipos:
rpn> 5 true +
Error de ejecución [TypeMismatchException]: Error de tipos: el operador "+" no es aplicable entre operandos de tipo Int y Bool.

# Comparación inválida:
rpn> 5 true ==
Error de ejecución [TypeMismatchException]: Error de tipos: el operador "==" no es aplicable entre operandos de tipo Int y Bool.

# División por cero:
rpn> 10 0 /
Error de ejecución [ZeroDivisionException]: División entera por cero no permitida.

# Stack underflow:
rpn> +
Error de ejecución [StackUnderflowException]: Stack underflow en operación "+": se requieren 2 operandos pero hay 0.

# Variable no definida:
rpn> z 5 +
Error de ejecución [UndefinedVariableException]: Variable no definida: "z".

# Elementos sobrantes en la pila:
rpn> 1 2 3 +
Error de ejecución [LeftoverElementsException]: Expresión inválida: quedaron 2 elementos sobrantes en la pila tras la evaluación.

# Cierre inválido del alcance global:
rpn> end
Error de ejecución [ScopeException]: Operación inválida: no es posible cerrar el alcance global con "end".

# Finalizar la sesión:
rpn> exit
Finalizando sesión de RPN REPL. ¡Hasta pronto!
```

---

## 5. Estructura del Proyecto

```text
rpn_repl/
├── bin/
│   └── rpn_repl.dart            # Bucle interactivo REPL con prompt dinámico
├── lib/
│   ├── environment.dart         # ScopeManager, ScopeFormatter y Environment
│   ├── errors.dart              # Jerarquía sealed de excepciones tipadas
│   ├── evaluator.dart           # EvaluationStack, subrutinas y pattern matching
│   ├── tokens.dart              # Enums, sealed class Token y tokenizer
│   └── values.dart              # sealed class Value, IntValue, DoubleValue, BoolValue, StackEntry
├── test/
│   └── rpn_repl_test.dart       # Suite completa de pruebas unitarias
├── docs/
│   └── reporte_tecnico.md       # Informe técnico académico con citas de código
├── pubspec.yaml                 # Configuración del paquete y dependencias
└── README.md                    # Manual de usuario y documentación general
```
