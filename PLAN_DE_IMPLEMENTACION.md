# Plan de Implementación: Entrega Completa Lapticon

Implementar la totalidad de los requerimientos especificados para la entrega: **Registro de Viaje**, **Registro de Encomienda**, **Filtro de Coincidencia de Rutas (Viajero ve a Remitente)**, **Aceptación de Encomienda** e **Interacción Directa / Chat Viajero-Remitente**.

---

## 🎯 Puntos Clave de la Entrega

- **Filtro de Rutas Estricto**:
  Los viajes y encomiendas utilizan la lista de ciudades autorizadas:
  - **Nacionales**: `Bogotá`, `Cali`, `Medellín`
  - **Internacionales**: `Bogotá`, `Miami`, `Madrid`
  La vista de encomiendas para el viajero filtra automáticamente por la ruta exacta (`origen` y `destino`) de su viaje registrado.

- **Persistencia y Roles**:
  Los usuarios con rol de **Viajero** pueden registrar sus viajes y tomar encomiendas. Los usuarios con rol de **Remitente** pueden publicar encomiendas con valor a pagar y fecha de caducidad.

---

## 🛠️ Cambios Implementados por Capa

### 1. Modelos de Datos (`lib/models/`)

#### [MODIFY] [viaje_model.dart](file:///C:/Users/KGhos/OneDrive/Escritorio/U/2026-1/Nuevas%20tecnologias/Guia%208/App_Lapticon/lib/models/viaje_model.dart)
- Campos de datos: `id`, `numeroVuelo`, `fecha`, `origen`, `destino`, `estado`.

#### [NEW] [encomienda_model.dart](file:///C:/Users/KGhos/OneDrive/Escritorio/U/2026-1/Nuevas%20tecnologias/Guia%208/App_Lapticon/lib/models/encomienda_model.dart)
- Modelo de encomiendas: `id`, `uidRemitente`, `nombreRemitente`, `origen`, `destino`, `descripcion`, `peso`, `valorPagar`, `fechaVencimiento`, `estado` (*disponible*, *tomada*, *en_transito*, *entregada*), `uidViajero`.

#### [NEW] [chat_model.dart](file:///C:/Users/KGhos/OneDrive/Escritorio/U/2026-1/Nuevas%20tecnologias/Guia%208/App_Lapticon/lib/models/chat_model.dart)
- Modelo de mensajes para el chat directo entre Viajero y Remitente (`id`, `chatId`, `senderUid`, `senderName`, `text`, `timestamp`).

---

### 2. Capa de Red y Repositorios (`lib/data/`)

#### [MODIFY] [api_constants.dart](file:///C:/Users/KGhos/OneDrive/Escritorio/U/2026-1/Nuevas%20tecnologias/Guia%208/App_Lapticon/lib/data/network/api_constants.dart)
- Endpoints del backend REST API de Render:
  - `POST /api/encomiendas` (crear encomienda)
  - `GET /api/encomiendas/mis-encomiendas` (mis encomiendas remitente)
  - `GET /api/encomiendas/disponibles` (encomiendas disponibles por ruta)
  - `PUT /api/encomiendas/tomar/{id}` (tomar encomienda)
  - `PUT /api/encomiendas/{id}/estado` (cambiar estado)
  - `GET /api/chats/estado/{chatId}` (estado del chat)

#### [NEW] [encomienda_repository.dart](file:///C:/Users/KGhos/OneDrive/Escritorio/U/2026-1/Nuevas%20tecnologias/Guia%208/App_Lapticon/lib/data/repositories/encomienda_repository.dart)
- Llamadas HTTP para crear, listar, buscar por ruta y tomar encomiendas.

#### [NEW] [chat_repository.dart](file:///C:/Users/KGhos/OneDrive/Escritorio/U/2026-1/Nuevas%20tecnologias/Guia%208/App_Lapticon/lib/data/repositories/chat_repository.dart)
- Interacción de chat directo entre el viajero asignado y el remitente.

---

### 3. ViewModels (`lib/viewmodels/`)

#### [NEW] [encomienda_viewmodel.dart](file:///C:/Users/KGhos/OneDrive/Escritorio/U/2026-1/Nuevas%20tecnologias/Guia%208/App_Lapticon/lib/viewmodels/encomienda_viewmodel.dart)
- Estado de publicación de encomiendas, filtrado por ruta para el viajero, aceptación y persistencia local con `SharedPreferences`.

#### [NEW] [chat_viewmodel.dart](file:///C:/Users/KGhos/OneDrive/Escritorio/U/2026-1/Nuevas%20tecnologias/Guia%208/App_Lapticon/lib/viewmodels/chat_viewmodel.dart)
- Conversación directa activa tras aceptar una encomienda.

---

### 4. Vistas y Pantallas (`lib/screens/`)

#### [NEW] [crear_encomienda_screen.dart](file:///C:/Users/KGhos/OneDrive/Escritorio/U/2026-1/Nuevas%20tecnologias/Guia%208/App_Lapticon/lib/screens/encomiendas/crear_encomienda_screen.dart)
- Formulario para el Remitente: Origen, Destino, Descripción, Peso, Valor a Pagar y Fecha de Vencimiento.

#### [MODIFY] [viajes_tab.dart](file:///C:/Users/KGhos/OneDrive/Escritorio/U/2026-1/Nuevas%20tecnologias/Guia%208/App_Lapticon/lib/screens/home/tabs/viajes_tab.dart)
- Vista completa para el Viajero:
  - Botón para registrar viaje.
  - Selección de viaje activo.
  - **Lista filtrada de encomiendas que coinciden exactamente con su ruta**.
  - Botón **"Aceptar llevar encomienda"**.

#### [MODIFY] [encomiendas_tab.dart](file:///C:/Users/KGhos/OneDrive/Escritorio/U/2026-1/Nuevas%20tecnologias/Guia%208/App_Lapticon/lib/screens/home/tabs/encomiendas_tab.dart)
- Vista completa para el Remitente:
  - Botón *"Publicar Nueva Encomienda"*.
  - Lista de *"Mis Encomiendas"* con su estado (*Buscando viajero*, *Aceptada por viajero*, *En tránsito*, *Entregada*).
  - Botón para abrir el **Chat directo** con el viajero asignado.

#### [NEW] [chat_screen.dart](file:///C:/Users/KGhos/OneDrive/Escritorio/U/2026-1/Nuevas%20tecnologias/Guia%208/App_Lapticon/lib/screens/chat/chat_screen.dart)
- Pantalla de conversación en tiempo real activada únicamente tras la aceptación de la encomienda por el viajero.

---

## 📋 Verificación y Pruebas

1. **Flujo Remitente**:
   - Crear una encomienda de `Bogotá` a `Medellín` especificando un valor a pagar y fecha de vencimiento.
2. **Flujo Viajero**:
   - Registrar un viaje de `Bogotá` a `Medellín`.
   - Entrar al panel de viajes: la app filtra y muestra únicamente la encomienda creada para la ruta `Bogotá -> Medellín`.
   - Presionar **"Aceptar llevar encomienda"**.
3. **Flujo de Interacción / Chat**:
   - Al aceptar la encomienda, se habilita el botón **"Abrir Chat con Remitente"**.
   - Entrar al chat y enviar mensajes entre ambos actores.
