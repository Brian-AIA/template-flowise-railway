# AIAutomatiza - Flowise Railway Standard

Plantilla privada para desplegar Flowise 3.1.4 en Railway con los estandares operativos de AIAutomatiza.

## Incluye

- Flowise fijado al commit de la version 3.1.4 validada.
- `gpt-5.6-luna` visible en el catalogo de OpenAI.
- Valor seguro `reasoningEffort=none` para Luna cuando se usan herramientas por Chat Completions.
- Retencion de ejecuciones activa por defecto: 90 dias, todos los dias a las 03:15 Europe/Madrid.
- Lotes transaccionales de 250, hasta 10.000 ejecuciones por ciclo.
- Conservacion de mensajes: antes de borrar una traza, solo se elimina su enlace tecnico `executionId`; no se borra el contenido del chat.
- Indice concurrente sobre `chat_message.executionId`, verificado automaticamente en el arranque para que la retencion mantenga un coste bajo.
- Bloqueo asesor de PostgreSQL para evitar dos limpiezas simultaneas si se escala el servicio.

## Politica de retencion

La retencion afecta unicamente a registros de `execution` que no estan `INPROGRESS` y superan los 90 dias. No borra Agentflows, Chatflows, credenciales, API keys, variables, documentos ni mensajes.

PostgreSQL reutiliza el espacio liberado. Una compactacion de `execution` es opcional y solo se realiza si se necesita reducir el uso fisico que muestra Railway. No debe programarse como parte del despliegue inicial.

## Crear la plantilla privada en Railway

1. Crear un repositorio privado de GitHub de la organizacion, por ejemplo `aiautomatiza/flowise-railway-standard`, y subir este directorio.
2. En Railway, crear un proyecto base no productivo con dos servicios: este repositorio y PostgreSQL.
3. En el servicio Flowise, copiar las variables de `.env.example` a la pestaña **Variables**. Las referencias `${{Postgres.*}}` deben apuntar al servicio PostgreSQL de ese proyecto.
4. Asignar a PostgreSQL un volumen persistente de 5 GB en `/var/lib/postgresql/data`. Ajustarlo solo si la observacion de 90 dias lo justifica.
5. Desplegar, abrir Flowise y comprobar que la pantalla carga y que Luna aparece en el catalogo de OpenAI.
6. En Railway: **Project Settings -> Generate Template from Project -> Create Template**. Mantenerlo privado dentro del workspace de AIAutomatiza.

El repositorio de GitHub es la fuente canonica y auditada. La plantilla de Railway es el mecanismo de despliegue para el equipo. Asi se pueden actualizar las personalizaciones mediante pull request y probarlas antes de crear nuevos proyectos.

## Despliegue de un nuevo cliente

1. Desde Railway, desplegar la plantilla privada.
2. Introducir las credenciales propias del cliente en Flowise despues de desplegar. Nunca reutilizar secretos ni API keys de otro proyecto.
3. Configurar dominio, usuarios de Flowise y las variables especificas del cliente.
4. Verificar una llamada de prueba y el log de inicio de `ExecutionRetention`.
5. Revisar el uso de volumen mensualmente. La ampliacion a 10 GB y la compactacion no son requisitos iniciales.

## Actualizar la base

No actualizar `FLOWISE_COMMIT` directamente en produccion. Crear una rama, cambiar el commit, verificar que el parche aplica y desplegar una instancia de prueba antes de aprobar la nueva version de la plantilla.
