# ============================================================
# FEATURE: EmailInvocable – Envío Asíncrono de Correo (NovaBank)
# Clase bajo prueba: EmailInvocable, AsyncEmailSender, EmailRequest
# Cobertura objetivo: >= 95%
# Usuarios involucrados: executiveTest (Ejecutivo), analystTest (Analista)
# ============================================================

Feature: Envío asíncrono de correo electrónico con adjunto mediante proceso Queueable

  Como sistema de NovaBank
  Quiero enviar correos electrónicos de forma asíncrona cuando una oportunidad es ganada
  Para notificar al cliente la emisión de su tarjeta de crédito

  Background:
    Given el sistema Salesforce está configurado con los perfiles "Asesor de Venta y Reclamos"
    And existe un rol "Ejecutivo" y un rol "Analista" en la jerarquía de roles
    And existe un usuario "executiveTest" con rol "Ejecutivo"
    And existe un usuario "analystTest" con rol "Analista"
    And existe una cuenta de cliente activa con DNI "12345678"
    And existe una plantilla de correo electrónico configurada en la plataforma

  # ============================================================
  # ESCENARIO 1 – Llamada con lista válida de una solicitud
  # ============================================================
  Scenario: Envío exitoso de correo con una solicitud válida ejecutado por Ejecutivo
    Given el usuario autenticado es "executiveTest" con rol "Ejecutivo"
    And se construye un EmailRequest con:
      | campo          | valor                          |
      | toAddress      | cliente@correo.com             |
      | subject        | Emisión de Tarjeta de Crédito  |
      | body           | Su tarjeta Visa Oro fue emitida|
      | templateId     | <Id de plantilla válida>       |
      | attachmentId   | <Id de ContentVersion válido>  |
    When se invoca EmailInvocable.sendEmailAsync con la lista que contiene ese EmailRequest
    Then el job Queueable AsyncEmailSender es encolado exitosamente
    And no se lanza ninguna excepción

  # ============================================================
  # ESCENARIO 2 – Llamada con lista válida ejecutado por Analista
  # ============================================================
  Scenario: Envío exitoso de correo con una solicitud válida ejecutado por Analista
    Given el usuario autenticado es "analystTest" con rol "Analista"
    And se construye un EmailRequest con:
      | campo          | valor                          |
      | toAddress      | cliente2@correo.com            |
      | subject        | Tarjeta Visa Infinite Emitida  |
      | body           | Su tarjeta fue aprobada        |
      | templateId     | <Id de plantilla válida>       |
      | attachmentId   | <Id de ContentVersion válido>  |
    When se invoca EmailInvocable.sendEmailAsync con la lista que contiene ese EmailRequest
    Then el job Queueable AsyncEmailSender es encolado exitosamente
    And no se lanza ninguna excepción

  # ============================================================
  # ESCENARIO 3 – Lista con múltiples solicitudes
  # ============================================================
  Scenario: Envío exitoso de correo con múltiples solicitudes en la lista
    Given el usuario autenticado es "executiveTest" con rol "Ejecutivo"
    And se construyen 3 EmailRequest con destinatarios distintos
    When se invoca EmailInvocable.sendEmailAsync con la lista de 3 solicitudes
    Then el job Queueable AsyncEmailSender es encolado exactamente una vez con la lista completa
    And no se lanza ninguna excepción

  # ============================================================
  # ESCENARIO 4 – Lista nula: no debe encolar ningún job
  # ============================================================
  Scenario: No se encola ningún job cuando la lista de solicitudes es nula
    Given el usuario autenticado es "executiveTest" con rol "Ejecutivo"
    When se invoca EmailInvocable.sendEmailAsync con una lista nula
    Then no se encola ningún job Queueable
    And no se lanza ninguna excepción

  # ============================================================
  # ESCENARIO 5 – Lista vacía: no debe encolar ningún job
  # ============================================================
  Scenario: No se encola ningún job cuando la lista de solicitudes está vacía
    Given el usuario autenticado es "analystTest" con rol "Analista"
    When se invoca EmailInvocable.sendEmailAsync con una lista vacía
    Then no se encola ningún job Queueable
    And no se lanza ninguna excepción

  # ============================================================
  # ESCENARIO 6 – Ejecución del job Queueable: correo enviado correctamente
  # ============================================================
  Scenario: AsyncEmailSender ejecuta el envío del correo al procesar la cola
    Given el usuario autenticado es "executiveTest" con rol "Ejecutivo"
    And existe un EmailRequest válido con toAddress, subject y body
    And se instancia AsyncEmailSender con ese EmailRequest
    When se ejecuta el método execute del job Queueable
    Then se genera y envía un Messaging.SingleEmailMessage al destinatario indicado
    And el correo contiene el subject y body especificados
    And no se lanza ninguna excepción

  # ============================================================
  # ESCENARIO 7 – Ejecución del job con adjunto (ContentVersion)
  # ============================================================
  Scenario: AsyncEmailSender adjunta correctamente el documento al correo
    Given el usuario autenticado es "executiveTest" con rol "Ejecutivo"
    And existe un registro ContentVersion vinculado a una oportunidad ganada
    And se construye un EmailRequest con attachmentId igual al Id del ContentVersion
    When se ejecuta el método execute del job Queueable AsyncEmailSender
    Then el correo enviado incluye el archivo adjunto correspondiente al ContentVersion
    And el adjunto tiene el nombre y tipo de contenido correctos

  # ============================================================
  # ESCENARIO 8 – Ejecución con plantilla de correo configurada
  # ============================================================
  Scenario: AsyncEmailSender utiliza la plantilla de correo configurada en la plataforma
    Given el usuario autenticado es "analystTest" con rol "Analista"
    And existe una EmailTemplate activa con nombre "Emision_Tarjeta"
    And se construye un EmailRequest con templateId igual al Id de esa plantilla
    When se ejecuta el método execute del job Queueable AsyncEmailSender
    Then el correo enviado utiliza la plantilla "Emision_Tarjeta"
    And los campos dinámicos de la plantilla son reemplazados correctamente

  # ============================================================
  # ESCENARIO 9 – Ejecución con lista de múltiples requests en el job
  # ============================================================
  Scenario: AsyncEmailSender procesa correctamente múltiples solicitudes de correo
    Given el usuario autenticado es "executiveTest" con rol "Ejecutivo"
    And se construyen 3 EmailRequest con distintos destinatarios y subjects
    When se ejecuta el método execute del job Queueable AsyncEmailSender con los 3 requests
    Then se envían 3 correos electrónicos de forma individual a cada destinatario
    And ningún envío falla

  # ============================================================
  # ESCENARIO 10 – Anotación @InvocableMethod disponible para Flow
  # ============================================================
  Scenario: El método sendEmailAsync está disponible como acción invocable en Flows
    Given existe un Record-Triggered Flow configurado en el objeto Opportunity
    And el flow se activa cuando la oportunidad cambia a estado "Cerrada-Ganada"
    When el flow ejecuta la acción "Enviar Correo Asíncrono con Adjunto"
    Then el sistema llama a EmailInvocable.sendEmailAsync con los datos de la oportunidad
    And el job Queueable es encolado correctamente

  # ============================================================
  # ESCENARIO 11 – Seguridad: clase ejecutada con "with sharing"
  # ============================================================
  Scenario: La clase respeta las reglas de compartición del usuario Ejecutivo
    Given el usuario autenticado es "executiveTest" con rol "Ejecutivo"
    And el OWD del objeto Financial Account está configurado como "Privado"
    When se invoca sendEmailAsync con un request asociado a una cuenta propia del ejecutivo
    Then el job se encola exitosamente respetando el modelo de seguridad
    And el ejecutivo no puede acceder a registros de otros ejecutivos

  # ============================================================
  # ESCENARIO 12 – Seguridad: Analista accede a campos restringidos
  # ============================================================
  Scenario: El Analista puede ejecutar el envío de correo con acceso a campos restringidos
    Given el usuario autenticado es "analystTest" con rol "Analista"
    And el Analista tiene permiso sobre el campo "Número de Tarjeta" del Financial Account
    When se invoca sendEmailAsync con un EmailRequest que incluye datos de tarjeta
    Then el job se encola exitosamente
    And el correo generado incluye los datos a los que el Analista tiene acceso
