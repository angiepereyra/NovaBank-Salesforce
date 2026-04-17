/**
 * @description  : Clase de prueba para EmailRequest.cls
 *                 Cubre todos los escenarios del Feature File con cobertura >= 95%.
 *                 Valida instanciación, asignación de campos, comportamiento nulo,
 *                 reasignación de valores, uso bulk y contexto de ambos roles:
 *                 Ejecutivo y Analista.
 *
 *                 Escenarios cubiertos:
 *                 [SC-01] Instanciación válida como Ejecutivo
 *                 [SC-02] Instanciación válida como Analista
 *                 [SC-03] Visibilidad pública de campos InvocableVariable
 *                 [SC-04] recordId de tipo Case (Postventa) - Ejecutivo
 *                 [SC-05] recordId de Financial Account - Analista
 *                 [SC-06] Lista bulk de EmailRequests - Ejecutivo
 *                 [SC-07] Contexto de Oportunidad Ganada - Ejecutivo
 *                 [SC-08] Distintos templateApiName (Outline) - ambos roles
 *                 [SC-09] Instancia con valores nulos por defecto
 *                 [SC-10] Reasignación de campos en instancia existente - Analista
 *
 * @author       : NovaBank Dev Team
 * @project      : Gestión Integral Tarjeta de Crédito - Salesforce
 * @last modified: 04-16-2026
 **/
@IsTest
private class EmailRequestTest {

    // =========================================================
    // TEST SETUP
    // =========================================================

    /**
     * @description Crea datos base compartidos por todos los métodos de prueba.
     *              Se ejecuta una sola vez antes de todos los tests del contexto.
     */
    @TestSetup
    static void setupTestData() {
        // Crear usuarios
        User ejecutivo = EmailRequestDataFactory.createEjecutivoUser();
        User analista  = EmailRequestDataFactory.createAnalistaUser();

        // Crear Accounts (inserción en contexto Admin para evitar restricciones de perfil)
        List<Account> accounts = EmailRequestDataFactory.createAccounts(5);

        // Crear Opportunities
        List<Opportunity> opps = EmailRequestDataFactory.createOpportunidadesGanadas(accounts);

        // Crear Cases
        EmailRequestDataFactory.createCase(accounts[0].Id);

        // Crear Email Templates (múltiples para distintos escenarios)
        EmailRequestDataFactory.createEmailTemplate(
            EmailRequestDataFactory.TEMPLATE_EMISION,
            'Confirmacion Emision Tarjeta'
        );
        EmailRequestDataFactory.createEmailTemplate(
            EmailRequestDataFactory.TEMPLATE_CIERRE_CASO,
            'Cierre Caso Postventa'
        );
        EmailRequestDataFactory.createEmailTemplate(
            EmailRequestDataFactory.TEMPLATE_FINANCIAL_ACC,
            'Emision Tarjeta Credito'
        );
        EmailRequestDataFactory.createEmailTemplate(
            EmailRequestDataFactory.TEMPLATE_CONTRATO,
            'Envio Contrato Oportunidad Ganada'
        );
    }

    // =========================================================
    // SC-01: Instanciación válida como Ejecutivo
    // =========================================================

    /**
     * @description [SC-01] Verifica que un usuario Ejecutivo puede crear una instancia
     *              de EmailRequest con todos los campos correctamente asignados.
     */
    @IsTest
    static void testInstanciacionValidaComoEjecutivo() {
        User ejecutivo = [
            SELECT Id FROM User
            WHERE LastName = 'Ejecutivo Test'
            LIMIT 1
        ];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [
            SELECT Id FROM Opportunity
            WHERE AccountId = :acc.Id
            LIMIT 1
        ];

        System.runAs(ejecutivo) {
            Test.startTest();

            EmailRequest req = EmailRequestDataFactory.buildEmailRequest(
                opp.Id,
                acc.Id,
                EmailRequestDataFactory.TEMPLATE_EMISION
            );

            Test.stopTest();

            Assert.isNotNull(req,                       'El objeto EmailRequest no debe ser nulo');
            Assert.areEqual(opp.Id, req.recordId,       'recordId debe coincidir con la Opportunity');
            Assert.areEqual(acc.Id, req.accountId,      'accountId debe coincidir con la Account');
            Assert.areEqual(
                EmailRequestDataFactory.TEMPLATE_EMISION,
                req.templateApiName,
                'templateApiName debe ser el de emisión de tarjeta'
            );
        }
    }

    // =========================================================
    // SC-02: Instanciación válida como Analista
    // =========================================================

    /**
     * @description [SC-02] Verifica que un usuario Analista puede crear una instancia
     *              de EmailRequest con todos los campos correctamente asignados.
     */
    @IsTest
    static void testInstanciacionValidaComoAnalista() {
        User analista = [
            SELECT Id FROM User
            WHERE LastName = 'Analista Test'
            LIMIT 1
        ];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [
            SELECT Id FROM Opportunity
            WHERE AccountId = :acc.Id
            LIMIT 1
        ];

        System.runAs(analista) {
            Test.startTest();

            EmailRequest req = EmailRequestDataFactory.buildEmailRequest(
                opp.Id,
                acc.Id,
                EmailRequestDataFactory.TEMPLATE_CIERRE_CASO
            );

            Test.stopTest();

            Assert.isNotNull(req,                            'El objeto EmailRequest no debe ser nulo');
            Assert.isNotNull(req.recordId,                   'recordId no debe ser nulo');
            Assert.isNotNull(req.accountId,                  'accountId no debe ser nulo');
            Assert.isNotNull(req.templateApiName,            'templateApiName no debe ser nulo');
            Assert.isTrue(
                String.valueOf(req.recordId).startsWith('006'),
                'recordId debe ser un Id de Opportunity (prefijo 006)'
            );
        }
    }

    // =========================================================
    // SC-03: Visibilidad pública de campos InvocableVariable
    // =========================================================

    /**
     * @description [SC-03] Verifica que los tres campos son públicos,
     *              pueden asignarse y leerse sin excepción desde cualquier contexto.
     */
    @IsTest
    static void testVisibilidadPublicaCampos() {
        User ejecutivo = [
            SELECT Id FROM User
            WHERE LastName = 'Ejecutivo Test'
            LIMIT 1
        ];

        System.runAs(ejecutivo) {
            Test.startTest();

            EmailRequest req = new EmailRequest();

            // Asignación directa de campos públicos (no debe lanzar excepción)
            req.recordId        = UserInfo.getUserId(); // Cualquier Id válido para la prueba
            req.accountId       = UserInfo.getUserId();
            req.templateApiName = 'Template_Prueba_Visibilidad';

            Test.stopTest();

            // Verificar lectura pública
            Assert.isNotNull(req.recordId,        'Campo recordId debe ser accesible públicamente');
            Assert.isNotNull(req.accountId,       'Campo accountId debe ser accesible públicamente');
            Assert.isNotNull(req.templateApiName, 'Campo templateApiName debe ser accesible públicamente');
            Assert.areEqual(
                'Template_Prueba_Visibilidad',
                req.templateApiName,
                'El valor asignado debe ser el mismo que se lee'
            );
        }
    }

    // =========================================================
    // SC-04: recordId de tipo Case (Postventa) - Ejecutivo
    // =========================================================

    /**
     * @description [SC-04] Verifica que EmailRequest puede ser construido
     *              con el Id de un Case como recordId en contexto de postventa,
     *              ejecutado por un usuario Ejecutivo.
     */
    @IsTest
    static void testEmailRequestConCase_Ejecutivo() {
        User ejecutivo = [
            SELECT Id FROM User
            WHERE LastName = 'Ejecutivo Test'
            LIMIT 1
        ];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Case c = [
            SELECT Id, AccountId FROM Case
            WHERE AccountId = :acc.Id
            LIMIT 1
        ];

        System.runAs(ejecutivo) {
            Test.startTest();

            EmailRequest req = EmailRequestDataFactory.buildEmailRequestForCase(
                c.Id,
                c.AccountId
            );

            Test.stopTest();

            Assert.isNotNull(req,                              'EmailRequest no debe ser nulo');
            Assert.areEqual(c.Id,         req.recordId,        'recordId debe ser el Id del Case');
            Assert.areEqual(c.AccountId,  req.accountId,       'accountId debe corresponder a la Account del caso');
            Assert.areEqual(
                EmailRequestDataFactory.TEMPLATE_CIERRE_CASO,
                req.templateApiName,
                'templateApiName debe ser el de cierre de caso'
            );
            Assert.isTrue(
                String.valueOf(req.recordId).startsWith('500'),
                'recordId debe ser un Id de Case (prefijo 500)'
            );
        }
    }

    // =========================================================
    // SC-05: recordId de Financial Account - Analista
    // =========================================================

    /**
     * @description [SC-05] Verifica que EmailRequest puede ser construido
     *              con un Id de objeto personalizado (Financial Account),
     *              ejecutado como usuario Analista.
     *              NOTA: Como FinancialAccount__c puede no existir en todos los orgs de test,
     *              se simula con el Id de una Opportunity (mismo patrón de Id de Salesforce).
     */
    @IsTest
    static void testEmailRequestConFinancialAccount_Analista() {
        User analista = [
            SELECT Id FROM User
            WHERE LastName = 'Analista Test'
            LIMIT 1
        ];
        Account acc   = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [
            SELECT Id FROM Opportunity
            WHERE AccountId = :acc.Id
            LIMIT 1
        ];

        System.runAs(analista) {
            Test.startTest();

            // Se usa el Id de Opportunity como proxy del Id de FinancialAccount__c
            // para validar que cualquier Id de Salesforce es aceptado en el campo
            EmailRequest req = EmailRequestDataFactory.buildEmailRequest(
                opp.Id,
                acc.Id,
                EmailRequestDataFactory.TEMPLATE_FINANCIAL_ACC
            );

            Test.stopTest();

            Assert.isNotNull(req,                 'EmailRequest no debe ser nulo');
            Assert.areEqual(opp.Id, req.recordId, 'recordId debe contener el Id asignado');
            Assert.areEqual(acc.Id, req.accountId,'accountId debe contener el Id de Account');
            Assert.areEqual(
                EmailRequestDataFactory.TEMPLATE_FINANCIAL_ACC,
                req.templateApiName,
                'templateApiName debe ser el de emisión de tarjeta'
            );
        }
    }

    // =========================================================
    // SC-06: Lista bulk de EmailRequests - Ejecutivo
    // =========================================================

    /**
     * @description [SC-06] Verifica que se pueden crear múltiples instancias
     *              de EmailRequest en una lista para procesamiento masivo.
     *              Ejecutado como usuario Ejecutivo.
     */
    @IsTest
    static void testBulkEmailRequestList_Ejecutivo() {
        User ejecutivo = [
            SELECT Id FROM User
            WHERE LastName = 'Ejecutivo Test'
            LIMIT 1
        ];
        List<Account>     accounts = [SELECT Id FROM Account LIMIT 3];
        List<Opportunity> opps     = [
            SELECT Id, AccountId FROM Opportunity
            WHERE AccountId IN :accounts
            LIMIT 3
        ];

        System.runAs(ejecutivo) {
            Test.startTest();

            List<EmailRequest> requests = EmailRequestDataFactory.buildEmailRequestList(
                opps,
                accounts,
                EmailRequestDataFactory.TEMPLATE_EMISION
            );

            Test.stopTest();

            Assert.isNotNull(requests,                         'La lista no debe ser nula');
            Assert.areEqual(3, requests.size(),                'La lista debe contener exactamente 3 elementos');

            Set<Id> recordIds = new Set<Id>();
            for (EmailRequest req : requests) {
                Assert.isNotNull(req,                          'Cada EmailRequest no debe ser nulo');
                Assert.isNotNull(req.recordId,                 'recordId no debe ser nulo en ningún elemento');
                Assert.isNotNull(req.accountId,                'accountId no debe ser nulo en ningún elemento');
                Assert.isNotNull(req.templateApiName,          'templateApiName no debe ser nulo en ningún elemento');
                Assert.areEqual(
                    EmailRequestDataFactory.TEMPLATE_EMISION,
                    req.templateApiName,
                    'Todos deben tener el mismo template'
                );
                recordIds.add(req.recordId);
            }

            Assert.areEqual(3, recordIds.size(), 'Los recordIds deben ser distintos entre sí');
        }
    }

    // =========================================================
    // SC-07: Contexto de Oportunidad Ganada - Ejecutivo
    // =========================================================

    /**
     * @description [SC-07] Verifica que EmailRequest se construye correctamente
     *              para el flujo de envío de contrato al ganar una Oportunidad.
     *              Ejecutado como usuario Ejecutivo.
     */
    @IsTest
    static void testEmailRequestOportunidadGanada_Ejecutivo() {
        User ejecutivo = [
            SELECT Id FROM User
            WHERE LastName = 'Ejecutivo Test'
            LIMIT 1
        ];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [
            SELECT Id FROM Opportunity
            WHERE AccountId = :acc.Id
            AND StageName = 'Closed Won'
            LIMIT 1
        ];

        System.runAs(ejecutivo) {
            Test.startTest();

            EmailRequest req = EmailRequestDataFactory.buildEmailRequestForOppGanada(
                opp.Id,
                acc.Id
            );

            Test.stopTest();

            Assert.isNotNull(req,                            'El objeto debe estar correctamente construido');
            Assert.areEqual(opp.Id, req.recordId,            'recordId debe ser el Id de la Opportunity ganada');
            Assert.areEqual(acc.Id, req.accountId,           'accountId debe ser el Id de la Account');
            Assert.areEqual(
                EmailRequestDataFactory.TEMPLATE_CONTRATO,
                req.templateApiName,
                'templateApiName debe ser el template de envío de contrato'
            );
            // Verificar que los campos tienen valores asignados
            Assert.isNotNull(req.recordId,        'recordId debe tener un valor asignado');
            Assert.isNotNull(req.accountId,       'accountId debe tener un valor asignado');
            Assert.isNotNull(req.templateApiName, 'templateApiName debe tener un valor asignado');
        }
    }

    // =========================================================
    // SC-08a: Distintos templateApiName - Ejecutivo (Outline Row 1 y 3)
    // =========================================================

    /**
     * @description [SC-08a] Verifica que templateApiName acepta distintos valores
     *              para el rol Ejecutivo (templates de emisión y financial account).
     */
    @IsTest
    static void testDistintosTemplates_Ejecutivo() {
        User ejecutivo = [
            SELECT Id FROM User
            WHERE LastName = 'Ejecutivo Test'
            LIMIT 1
        ];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [
            SELECT Id FROM Opportunity
            WHERE AccountId = :acc.Id
            LIMIT 1
        ];

        System.runAs(ejecutivo) {
            Test.startTest();

            // Template 1: Confirmacion_Emision_Tarjeta
            EmailRequest req1 = EmailRequestDataFactory.buildEmailRequest(
                opp.Id, acc.Id, EmailRequestDataFactory.TEMPLATE_EMISION
            );

            // Template 2: Emision_Tarjeta_Credito
            EmailRequest req2 = EmailRequestDataFactory.buildEmailRequest(
                opp.Id, acc.Id, EmailRequestDataFactory.TEMPLATE_FINANCIAL_ACC
            );

            // Template 3: Envio_Contrato_Oportunidad_Ganada
            EmailRequest req3 = EmailRequestDataFactory.buildEmailRequest(
                opp.Id, acc.Id, EmailRequestDataFactory.TEMPLATE_CONTRATO
            );

            Test.stopTest();

            Assert.areEqual(EmailRequestDataFactory.TEMPLATE_EMISION,       req1.templateApiName, 'Template emisión incorrecto');
            Assert.areEqual(EmailRequestDataFactory.TEMPLATE_FINANCIAL_ACC,  req2.templateApiName, 'Template financial account incorrecto');
            Assert.areEqual(EmailRequestDataFactory.TEMPLATE_CONTRATO,       req3.templateApiName, 'Template contrato incorrecto');
            Assert.isNotNull(req1, 'req1 no debe ser nulo');
            Assert.isNotNull(req2, 'req2 no debe ser nulo');
            Assert.isNotNull(req3, 'req3 no debe ser nulo');
        }
    }

    // =========================================================
    // SC-08b: Distintos templateApiName - Analista (Outline Row 2 y 4)
    // =========================================================

    /**
     * @description [SC-08b] Verifica que templateApiName acepta distintos valores
     *              para el rol Analista (templates de cierre de caso y contrato).
     */
    @IsTest
    static void testDistintosTemplates_Analista() {
        User analista = [
            SELECT Id FROM User
            WHERE LastName = 'Analista Test'
            LIMIT 1
        ];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Case c = [SELECT Id, AccountId FROM Case LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id LIMIT 1];

        System.runAs(analista) {
            Test.startTest();

            // Template cierre de caso (con Case como recordId)
            EmailRequest req1 = EmailRequestDataFactory.buildEmailRequest(
                c.Id, c.AccountId, EmailRequestDataFactory.TEMPLATE_CIERRE_CASO
            );

            // Template contrato (con Opportunity como recordId)
            EmailRequest req2 = EmailRequestDataFactory.buildEmailRequest(
                opp.Id, acc.Id, EmailRequestDataFactory.TEMPLATE_CONTRATO
            );

            Test.stopTest();

            Assert.areEqual(
                EmailRequestDataFactory.TEMPLATE_CIERRE_CASO,
                req1.templateApiName,
                'Template cierre caso incorrecto'
            );
            Assert.areEqual(
                EmailRequestDataFactory.TEMPLATE_CONTRATO,
                req2.templateApiName,
                'Template contrato incorrecto'
            );
            Assert.isNotNull(req1, 'req1 no debe ser nulo');
            Assert.isNotNull(req2, 'req2 no debe ser nulo');
        }
    }

    // =========================================================
    // SC-09: Instancia con valores nulos por defecto
    // =========================================================

    /**
     * @description [SC-09] Verifica que una instancia de EmailRequest creada
     *              sin asignar valores tiene todos sus campos nulos,
     *              pero el objeto en sí no es nulo.
     */
    @IsTest
    static void testInstanciaVaciaValoresNulos() {
        User ejecutivo = [
            SELECT Id FROM User
            WHERE LastName = 'Ejecutivo Test'
            LIMIT 1
        ];

        System.runAs(ejecutivo) {
            Test.startTest();

            EmailRequest req = EmailRequestDataFactory.buildEmailRequestVacio();

            Test.stopTest();

            Assert.isNotNull(req,                  'El objeto EmailRequest no debe ser nulo aunque sus campos estén vacíos');
            Assert.isNull(req.recordId,             'recordId debe ser nulo por defecto');
            Assert.isNull(req.accountId,            'accountId debe ser nulo por defecto');
            Assert.isNull(req.templateApiName,      'templateApiName debe ser nulo por defecto');
        }
    }

    // =========================================================
    // SC-10: Reasignación de campos en instancia existente - Analista
    // =========================================================

    /**
     * @description [SC-10] Verifica que los campos de una instancia de EmailRequest
     *              pueden ser reasignados correctamente después de la creación inicial,
     *              ejecutado como usuario Analista.
     */
    @IsTest
    static void testReasignacionCampos_Analista() {
        User analista = [
            SELECT Id FROM User
            WHERE LastName = 'Analista Test'
            LIMIT 1
        ];
        List<Account>     accounts = [SELECT Id FROM Account LIMIT 2];
        List<Opportunity> opps     = [
            SELECT Id FROM Opportunity
            WHERE AccountId IN :accounts
            LIMIT 2
        ];

        System.runAs(analista) {
            Test.startTest();

            // Crear instancia inicial
            EmailRequest req = EmailRequestDataFactory.buildEmailRequest(
                opps[0].Id,
                accounts[0].Id,
                'Template_Inicial'
            );

            Id originalAccountId = req.accountId;

            // Reasignar campos
            req.templateApiName = 'Template_Actualizado';
            req.recordId        = opps[1].Id;

            Test.stopTest();

            Assert.areEqual(
                'Template_Actualizado',
                req.templateApiName,
                'templateApiName debe contener el valor actualizado'
            );
            Assert.areEqual(
                opps[1].Id,
                req.recordId,
                'recordId debe contener el nuevo valor asignado'
            );
            Assert.areEqual(
                originalAccountId,
                req.accountId,
                'accountId debe mantener el valor original sin cambios'
            );
        }
    }

    // =========================================================
    // SC-EXTRA: Verificar igualdad de campo tras múltiples asignaciones
    // =========================================================

    /**
     * @description [SC-EXTRA] Verifica robustez: asignar el mismo campo múltiples veces
     *              conserva siempre el último valor. Cubre ramas adicionales para >= 95%.
     */
    @IsTest
    static void testAsignacionMultiple() {
        User ejecutivo = [
            SELECT Id FROM User
            WHERE LastName = 'Ejecutivo Test'
            LIMIT 1
        ];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        System.runAs(ejecutivo) {
            Test.startTest();

            EmailRequest req = new EmailRequest();
            req.templateApiName = 'Template_v1';
            req.templateApiName = 'Template_v2';
            req.templateApiName = 'Template_v3';

            req.accountId = acc.Id;
            req.recordId  = acc.Id; // Usando el mismo Id como placeholder

            Test.stopTest();

            Assert.areEqual('Template_v3', req.templateApiName, 'Debe conservar el último valor asignado');
            Assert.areEqual(acc.Id, req.accountId, 'accountId debe ser el último asignado');
            Assert.isNotNull(req, 'La instancia no debe ser nula');
        }
    }
}
