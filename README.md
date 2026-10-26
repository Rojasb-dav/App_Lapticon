# App Lapticon - Base de Autenticación y Registro

Proyecto base en Flutter para la plataforma **Lapticon** implementado con arquitectura **MVVM (Model-View-ViewModel)**, **Firebase Authentication** y consumo de backend REST API.

---

## 🛠️ Stack Técnico

- **Lenguaje**: Dart
- **Framework**: Flutter
- **Estado**: Provider
- **HTTP**: Client personalizado con `http` y refresh forzado de Firebase ID Token (`getIdToken(true)`)
- **Autenticación**: Firebase Authentication (`firebase_auth`)
- **Navegación**: `go_router`
- **Backend URL**: `https://lapticon-backend.onrender.com`

---

## 📁 Arquitectura del Proyecto

```text
lib/
├── data/
│   ├── network/
│   │   ├── api_client.dart            # Cliente HTTP con inserción de Authorization: Bearer <id_token>
│   │   └── api_constants.dart         # Constantes de endpoints
│   └── repositories/
│       ├── auth_repository.dart       # Métodos de Firebase Auth (Login, Register, SignOut)
│       └── user_repository.dart       # Llamadas a /api/users/register y /api/users/{uid}
├── models/
│   └── user_model.dart                # Modelo de datos del perfil de usuario
├── viewmodels/
│   ├── auth_viewmodel.dart            # Estado y operaciones de autenticación de Firebase
│   └── user_viewmodel.dart            # Estado y operaciones del perfil en el backend
├── router/
│   └── app_router.dart                # Configuración de GoRouter
├── screens/
│   ├── auth/
│   │   ├── splash_screen.dart          # Comprueba sesión y estado de perfil
│   │   ├── login_screen.dart           # Login con email y contraseña
│   │   ├── register_screen.dart        # Registro en Firebase
│   │   └── complete_profile_screen.dart# Formulario de Nombre, Apellido, Teléfono y Nacionalidad
│   └── home/
│       ├── home_screen.dart            # Pantalla principal con BottomNavigationBar
│       └── tabs/
│           ├── home_tab.dart           # Perfil del usuario y estado de la app
│           ├── viajes_tab.dart         # Módulo placeholder de Viajes
│           └── encomiendas_tab.dart    # Módulo placeholder de Encomiendas
├── firebase_options.dart               # Opciones de Firebase
└── main.dart                          # Punto de entrada de la aplicación
```

---

## 🔐 Flujo de Autenticación y Backend

1. **SplashScreen**:
   - Revisa si hay un usuario activo con `FirebaseAuth.instance.currentUser`.
   - Si no hay sesión, navega a `/login`.
   - Si hay sesión, llama a `GET /api/users/{uid}` a través de `UserViewModel`.
   - Si el perfil existe en el backend, navega a `/home`. Si no existe o devuelve 404, navega a `/complete-profile`.

2. **LoginScreen & RegisterScreen**:
   - El usuario realiza login o registro con correo + contraseña en Firebase Auth.

3. **CompleteProfileScreen**:
   - El usuario envía `nombre`, `apellido`, `telefono` y `nacionalidad`.
   - Se ejecuta `POST /api/users/register` enviando el token fresco en el header `Authorization: Bearer <id_token>`.

4. **HomeScreen**:
   - Muestra el perfil registrado del usuario y dispone de 3 pestañas en la `BottomNavigationBar` (`Inicio`, `Viajes`, `Encomiendas`) preparadas para la integración de nuevos módulos por parte del equipo.

---

## ⚙️ Configuración de Firebase

Para vincular con tu proyecto de Firebase:
1. Copia tu archivo `google-services.json` dentro de `android/app/`.
2. Si utilizas iOS, descarga `GoogleService-Info.plist` dentro de `ios/Runner/`.
3. Actualiza `lib/firebase_options.dart` si requieres soporte Web/Desktop o claves específicas.
