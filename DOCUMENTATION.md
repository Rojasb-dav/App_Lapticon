# 📘 DOCUMENTACIÓN TÉCNICA - LAPTICON

## 📱 Descripción del Proyecto

**Lapticon** es una plataforma móvil desarrollada en **Flutter** para la gestión e integración de servicios de **Viajes y Encomiendas**. 

Esta entrega contiene la **arquitectura base completa**, incluyendo la **Autenticación con Firebase Authentication**, el **Registro y Gestión de Perfiles de Usuario** conectado a un backend REST API desplegado en **Render**, y una interfaz moderna con estilo **Glassmorphic UI**, animaciones fluidas y soporte modular para el desarrollo colaborativo.

---

## 🛠️ Stack Técnico

| Componente | Tecnología |
| :--- | :--- |
| **Lenguaje** | Dart 3.x |
| **Framework** | Flutter 3.x |
| **Arquitectura** | MVVM (Model - View - ViewModel) |
| **Gestión de Estado** | Provider |
| **Autenticación** | Firebase Authentication (`firebase_core`, `firebase_auth`) |
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
│       ├── auth_repository.dart     # Capa de datos para Firebase Auth (Login, Registro, Cerrar Sesión)
│       └── user_repository.dart     # Capa de datos para la API REST (GET /api/users/{uid}, POST /api/users/register)
├── models/
│   └── user_model.dart              # Modelo de datos con deserialización JSON tolerante a variaciones
├── viewmodels/
│   ├── auth_viewmodel.dart          # ViewModel que gestiona el estado de autenticación de Firebase
│   └── user_viewmodel.dart          # ViewModel que gestiona la carga y actualización del perfil del usuario
├── router/
│   └── app_router.dart              # Configuración declarativa de rutas con GoRouter
├── screens/
│   ├── auth/
│   │   ├── splash_screen.dart        # Pantalla de carga inicial con comprobación de sesión y perfil
│   │   ├── login_screen.dart         # Inicio de sesión con validaciones e interfaz animada
│   │   ├── register_screen.dart      # Registro de nuevas cuentas en Firebase Auth
│   │   └── complete_profile_screen.dart # Registro y edición de Nombre, Apellido, Teléfono y Nacionalidad
│   └── home/
│       ├── home_screen.dart          # Contenedor con BottomNavigationBar y estado persistente
│       └── tabs/
│           ├── home_tab.dart         # Panel principal: bienvenida, datos del usuario, copia de UID y logout
│           ├── viajes_tab.dart       # Vista placeholder para el Módulo de Viajes (Integrante 2)
│           └── encomiendas_tab.dart  # Vista placeholder para el Módulo de Encomiendas (Integrante 3)
├── firebase_options.dart             # Opciones de configuración del proyecto de Firebase (lapticon-eba31)
└── main.dart                        # Punto de entrada, inicialización de Firebase y Providers
```

---

## 🔐 Flujo de Autenticación y Consumo de API REST

1. **Garantía de Token Fresco**:
   En cada solicitud HTTP enviada al backend, `ApiClient` invoca `await FirebaseAuth.instance.currentUser?.getIdToken(true)`. Esto asegura que el token no haya expirado y se adjunte en el encabezado:
   `Authorization: Bearer <id_token>`

2. **Registro de Usuarios**:
   - El usuario se registra con correo y contraseña en Firebase Auth mediante `RegisterScreen`.
   - Tras crearse la cuenta, es redirigido automáticamente a `CompleteProfileScreen`.
   - Completa su **Nombre**, **Apellido**, **Teléfono** y **Nacionalidad**.
   - Se ejecuta la petición: `POST https://lapticon-backend.onrender.com/api/users/register`.

3. **Inicio de Sesión e Inspección de Perfil**:
   - Al iniciar sesión en `LoginScreen`, `SplashScreen` o `LoginScreen` consultan `GET /api/users/{uid}`.
   - Si el perfil existe en la base de datos, el usuario ingresa directamente al `HomeScreen`.
   - Si no ha registrado su perfil aún, la app lo redirige a completar su información.

4. **Edición de Perfil**:
   - En la pestaña **Inicio** del `HomeScreen`, el usuario cuenta con el botón **"Editar Perfil"**.
   - Puede modificar sus datos personales y presionar **"Guardar Cambios"**, actualizando su perfil en el backend en tiempo real.

---

## 🚀 Guía de Integración para Integrantes del Equipo

La arquitectura está diseñada de forma **de desacoplada e independiente** para que los integrantes del grupo puedan desarrollar sus módulos encima sin interferir en el módulo de Autenticación:

1. **Módulo de Viajes**:
   - Edita el archivo `lib/screens/home/tabs/viajes_tab.dart`.
   - Puedes crear tu propio repositorio en `lib/data/repositories/viajes_repository.dart` y tu ViewModel en `lib/viewmodels/viajes_viewmodel.dart`.
   - Agrega tu Provider en `lib/main.dart` dentro del arreglo `MultiProvider`.

2. **Módulo de Encomiendas**:
   - Edita el archivo `lib/screens/home/tabs/encomiendas_tab.dart`.
   - Crea tu propio repositorio en `lib/data/repositories/encomiendas_repository.dart` y tu ViewModel en `lib/viewmodels/encomiendas_viewmodel.dart`.
   - Agrega tu Provider en `lib/main.dart` dentro del arreglo `MultiProvider`.

---

## ⚙️ Instrucciones de Instalación y Ejecución Local

1. **Clonar el repositorio**:
   ```bash
   git clone <URL_DE_TU_REPOSITTORIO_GITHUB>
   cd App_Lapticon
   ```

2. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

3. **Verificar que no existan errores**:
   ```bash
   flutter analyze
   ```

4. **Ejecutar la aplicación**:
   ```bash
   flutter run
   ```

5. **Generar APK para instalación en dispositivos**:
   ```bash
   flutter build apk --debug
   ```
