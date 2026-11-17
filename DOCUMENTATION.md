# 📘 DOCUMENTACIÓN TÉCNICA - LAPTICON

## 📱 Descripción del Proyecto

**Lapticon** es una plataforma móvil desarrollada en **Flutter** para la gestión e integración de servicios de **Viajes y Encomiendas**.

Esta entrega contiene la **aplicación funcional completa**, incluyendo la **Autenticación con Firebase Authentication**, el **Registro y Gestión de Perfiles de Usuario** conectado a un backend REST API desplegado en **Render**, selección de roles (**Remitente** / **Viajero**), **Publicación de Encomiendas**, **Registro de Viajes**, **Filtro de Coincidencia de Rutas**, **Aceptación de Encomiendas**, **Chat Directo entre Viajero y Remitente**, **Persistencia Automática de Sesión**, e interfaz moderna estilo **Glassmorphic UI** con animaciones fluidas a 60 FPS.

---

## 🛠️ Stack Técnico

| Componente | Tecnología |
| :--- | :--- |
| **Lenguaje** | Dart 3.x |
| **Framework** | Flutter 3.x |
| **Arquitectura** | MVVM (Model - View - ViewModel) |
| **Gestión de Estado** | Provider |
| **Autenticación** | Firebase Authentication (`firebase_core`, `firebase_auth`, `google_sign_in`) |
| **Persistencia Local** | `shared_preferences` |
| **Navegación** | GoRouter |
| **Peticiones HTTP** | Client personalizado con `http` |
| **Backend REST API** | `https://lapticon-backend.onrender.com` |

---

## 📂 Estructura del Código Fuente

```text
lib/
├── data/
│   ├── network/
│   │   ├── api_client.dart          # Cliente HTTP centralizado con inclusión automática de Bearer ID Token
│   │   └── api_constants.dart       # Endpoints de la API REST de Render
│   └── repositories/
│       ├── auth_repository.dart     # Capa de datos para Firebase Auth (Login, Registro, Google, Reset Pass)
│       ├── user_repository.dart     # Capa de datos para la API REST de usuarios (/api/users)
│       ├── viaje_repository.dart    # Capa de datos para la gestión y registro de viajes (/api/viajes)
│       ├── encomienda_repository.dart# Capa de datos para encomiendas (/api/encomiendas)
│       └── chat_repository.dart     # Capa de datos para interacción y chat directo (/api/chats)
├── models/
│   ├── user_model.dart              # Modelo de datos de usuario con rol y deserialización JSON tolerante
│   ├── viaje_model.dart             # Modelo de datos para las rutas de viaje
│   ├── encomienda_model.dart        # Modelo de encomienda con origen, destino, peso, precio y estado
│   └── chat_model.dart              # Modelo de mensajes del chat entre Viajero y Remitente
├── viewmodels/
│   ├── auth_viewmodel.dart          # ViewModel que gestiona la autenticación y vinculación de cuentas
│   ├── user_viewmodel.dart          # ViewModel que gestiona la carga y actualización del perfil
│   ├── role_viewmodel.dart          # ViewModel para la persistencia del rol (Remitente / Viajero)
│   ├── viaje_viewmodel.dart         # ViewModel para la publicación y consulta de viajes
│   ├── encomienda_viewmodel.dart    # ViewModel para creación, filtrado por ruta y aceptación de encomiendas
│   └── chat_viewmodel.dart          # ViewModel para la gestión del chat en tiempo real
├── router/
│   └── app_router.dart              # Configuración declarativa de rutas con GoRouter
├── screens/
│   ├── auth/
│   │   ├── splash_screen.dart        # Carga inicial con comprobación asíncrona de sesión persistente
│   │   ├── login_screen.dart         # Login con Correo/Contraseña, Recordar correo y recuperar clave
│   │   ├── register_screen.dart      # Registro de nuevas cuentas en Firebase Auth
│   │   ├── forgot_password_screen.dart # Ventana de recuperación de contraseña por correo
│   │   ├── role_selection_screen.dart # Selección e intercambio de roles (Remitente / Viajero)
│   │   └── complete_profile_screen.dart # Formulario con Lista de Países e inmutabilidad de datos
│   ├── home/
│   │   ├── home_screen.dart          # Contenedor principal con BottomNavigationBar y estado persistente
│   │   └── tabs/
│   │       ├── home_tab.dart         # Panel de bienvenida, datos del usuario, copia de UID y logout
│   │       ├── viajes_tab.dart       # Panel del Viajero: viajes activos, filtro por ruta y aceptación
│   │       └── encomiendas_tab.dart  # Panel del Remitente: publicación de encomiendas y estado
│   ├── encomiendas/
│   │   └── crear_encomienda_screen.dart # Formulario para publicar una nueva encomienda
│   ├── viajes/
│   │   └── registrar_viaje_screen.dart # Formulario para publicar una nueva ruta de viaje
│   └── chat/
│       └── chat_screen.dart          # Pantalla de chat directo habilitada tras aceptar la encomienda
├── widgets/
│   └── lapticon_ui.dart              # Componentes de UI reutilizables estilo Glassmorphic
├── firebase_options.dart             # Opciones de configuración del proyecto de Firebase (lapticon-eba31)
└── main.dart                        # Punto de entrada, inicialización de Firebase y Providers
```

---

## 🔐 Módulos Funcionales y Criterios de Evaluación

### 1. **Registro y Perfil de Usuarios (15%)**:
- Autenticación con Firebase Auth (Email y Contraseña).
- Selección e intercambio de roles (**Remitente** / **Viajero**).
- Formulario de perfil con lista desplegable de países para la Nacionalidad.
- **Regla de Inmutabilidad**: Al editar el perfil, `Nombre`, `Apellido` y `Nacionalidad` permanecen bloqueados (solo lectura). Únicamente se permite actualizar el `Teléfono` de contacto.

### 2. **Registro de la Encomienda (15%)**:
- Formulario interactivo `CrearEncomiendaScreen` para el usuario **Remitente**.
- Permite especificar **Origen**, **Destino**, **Descripción**, **Peso**, **Valor a pagar ($)** y **Fecha de Vencimiento/Caducidad**.
- Persistencia enviada al Backend REST API (`POST /api/encomiendas`).

### 3. **Registro del Viaje (15%)**:
- Formulario `RegistrarViajeScreen` para el usuario **Viajero**.
- Permite registrar Origen, Destino, Número de vuelo/vehículo y Fecha.
- Persistencia enviada al Backend REST API (`POST /api/viajes`).

### 4. **Filtro de Coincidencia de Rutas y Aceptación (15%)**:
- **Lógica de Encuentro (El viajero ve al remitente)**: Al seleccionar su viaje en `ViajesTab`, la app **filtra automáticamente mostrando únicamente aquellas encomiendas que coinciden de forma exacta en su ruta (`Origen` ➔ `Destino`)**.
- Acción **"Aceptar Llevar Encomienda"** (`PUT /api/encomiendas/tomar/{id}`): El viajero acepta transportar el paquete.

### 5. **Interacción Directa y Chat Viajero-Remitente (15%)**:
- Se habilita **únicamente después de que el viajero acepta llevar la encomienda**, dando una justificación clara de negocio para comunicarse.
- Pantalla `ChatScreen` para coordinar el punto y hora de entrega.

---

## 🔒 Persistencia y Opciones de Autenticación

1. **Garantía de Token Fresco**:
   En cada solicitud HTTP enviada al backend, `ApiClient` invoca `await FirebaseAuth.instance.currentUser?.getIdToken(true)`.
2. **Persistencia Automática de Sesión**:
   Firebase Auth almacena de forma nativa la sesión. En `SplashScreen`, la app espera asíncronamente mediante `FirebaseAuth.instance.authStateChanges().first`. Si el usuario cierra o sale de la app, **la sesión no finaliza**. Únicamente expira al presionar **Cerrar Sesión**.
3. **Recordar Correo Electrónico**:
   Casilla **"Recordar correo"** en el Login guardada en `SharedPreferences`. La contraseña **NUNCA** se almacena.
4. **Estado de Botones de Google**:
   Los botones de inicio de sesión con Google incluyen una notificación informativa indicando que dicha opción se encuentra en desarrollo por restricciones de la plataforma de Firebase.

---

## 🖼️ Guía para la Personalización del Icono de la App

Para cambiar el icono de la aplicación en dispositivos Android:

1. Coloca la imagen cuadrada de tu icono (en formato PNG de 512x512 px) en la carpeta de recursos.
2. Reemplaza las imágenes `ic_launcher.png` en las siguientes carpetas:
   - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
   - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
   - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
   - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
   - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
3. O bien utiliza el paquete `flutter_launcher_icons` agregándolo a `pubspec.yaml` y ejecutando `flutter pub run flutter_launcher_icons`.
