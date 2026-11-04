# 🚌 App Lapticon - Plataforma de Viajes y Encomiendas

Proyecto en Flutter para la plataforma **Lapticon** implementado con arquitectura **MVVM (Model-View-ViewModel)** con **Provider**, **Firebase Authentication (Email/Password & Google Sign-In)**, consumo de backend REST API en **Render**, selección de roles, persistencia automática de sesión e interfaz **Glassmorphism UI**.

---

## 🛠️ Stack Técnico

- **Lenguaje**: Dart 3.x
- **Framework**: Flutter 3.x
- **Gestión de Estado**: Provider
- **Autenticación**: Firebase Authentication (`firebase_core`, `firebase_auth`, `google_sign_in`)
- **Persistencia Local**: `shared_preferences`
- **Peticiones HTTP**: Client personalizado con `http` e inserción automática de Firebase ID Token fresco (`getIdToken(true)`)
- **Navegación**: `go_router`
- **Backend URL**: `https://lapticon-backend.onrender.com`

---

## 📄 Documentación Técnica Completa

Para conocer todos los detalles de la arquitectura, flujos de autenticación, vinculación con Google, guía de configuración de huella SHA-1 en Firebase e integración para los miembros del equipo, consulta el archivo:

👉 **[DOCUMENTATION.md](./DOCUMENTATION.md)**

---

## ⚙️ Pasos para la Configuración de Google Sign-In en Firebase

Para activar el inicio de sesión con Google en un entorno Android:

1. Obtén tu huella digital **SHA-1** con el comando:
   ```bash
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```
2. Ingresa a **[Firebase Console](https://console.firebase.google.com)** -> Proyecto **`lapticon-eba31`**.
3. Ve a **Configuración del Proyecto (⚙️)** -> **Tus aplicaciones** -> App Android (`com.example.lapticon_clean`).
4. Haz clic en **"Agregar huella digital"** (*Add fingerprint*), pega tu SHA-1 y guarda los cambios.
