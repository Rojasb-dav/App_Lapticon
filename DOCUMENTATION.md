# 📘 DOCUMENTACIÓN TÉCNICA - LAPTICON

## 📱 Descripción del Proyecto

**Lapticon** es una plataforma móvil desarrollada en **Flutter** para la gestión e integración de servicios de **Viajes y Encomiendas**.

Esta entrega contiene la **arquitectura base completa**, incluyendo la **Autenticación con Firebase Authentication (Email/Contraseña y Google Sign-In)**, el **Registro y Gestión de Perfiles de Usuario** conectado a un backend REST API desplegado en **Render**, selección de roles (**Remitente** / **Viajero**), **Persistencia Automática de Sesión**, y una interfaz moderna con estilo **Glassmorphic UI**, animaciones fluidas a 60 FPS y soporte modular para el desarrollo colaborativo.

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
│       ├── auth_repository.dart     # Capa de datos para Firebase Auth (Login, Registro, Google Sign-In, Reset Pass)
│       ├── user_repository.dart     # Capa de datos para la API REST (GET /api/users/{uid}, POST /api/users/register, PUT /api/users/{uid})
│       └── viaje_repository.dart    # Capa de datos para la gestión y registro de viajes
├── models/
│   ├── user_model.dart              # Modelo de datos de usuario con rol y deserialización JSON tolerante
│   └── viaje_model.dart             # Modelo de datos para las rutas de viaje
├── viewmodels/
│   ├── auth_viewmodel.dart          # ViewModel que gestiona el estado de autenticación y vinculación con Google
│   ├── user_viewmodel.dart          # ViewModel que gestiona la carga y actualización del perfil del usuario
│   ├── role_viewmodel.dart          # ViewModel para la persistencia del rol (Remitente / Viajero)
│   └── viaje_viewmodel.dart         # ViewModel para la gestión de viajes
├── router/
│   └── app_router.dart              # Configuración declarativa de rutas con GoRouter
├── screens/
│   ├── auth/
│   │   ├── splash_screen.dart        # Carga inicial con verificación asíncrona de sesión persistente
│   │   ├── login_screen.dart         # Login con Correo/Contraseña, Google, Recordar correo y recuperar contraseña
│   │   ├── register_screen.dart      # Registro de nuevas cuentas en Firebase Auth y Google Sign-In
│   │   ├── forgot_password_screen.dart # Ventana de envío de correo para recuperación de contraseña
│   │   ├── role_selection_screen.dart # Selección e intercambio de roles (Remitente / Viajero)
│   │   └── complete_profile_screen.dart # Formulario con Lista de Países e inmutabilidad de datos
│   ├── home/
│   │   ├── home_screen.dart          # Contenedor principal con BottomNavigationBar y estado persistente
│   │   └── tabs/
│   │       ├── home_tab.dart         # Panel de bienvenida, datos del usuario, vincular Google, copia de UID y logout
│   │       ├── viajes_tab.dart       # Módulo de consulta de viajes y botón de registro
│   │       └── encomiendas_tab.dart  # Módulo de rastreo y envíos de encomiendas
│   └── viajes/
│       └── registrar_viaje_screen.dart # Formulario para crear y publicar una nueva ruta de viaje
├── widgets/
│   └── lapticon_ui.dart              # Componentes de UI reutilizables estilo Glassmorphic
├── firebase_options.dart             # Opciones de configuración del proyecto de Firebase (lapticon-eba31)
└── main.dart                        # Punto de entrada, inicialización de Firebase y Providers
```

---

## 🔐 Funcionalidades de Autenticación y Seguridad

### 1. **Garantía de Token Fresco**:
En cada solicitud HTTP enviada al backend, `ApiClient` invoca `await FirebaseAuth.instance.currentUser?.getIdToken(true)`. Esto asegura que el token no haya expirado y se adjunte en el encabezado:
`Authorization: Bearer <id_token>`

### 2. **Persistencia Automática de Sesión**:
Firebase Auth almacena de forma nativa en el almacenamiento seguro del dispositivo la sesión activa. En `SplashScreen`, la app espera asíncronamente mediante `FirebaseAuth.instance.authStateChanges().first`. Si el usuario cierra o sale de la app, **la sesión no se finaliza** y al regresar ingresa directamente al Home. La sesión únicamente expira si presiona la opción **Cerrar Sesión**.

### 3. **Recordar Correo Electrónico**:
En la pantalla de Login, se incluye la casilla **"Recordar correo"**. Al marcarla, almacena el correo en `SharedPreferences` para pre-llenarlo en futuros inicios de sesión. Por motivos de seguridad, **la contraseña NUNCA se almacena**.

### 4. **Nacionalidad con Lista Desplegable e Inmutabilidad de Perfil**:
- Al crear la cuenta por primera vez, el usuario elige su país de origen desde una lista desplegable con todos los países de la región (*Ecuador, Colombia, Perú, Venezuela, México, Argentina, Chile, EE. UU., España, etc.*).
- Al editar el perfil posteriormente:
  - 🔒 **`Nombre`**, **`Apellido`** y **`Nacionalidad`** permanecen bloqueados (solo lectura).
  - ✏️ **`Teléfono`** es el único campo editable habilitado para actualizar el contacto.

---

## 🌐 Inicio de Sesión y Vinculación con Google

### **Inicio de Sesión Directo con Google**:
En las pantallas de **Login** y **Registro** se cuenta con el botón **"Continuar con Google"**. Al presionar sobre él, se autentica mediante `google_sign_in` y genera una credencial de OAuth en Firebase.

### **Manejo de Cuentas Existentes y Vinculación**:
1. Si un usuario registró originalmente su cuenta con Correo y Contraseña e intenta usar Google Sign-In con ese mismo correo, Firebase detecta el conflicto (`account-exists-with-different-credential`) y la app le muestra el mensaje explicativo:
   > *"Ya existe una cuenta registrada con este correo electrónico. Inicia sesión con tu contraseña y podrás vincular Google desde tu perfil."*

2. En la pestaña de Inicio (`HomeTab`), el usuario dispone de la sección **"Vincular Cuenta de Google"**:
   - Presiona **"Vincular"** para asociar su cuenta de Google a su perfil de correo/contraseña existente mediante `user.linkWithCredential(credential)`.
   - Una vez vinculada, el estado cambia a **"Cuenta de Google Vinculada"** con un check verde. Desde ese momento, puede iniciar sesión indistintamente con su contraseña o con Google.

---

## 🔑 Configuración de Huellas SHA-1 en Firebase (Guía para Desarrolladores)

Para que el inicio de sesión con Google funcione sin rechazos de seguridad (`ApiException 10`), la Consola de Firebase valida la firma digital SHA-1 con la que se compiló la aplicación.

### **Escenario A: Distribución del APK Generado (`app-debug.apk`)**:
Cuando un integrante del equipo genera el APK y se lo comparte a sus compañeros o usuarios finales para que lo instalen en sus teléfonos:
- La firma digital **ya queda grabada permanentemente dentro del archivo APK**.
- **A todos los usuarios que instalen ese APK les funcionará Google Sign-In en sus celulares sin necesidad de estar conectados a ninguna PC**, siempre que la huella SHA-1 de quien compiló ese APK esté registrada en Firebase Console.

### **Escenario B: Múltiples Desarrolladores Compilando desde sus Laptops**:
Cuando cada integrante del equipo programa y compila la app en su propio Android Studio:
1. Cada desarrollador debe extraer la huella SHA-1 de su propia laptop ejecutando en la terminal:
   ```bash
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```
2. En **[Firebase Console](https://console.firebase.google.com)** -> Proyecto **`lapticon-eba31`** -> **Configuración del Proyecto (⚙️)** -> **Tus Aplicaciones Android** (`com.example.lapticon_clean`).
3. Hacer clic en **"Agregar huella digital"** (*Add fingerprint*). **Firebase permite registrar múltiples huellas SHA-1 en la misma aplicación**.
4. Al agregar las huellas SHA-1 de cada laptop del equipo, la autenticación con Google funcionará perfectamente para todos los desarrolladores mientras trabajan localmente.

---

## 🚀 Guía de Integración para Integrantes del Equipo

La arquitectura está totalmente desacoplada para el trabajo colaborativo:

1. **Módulo de Viajes**:
   - Código localizado en `lib/screens/home/tabs/viajes_tab.dart`, `lib/screens/viajes/registrar_viaje_screen.dart`, `lib/data/repositories/viaje_repository.dart` y `lib/viewmodels/viaje_viewmodel.dart`.
2. **Módulo de Encomiendas**:
   - Código localizado en `lib/screens/home/tabs/encomiendas_tab.dart`.
