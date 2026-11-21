# Muuvelo (versión ABP – Entrega final)

App Flutter para **dividir la cuenta de un restaurante según lo que cada persona consumió** y llevar el control de quién ya pagó.

Esta es la versión final de la actividad: parte de la entrega de la Unidad 2 (en memoria, tag `unidad2-entrega`) y agrega:

- **Autenticación** con correo y contraseña (Supabase Auth).
- **Persistencia remota** en PostgreSQL (Supabase) con 4 tablas protegidas por **Row Level Security**.
- **CRUD completo** de vacas (crear, consultar, editar, eliminar) contra la base de datos real.
- **Sincronización** app ⇄ base de datos con indicador visible de estado.
- Interfaz con estética iOS (Apple Human Interface Guidelines): fondo agrupado, secciones blancas, títulos grandes, controles Cupertino y barra de pestañas flotante tipo "vidrio".

---

## 1. El problema

Varios amigos comen juntos, una persona paga toda la cuenta y después pasa días cobrando por WhatsApp. Dividir "en partes iguales" es injusto y hacer las cuentas a mano con ítems compartidos y propina produce errores de redondeo.

**Muuvelo resuelve dos cosas:**

1. **Reparto justo por ítems.** Cada ítem se asigna a quienes lo consumieron (si lo compartieron 3, cada uno paga 1/3). La propina se reparte en proporción a lo consumido. El residuo de redondeo lo asume el anfitrión, así que **la suma siempre es exactamente el total** (todo en pesos `int`, nunca `double`).
2. **Seguimiento de pagos.** El anfitrión marca quién pagó y ve "el vaso" llenarse. Puede cerrar la cuenta aunque falte alguien.

---

## 2. Pantallas (6 + autenticación)

| # | Pantalla | Archivo | Qué hace |
|---|---|---|---|
| 0 | **Autenticación** | `lib/screens/login_screen.dart` | Correo (teclado de correo) y contraseña (con mostrar/ocultar), validación, botón **Iniciar sesión**, error claro en español ("Correo o contraseña incorrectos."), modo **Crear cuenta** (si el proyecto exige confirmar el correo muestra "Te enviamos un correo para confirmar tu cuenta"). |
| 1 | **Inicio** | `lib/screens/home_screen.dart` | Saludo con el correo del usuario, indicador de sincronización, tarjeta **Por cobrar** (total pendiente y vacas abiertas), accesos a todas las funciones y la vaca activa. |
| 2 | **Listado** ("Mis vacas") | `lib/screens/vacas_list_screen.dart` | Vacas leídas de la base de datos, búsqueda por restaurante, filtro **Todas / Abiertas / Cerradas**, deslizar hacia abajo para sincronizar, estados de carga (esqueleto), error con **Reintentar** y vacío. |
| 3 | **Registro** | `lib/screens/register_screen.dart` | Formulario (restaurante, personas, anfitrión, ítems con quién los compartió, propina, vista previa en vivo). **Calcular y guardar** calcula el reparto con `split_service` y lo inserta en Supabase. Luego muestra la pantalla de éxito. |
| 4 | **Detalle** | `lib/screens/vaca_detail_screen.dart` | Toda la información de una vaca: "Recogido $ Y de $ Z" + "Faltan $ X por cobrar", ítems con quién los compartió, participantes con monto y estado de pago. Acciones: **Editar**, **Eliminar** (con confirmación) y **Gestionar cobro**. |
| 5 | **Edición** | `lib/screens/edit_screen.dart` | El mismo formulario precargado. Permite cambiar restaurante, propina, ítems (agregar, quitar, editar precio, reasignar personas) y nombres de participantes. Al guardar recalcula el reparto y actualiza la base de datos. |
| 6 | **Gestión de cobro** (funcionalidad principal) | `lib/screens/results_screen.dart` | El vaso con el % recogido, monto por persona, interruptor **Pagó** (guarda `paid` y `paid_at`), **Compartir resumen** y **Cerrar cuenta** (guarda `status = 'cerrada'` y `closed_at`). |
| + | Pestaña **Cobros** | `lib/screens/cobros_screen.dart` | Atajo a la funcionalidad principal: solo vacas abiertas con lo que falta. |
| + | **Éxito** | `lib/screens/success_screen.dart` | Confirma qué pasó (vaca guardada / cuenta cerrada), para quién, cuánto y cuándo, con **Compartir resumen** (`share_plus`). |

**Navegación.** Tras iniciar sesión se ve `MainShell` (`lib/screens/main_shell.dart`) con una **barra de pestañas flotante** (Inicio, Mis vacas, Nueva, Cobros) y un botón redondo con el logo que abre el perfil (correo + **Cerrar sesión** con confirmación). Detalle, Edición, Gestión y Éxito se abren encima con transición iOS (deslizar para volver). Rutas con nombre en `lib/main.dart`.

Flujo de la demostración: **Autenticación → Consulta (Mis vacas) → Registro → Detalle → Edición → Eliminación → Sincronización**.

---

## 3. Arquitectura

Se mantiene la estructura del curso:

```
lib/
  main.dart            Inicializa Supabase, puerta de autenticación, rutas
  models/              Vaca, Participant, BillItem, VacaDraft, money, split_result (+ fromJson / toJson)
  services/
    auth_service.dart          AuthService (interfaz) + SupabaseAuthService
    vaca_repository.dart       VacaRepository (interfaz) + SupabaseVacaRepository: TODAS las consultas a Supabase
    vaca_sync_controller.dart  Estado sincronizado (lista, cargando, error, última sincronización)
    split_service.dart         Cálculo puro del reparto (sin cambios)
  screens/             Contenedores: estado y reglas, llaman a servicios
  widgets/             Presentacionales: solo dibujan y avisan eventos
  utils/               Tokens de diseño, tema, validadores, mensajes de error, fechas, configuración
```

- **Contenedor / presentacional:** las pantallas nunca llaman a Supabase; hablan con `VacaSyncController`, que usa `VacaRepository`. Los widgets reciben datos y callbacks.
- **Inyección por constructor:** `MuuveloApp(auth:, createRepository:)`. Las pruebas pasan servicios falsos en memoria y nunca tocan la red.
- **Errores:** `utils/error_messages.dart` (`friendlyError`) traduce `AuthException`, `PostgrestException`, `SocketException` y `TimeoutException` a mensajes en español ("Sin conexión. Revisa tu internet.", "No tienes permiso para ver esto.", ...). Se muestran en SnackBars o en un `ErrorView` con **Reintentar**.

---

## 4. Modelo de datos (Supabase / PostgreSQL)

Script: `supabase/migrations/001_muuvelo_schema.sql`.

| Tabla | Columnas principales | Relación |
|---|---|---|
| `muuvelo_vacas` | `id`, `owner_id`, `restaurant_name`, `tip_enabled`, `tip_percent`, `status` (`abierta`/`cerrada`), `created_at`, `updated_at`, `closed_at` | — |
| `muuvelo_participantes` | `id`, `vaca_id`, `owner_id`, `name`, `is_host`, `amount` (pesos, `integer`), `paid`, `paid_at`, `position` | N : 1 con vacas |
| `muuvelo_items` | `id`, `vaca_id`, `owner_id`, `description`, `price` (pesos), `position` | N : 1 con vacas |
| `muuvelo_item_shares` | `item_id`, `participant_id`, `owner_id` | N : M entre ítems y participantes |

Todas las claves foráneas tienen `ON DELETE CASCADE`: eliminar una vaca elimina sus participantes, ítems y repartos.

**CRUD (en `SupabaseVacaRepository`):**

- **Crear:** inserta la vaca, luego participantes (con el monto ya calculado por `split_service`), ítems y la tabla de repartos. Si falla un paso, borra la vaca a medio guardar.
- **Leer:** una sola consulta trae todo con relaciones embebidas: `select('*, muuvelo_participantes(*), muuvelo_items(*, muuvelo_item_shares(participant_id))')`.
- **Actualizar:** actualiza la fila de la vaca, borra sus participantes e ítems y los vuelve a insertar con el reparto recalculado (la estrategia más simple y correcta; el estado "pagó" se conserva). Marcar pagó y cerrar son `update` puntuales.
- **Eliminar:** `delete` de la vaca (cascada).

---

## 5. Seguridad

- **Row Level Security (RLS)** activo en las 4 tablas. Cada política compara `auth.uid()` con `owner_id`: un usuario **solo puede leer, crear, modificar y borrar sus propias filas**.
- `owner_id` tiene valor por defecto `auth.uid()`; la app **nunca lo envía**, así que no puede escribir a nombre de otro.
- El rol `anon` (sin sesión) **no tiene ningún privilegio** sobre las tablas.
- `lib/utils/supabase_config.dart` contiene la URL y la **publishable key**. Es pública por diseño (viaja dentro de cualquier app); sin una sesión válida no da acceso a datos gracias a RLS. La clave `service_role` **nunca** está en la app.
- La sesión la guarda `supabase_flutter` en el dispositivo: el usuario sigue conectado al reiniciar la app hasta que pulse **Cerrar sesión**.

---

## 6. Sincronización

`VacaSyncController` (`lib/services/vaca_sync_controller.dart`):

- **App → base de datos:** cada crear, editar, eliminar, marcar pagó y cerrar se escribe de inmediato en Supabase (no hay cambios solo locales).
- **Base de datos → app:** se vuelve a consultar la lista
  - después de cada cambio,
  - al deslizar hacia abajo (pull-to-refresh) en Inicio, Mis vacas, Cobros, Detalle y Gestión,
  - cada vez que la app vuelve a primer plano (`AppLifecycleState.resumed`).
- **Indicador visible** (`widgets/sync_status_badge.dart`): "Sincronizando…" con spinner, "Sincronizado hace un momento / hace 3 min" con nube verde, o "Sin sincronizar · Reintentar" en rojo (tocable).
- Prueba en la demo: editar una fila en el panel de Supabase y deslizar hacia abajo en la app (o salir y volver a entrar) muestra el cambio.

> Realtime (actualización en vivo sin deslizar) no está activado: requiere agregar las tablas a la publicación `supabase_realtime` en la base de datos, cosa que esta entrega no modifica.

---

## 7. Diseño (Cimientos de UI)

- **Tokens** en `lib/utils/design_tokens.dart`: espaciado 4/8/12/16/24/32, **solo dos radios** (10 y 16), escala tipográfica iOS (Large Title 34, Title2 22, Headline 17, Body 17, Subheadline 15, Footnote 13, Caption 12). Colores en `lib/utils/constants.dart`: morado `#5B21D6` solo como acento, neutros iOS, verde/naranja/rojo del sistema para pagó/pendiente/eliminar.
- **Jerarquía:** el dinero es siempre lo más grande de la pantalla (cifras tabulares).
- **Consecuencias visibles:** junto a "Recogido $ Y de $ Z" siempre aparece "Faltan $ X por cobrar".
- **Confirmaciones:** diálogos iOS para cerrar sesión, eliminar y cerrar cuenta; pantalla de éxito después de crear y de cerrar.
- **Iconos personalizables:** `widgets/muuvelo_icon.dart` muestra `assets/icons/<nombre>.png` y, mientras el archivo no exista, un icono Cupertino. Nombres esperados: `tab_home`, `tab_vacas`, `tab_new`, `tab_cobros`, `empty_vacas`, `login_hero`, `glass_full`, `receipt`, `split`, `people`, `paid`, `pending`, `edit`, `lock`, `cloud_sync`. Basta con copiar los PNG en `assets/icons/`.
- **Tipografía:** usa la fuente del sistema. Para usar Inter, copiar los TTF en `assets/fonts/`, declararlos en `pubspec.yaml` (`fonts: - family: Inter`) y cambiar `AppText.family` a `'Inter'`.
- Sin desbordes en un teléfono de 360 dp (las pruebas de widgets corren a ese ancho), `SafeArea` y zonas táctiles ≥ 48 dp.

---

## 8. Cómo ejecutar

Requisitos: Flutter 3.47 o superior (Dart 3.13), un emulador o teléfono Android con internet.

```bash
flutter pub get
flutter run            # Android
flutter test           # pruebas
flutter analyze        # análisis estático
flutter build apk --debug
```

Para entrar, crear una cuenta desde la pantalla de inicio ("¿No tienes cuenta? Crear cuenta"). Si el proyecto de Supabase exige confirmar el correo, abrir el enlace recibido y luego iniciar sesión.

---

## 9. Pruebas

| Archivo | Qué prueba |
|---|---|
| `test/services/split_service_test.dart` | Reparto: residuo al anfitrión, propina proporcional, la suma siempre da el total. |
| `test/models/money_test.dart` | Formato y redondeo de pesos. |
| `test/models/json_mapping_test.dart` | `fromJson` / `toJson` de vaca, participante, ítem y `VacaDraft` (filas de inserción y repartos). |
| `test/utils/error_messages_test.dart` | Traducción de errores a mensajes en español. |
| `test/utils/validators_test.dart` | Validadores del formulario, correo y contraseña. |
| `test/utils/dates_test.dart` | Texto de sincronización y fechas. |
| `test/services/vaca_sync_controller_test.dart` | Sincronización: carga, error y reintento, cambios hechos en la base de datos, mutaciones. |
| `test/screens/login_screen_test.dart` | Validación, credenciales incorrectas, mostrar contraseña, crear cuenta y puerta de autenticación (con `AuthService` falso). |
| `test/screens/register_screen_test.dart` | Errores del formulario, nombres duplicados y registro completo guardado en el repositorio. |
| `test/screens/crud_flow_test.dart` | Listado → Detalle → Edición → Eliminación. |
| `test/screens/results_screen_test.dart` | Marcar pagó (persistido), "Faltan $ X", cierre con confirmación. |
| `test/widgets/custom_widgets_test.dart` | Widgets propios. |
