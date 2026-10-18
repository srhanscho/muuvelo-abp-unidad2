# Muuvelo (versión ABP – Unidad 2)

App Flutter para **dividir la cuenta de un restaurante según lo que cada persona consumió** y llevar el control de quién ya pagó.

Es una versión reducida y autocontenida de Muuvelo, hecha para la actividad académica:

- Sin backend, sin API, sin base de datos, sin Firebase, sin almacenamiento persistente y sin red.
- Todos los datos viven **en memoria** mientras la app está abierta (variables, listas y estado).
- Solo usa el SDK de Flutter. No tiene paquetes de terceros.

---

## 1. El problema

Varios amigos comen juntos, una persona paga toda la cuenta y después pasa días cobrando por WhatsApp. Dividir "en partes iguales" es injusto (unos piden más que otros) y hacer las cuentas a mano con ítems compartidos y propina lleva a errores de redondeo: la suma de lo que paga cada uno casi nunca da exacto el total.

**Muuvelo resuelve dos cosas:**

1. **Reparto justo por ítems.** Cada ítem se asigna a quienes lo consumieron; si lo compartieron 3 personas, cada una paga 1/3. La propina se reparte en proporción a lo que consumió cada uno. El residuo de redondeo lo asume el anfitrión, así que **la suma siempre es exactamente el total**.
2. **Seguimiento de pagos.** El anfitrión marca quién ya pagó y ve "el vaso" llenarse con el porcentaje recogido. Puede cerrar la cuenta aunque falte alguien (cerrar incompleto es un estado válido).

---

## 2. Las 3 pantallas

| # | Pantalla | Archivo | Qué hace |
|---|---|---|---|
| 1 | **Principal** | `lib/screens/home_screen.dart` | Presenta la app (logo, nombre, lema), explica el problema, botón **Nueva vaca** (va a la pantalla 2), tarjeta **Ver resultados** (va a la pantalla 3; deshabilitada y con explicación si aún no se ha calculado nada) y la lista de vacas calculadas en la sesión (cada una abre la pantalla 3). |
| 2 | **Registro** | `lib/screens/register_screen.dart` | Formulario: restaurante, personas, anfitrión, ítems con quién los compartió, propina, y una vista previa en vivo de subtotal / propina / total. El botón **Calcular reparto** valida todo, procesa y navega a la pantalla 3. |
| 3 | **Consulta y resultados** | `lib/screens/results_screen.dart` | Resumen de la cuenta, el vaso con el % recogido, una tarjeta por persona (monto, ítems con su fracción, casilla "Pagó"), **Copiar resumen** al portapapeles y **Cerrar cuenta** con confirmación. Muestra el estado cerrado. |

Navegación: rutas con nombre en `lib/main.dart` (`/`, `/registro`, `/resultados`). Los diálogos (agregar ítem, confirmar cierre) no son pantallas.

---

## 3. Controles usados

| Control | Dónde (archivo) |
|---|---|
| `TextFormField` (envuelto en `CustomTextField`) | `widgets/custom_text_field.dart`, usado en `register_screen.dart`, `participants_editor.dart`, `add_item_dialog.dart` |
| `Form` + `validator` | `register_screen.dart`, `add_item_dialog.dart` |
| `FilledButton` | `register_screen.dart` (Calcular reparto), `results_screen.dart` (Cerrar cuenta, Volver al inicio), diálogos |
| `OutlinedButton` | `register_screen.dart` (Agregar ítem), `results_screen.dart` (Copiar resumen) |
| `TextButton` | `add_item_dialog.dart`, `confirm_close_dialog.dart` (Cancelar) |
| `IconButton` | `participants_editor.dart` (agregar persona), `bill_item_card.dart` (eliminar ítem) |
| `InputChip` (con borrar) | `participants_editor.dart` |
| `FilterChip` | `bill_item_card.dart` (quién compartió el ítem) |
| `ChoiceChip` | `tip_selector.dart` (10 % / 15 % / 20 %) |
| `Switch` (`SwitchListTile`) | `tip_selector.dart` (Incluir propina) |
| `Slider` | `tip_selector.dart` (propina personalizada 0–30 %) |
| `DropdownButtonFormField` | `host_dropdown.dart` (anfitrión) |
| `Checkbox` | `person_share_card.dart` (Pagó) |
| `ExpansionTile` | `person_share_card.dart` (ver consumo) |
| `AlertDialog` | `add_item_dialog.dart`, `confirm_close_dialog.dart` |
| `SnackBar` | `register_screen.dart` (errores), `results_screen.dart` (pago, cierre, copiado) |
| `ListView` | `home_screen.dart`, `results_screen.dart` |
| `SingleChildScrollView` | `register_screen.dart` |
| `CustomPaint` + `TweenAnimationBuilder` | `glass_progress.dart` |
| `Clipboard`, `HapticFeedback` | `results_screen.dart` |

---

## 4. Componentes personalizados (`lib/widgets/`)

Todos son **presentacionales** (patrón contenedor-presentacional): reciben los datos por constructor, no tienen lógica de negocio ni navegación, y avisan las acciones con callbacks (`onTap`, `onChanged`...). Las pantallas son los "contenedores" que tienen el estado. Cada archivo tiene un solo widget público y un comentario arriba que explica qué es, sus parámetros y dónde se usa.

| Widget | Archivo | Parámetros | Dónde se usa |
|---|---|---|---|
| `CustomTextField` | `custom_text_field.dart` | `label`, `icon`, `controller`, `hint`, `validator`, `errorText`, `keyboardType`, `inputFormatters`, `maxLength`, `textInputAction`, `onSubmitted`, `autofocus` | Registro (restaurante), `ParticipantsEditor` (nombre), `AddItemDialog` (descripción y precio) |
| `GlassProgress` | `glass_progress.dart` | `percent`, `width`, `height`, `showLabel` | `CollectedCard` (vaso grande) y `VacaTile` (vaso pequeño) |
| `AvatarInitials` | `avatar_initials.dart` | `initials`, `size`, `highlighted` | `ParticipantsEditor` (chips) y `PersonShareCard` |
| `MoneyText` | `money_text.dart` | `pesos`, `style` | `SummaryCard`, `CollectedCard`, `PersonShareCard`, `BillItemCard`, `VacaTile` |
| `SectionHeader` | `section_header.dart` | `title`, `trailing` | Las 3 pantallas |
| `SummaryCard` | `summary_card.dart` | `title`, `subtitle`, `subtotal`, `tip`, `tipPercent`, `total` | Registro (vista previa en vivo) y Resultados (resumen) |
| `PersonShareCard` | `person_share_card.dart` | `name`, `initials`, `amount`, `isHost`, `isPaid`, `shares`, `onPaidChanged` | Resultados, una por persona |
| `StatusChip` | `status_chip.dart` | `label`, `color`, `background` | `PersonShareCard`, `VacaTile`, `BillItemCard`, `CollectedCard` |
| `InfoBanner` | `info_banner.dart` | `icon`, `title`, `message`, `color`, `background` | Principal (problema y lista vacía) y Resultados (cuenta cerrada) |
| `ActionCard` | `action_card.dart` | `icon`, `title`, `subtitle`, `onTap` (null = deshabilitada), `highlighted` | Principal: "Nueva vaca" y "Ver resultados" |
| `VacaTile` | `vaca_tile.dart` | `title`, `subtitle`, `collected`, `total`, `percent`, `isClosed`, `onTap` | Principal, una por vaca de la sesión |
| `CollectedCard` | `collected_card.dart` | `collected`, `total`, `percent`, `paidCount`, `peopleCount`, `isClosed` | Resultados (abierta y cerrada) |
| `BillItemCard` | `bill_item_card.dart` | `description`, `price`, `people`, `selectedIds`, `onToggle`, `onDelete`, `showError` | Registro, una por ítem |
| `ParticipantsEditor` | `participants_editor.dart` | `controller`, `participants`, `errorText`, `onAdd`, `onRemove` | Registro |
| `HostDropdown` | `host_dropdown.dart` | `participants`, `hostId`, `onChanged`, `validator` | Registro |
| `TipSelector` | `tip_selector.dart` | `enabled`, `percent`, `presets`, `maxPercent`, `onEnabledChanged`, `onPercentChanged` | Registro |
| `AddItemDialog` | `add_item_dialog.dart` | (sin parámetros; devuelve `(description, price)` al cerrarse) | Registro, botón "Agregar ítem" |
| `ConfirmCloseDialog` | `confirm_close_dialog.dart` | `unpaidNames`, `pendingAmount` | Resultados, botón "Cerrar cuenta" |

**`GlassProgress`** es el componente más elaborado: dibuja a mano un vaso (trapecio con esquinas redondeadas) con un `CustomPainter`, recorta el líquido con la forma del vaso y anima el nivel con `TweenAnimationBuilder` cada vez que alguien paga.

---

## 5. Validaciones

Las reglas están en `lib/utils/validators.dart` como **funciones puras** que devuelven un mensaje de error en español o `null` si el dato es válido (la misma firma que pide `TextFormField.validator`, así que se conectan directo y se prueban con tests unitarios).

| Dato | Regla |
|---|---|
| Restaurante | Obligatorio, entre 2 y 40 caracteres |
| Persona | No vacía, máximo 20 caracteres, sin nombres repetidos (sin importar mayúsculas), máximo 10 personas |
| Personas | Mínimo 2 |
| Anfitrión | Obligatorio (se elige de la lista de personas) |
| Ítem: descripción | Obligatoria, máximo 40 caracteres |
| Ítem: precio | Obligatorio, número entero de pesos (el campo solo acepta dígitos), mayor que 0 y máximo $ 10.000.000 |
| Ítems | Al menos uno, y cada ítem con al menos una persona asignada |

Al tocar **Calcular reparto** se ejecuta `Form.validate()` (errores en rojo bajo cada campo) y además las validaciones personalizadas; el primer problema se muestra también en un `SnackBar`. Después del primer intento, el formulario se revalida mientras el usuario escribe (`AutovalidateMode.onUserInteraction`), así que cada error rojo desaparece apenas se corrige.

---

## 6. Procesamiento (la lógica principal)

Todo el cálculo está en `lib/services/split_service.dart`, en la función pura `calculateSplit` (sin Flutter, sin estado), por eso es fácil de probar:

1. Cada ítem se divide en partes iguales entre quienes lo compartieron, con división entera.
2. La propina se calcula sobre el subtotal, redondeada al peso más cercano solo con enteros: `(subtotal * porcentaje + 50) ~/ 100`.
3. La propina se reparte en proporción a lo que consumió cada uno.
4. Los pesos que sobran por redondeo (en ítems y en propina) los asume el anfitrión. Resultado: **la suma de lo que paga cada uno es exactamente el total**.

El dinero siempre es `int` (pesos colombianos, sin centavos). Nunca se usa `double` para dinero porque no representa los decimales exactos. Formato: `$ 79.200`.

Ejemplo (el de las capturas): Bandeja paisa $ 26.000 (Hans, anfitrión), Limonada de coco $ 7.600 (Camilo), Churrasco $ 20.400 (Valentina), Postre de natas $ 18.000 (los tres), propina 10 % → Hans $ 35.200, Camilo $ 14.960, Valentina $ 29.040. Total $ 79.200 exacto.

**Estado en memoria:** `lib/services/vaca_store.dart` es un `ChangeNotifier` con la lista de vacas de la sesión. Se crea una vez en `main.dart` y se pasa a las pantallas por constructor; las pantallas lo escuchan con `ListenableBuilder` y se redibujan cuando alguien paga o se cierra la cuenta. Se eligió así porque no se permiten paquetes externos (como `provider`) y `ChangeNotifier` viene con Flutter.

---

## 7. Estructura

```
lib/
  main.dart                  entrada, MaterialApp y rutas
  models/                    money, participant, bill_item, vaca, split_result
  services/                  split_service (cálculo puro), vaca_store (lista en memoria)
  screens/                   home_screen, register_screen, results_screen
  widgets/                   componentes personalizados (tabla de arriba)
  utils/                     constants (colores, rutas, límites), app_theme, validators
test/
  models/money_test.dart
  services/split_service_test.dart
  utils/validators_test.dart
  widgets/custom_widgets_test.dart
  screens/register_screen_test.dart
  screens/results_screen_test.dart
evidencias/                  capturas de la app en el emulador
```

---

## 8. Cómo ejecutar

Requisitos: Flutter 3.47 o superior y un emulador o teléfono Android.

```bash
flutter pub get
flutter run             # ejecutar en el emulador o teléfono
flutter test            # 45 pruebas (lógica, validaciones, widgets y pantallas)
flutter analyze         # sin problemas
flutter build apk --debug
```

El APK queda en `build/app/outputs/flutter-apk/app-debug.apk`.

---

## 9. Evidencias

Capturas tomadas en un emulador Pixel 6a, en `evidencias/`:

| Archivo | Qué muestra |
|---|---|
| `01-principal.png` | Pantalla principal sin vacas ("Ver resultados" deshabilitado) |
| `02a-registro-lleno.png` | Registro con los 4 ítems asignados (el postre compartido entre 3) |
| `02b-registro-vista-previa.png` | Propina 10 % y vista previa en vivo: $ 72.000 + $ 7.200 = $ 79.200 |
| `03-registro-errores.png` | Errores en rojo al enviar el formulario vacío |
| `04-resultados.png` | Resultados: resumen, vaso en 0 % y montos por persona (suman $ 79.200) |
| `05-resultados-expandido.png` | Consumo de Camilo abierto: "Limonada de coco" y "Postre de natas (1/3)" |
| `06-resultados-pagado.png` | Hans y Camilo pagaron: el vaso sube a 63 % ($ 50.160) |
| `07-confirmar-cierre.png` | Diálogo de confirmación avisando que falta Valentina ($ 29.040) |
| `08-cuenta-cerrada.png` | Estado cerrado (casillas bloqueadas, "La vaca quedó cerrada") |
| `09-principal-con-vacas.png` | Principal con la vaca de la sesión en la lista |
