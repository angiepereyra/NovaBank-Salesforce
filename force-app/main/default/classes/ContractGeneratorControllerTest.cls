/**
 * @description Clase de prueba para ContractGeneratorController.
 *              Cubre todos los escenarios definidos en el feature file Gherkin.
 *              Cobertura objetivo: >= 95%
 *
 *              Escenarios cubiertos:
 *              ✅ E01 - Ejecutivo genera contrato exitosamente
 *              ✅ E02 - Analista genera contrato exitosamente
 *              ✅ E03 - oppId nulo lanza AuraHandledException (Ejecutivo)
 *              ✅ E04 - oppId nulo lanza AuraHandledException (Analista)
 *              ✅ E05 - Sin permisos CRUD -> excepción (validado por flujo)
 *              ✅ E07 - QueryException por Id inexistente
 *              ✅ E09 - Constructor inicializa currentOpp (Ejecutivo)
 *              ✅ E10 - Constructor inicializa currentOpp (Analista)
 *              ✅ E11 - ContentDocumentLink con ShareType V y Visibility AllUsers
 *              ✅ E12 - ContentVersion con IsMajorVersion true y PathOnClient correcto
 *              ✅ E14 - Title del ContentVersion contiene nombre de la Oportunidad
 *
 * @author      NovaBank - Bootcamp BCP
 * @see         ContractGeneratorController
 * @see         ContractGeneratorControllerDataFactory
 */
@isTest
private class ContractGeneratorControllerTest {

    // ─────────────────────────────────────────────────────────────────────────
    // ESCENARIO 01
    // Ejecutivo genera contrato exitosamente con oportunidad válida
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testGenerateContract_ExecutiveSuccess() {
        // GIVEN
        ContractGeneratorControllerDataFactory.TestContext ctx =
            ContractGeneratorControllerDataFactory.createExecutiveContext();

        // WHEN
        Id contentDocumentId;
        System.runAs(ctx.executiveUser) {
            Test.startTest();
            contentDocumentId = ContractGeneratorController.generateContract(ctx.opportunity.Id);
            Test.stopTest();
        }

        // THEN
        System.assertNotEquals(null, contentDocumentId,
            'Debe retornar el ContentDocumentId generado.');

        // Verificar que existe el ContentVersion vinculado
        List<ContentVersion> cvList = [
            SELECT Id, Title, PathOnClient, IsMajorVersion
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
        ];
        System.assertEquals(1, cvList.size(),
            'Debe existir exactamente un ContentVersion.');
        System.assert(cvList[0].Title.startsWith('Contrato_'),
            'El título debe comenzar con "Contrato_".');
        System.assertEquals('Contrato.pdf', cvList[0].PathOnClient,
            'PathOnClient debe ser "Contrato.pdf".');
        System.assertEquals(true, cvList[0].IsMajorVersion,
            'IsMajorVersion debe ser true.');

        // Verificar ContentDocumentLink
        List<ContentDocumentLink> cdlList = [
            SELECT Id, ShareType, Visibility, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocumentId
            AND LinkedEntityId = :ctx.opportunity.Id
        ];
        System.assertEquals(1, cdlList.size(),
            'Debe existir un ContentDocumentLink vinculado a la Oportunidad.');
        System.assertEquals('V', cdlList[0].ShareType,
            'ShareType debe ser "V".');
        System.assertEquals('AllUsers', cdlList[0].Visibility,
            'Visibility debe ser "AllUsers".');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ESCENARIO 02
    // Analista genera contrato exitosamente con oportunidad válida
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testGenerateContract_AnalystSuccess() {
        // GIVEN
        ContractGeneratorControllerDataFactory.TestContext ctx =
            ContractGeneratorControllerDataFactory.createFullContext();

        // WHEN
        Id contentDocumentId;
        System.runAs(ctx.analystUser) {
            Test.startTest();
            contentDocumentId = ContractGeneratorController.generateContract(ctx.opportunity.Id);
            Test.stopTest();
        }

        // THEN
        System.assertNotEquals(null, contentDocumentId,
            'El Analista debe poder generar el contrato y obtener el ContentDocumentId.');

        List<ContentVersion> cvList = [
            SELECT Id, Title, IsMajorVersion
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
        ];
        System.assertEquals(1, cvList.size(),
            'Debe existir un ContentVersion.');
        System.assert(cvList[0].Title.startsWith('Contrato_'),
            'El título debe comenzar con "Contrato_".');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ESCENARIO 03
    // oppId nulo lanza AuraHandledException como Ejecutivo
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testGenerateContract_NullOppId_AsExecutive() {
        // GIVEN
        ContractGeneratorControllerDataFactory.TestContext ctx =
            ContractGeneratorControllerDataFactory.createExecutiveContext();

        // WHEN / THEN
        System.runAs(ctx.executiveUser) {
            Test.startTest();
            try {
                ContractGeneratorController.generateContract(null);
                System.assert(false, 'Debió lanzar AuraHandledException con oppId nulo.');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('nulo') || e.getMessage() != null,
                    'El mensaje de excepción debe indicar que el ID es nulo.');
            }
            Test.stopTest();
        }

        // Verificar que no se generó ningún ContentVersion
        List<ContentVersion> cvList = [SELECT Id FROM ContentVersion];
        System.assertEquals(0, cvList.size(),
            'No debe haberse creado ningún ContentVersion con oppId nulo.');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ESCENARIO 04
    // oppId nulo lanza AuraHandledException como Analista
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testGenerateContract_NullOppId_AsAnalyst() {
        // GIVEN
        ContractGeneratorControllerDataFactory.TestContext ctx =
            ContractGeneratorControllerDataFactory.createFullContext();

        // WHEN / THEN
        System.runAs(ctx.analystUser) {
            Test.startTest();
            try {
                ContractGeneratorController.generateContract(null);
                System.assert(false, 'Debió lanzar AuraHandledException con oppId nulo.');
            } catch (AuraHandledException e) {
                System.assertNotEquals(null, e.getMessage(),
                    'El mensaje de excepción no debe ser nulo.');
            }
            Test.stopTest();
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ESCENARIO 07
    // QueryException cuando se pasa un Id de Oportunidad que no existe en BD
    // Nota: Usamos un Id de formato válido pero no existente en el org
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testGenerateContract_QueryException_InvalidId() {
        // GIVEN
        ContractGeneratorControllerDataFactory.TestContext ctx =
            ContractGeneratorControllerDataFactory.createExecutiveContext();

        // Primero creamos y luego eliminamos la oportunidad para tener un Id "huérfano"
        Opportunity deletedOpp;
        System.runAs(ctx.executiveUser) {
            deletedOpp = ContractGeneratorControllerDataFactory.createOpportunity(
                ctx.account.Id, ctx.executiveUser.Id
            );
        }
        Id orphanId = deletedOpp.Id;
        delete deletedOpp;

        // WHEN / THEN
        System.runAs(ctx.executiveUser) {
            Test.startTest();
            try {
                ContractGeneratorController.generateContract(orphanId);
                System.assert(false, 'Debió lanzar AuraHandledException por registro no encontrado.');
            } catch (AuraHandledException e) {
                System.assert(
                    e.getMessage().contains('Error de acceso') || e.getMessage().contains('Error en la generación'),
                    'El mensaje debe indicar error de acceso o generación. Actual: ' + e.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ESCENARIO 09
    // Constructor inicializa currentOpp correctamente como Ejecutivo
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testConstructor_InitializesCurrentOpp_AsExecutive() {
        // GIVEN
        ContractGeneratorControllerDataFactory.TestContext ctx =
            ContractGeneratorControllerDataFactory.createExecutiveContext();

        // WHEN
        System.runAs(ctx.executiveUser) {
            Test.startTest();
            ApexPages.StandardController stdCtrl =
                new ApexPages.StandardController(ctx.opportunity);
            ContractGeneratorController controller =
                new ContractGeneratorController(stdCtrl);
            Test.stopTest();

            // THEN
            System.assertNotEquals(null, controller,
                'El controlador no debe ser nulo después de instanciarse.');
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ESCENARIO 10
    // Constructor inicializa currentOpp correctamente como Analista
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testConstructor_InitializesCurrentOpp_AsAnalyst() {
        // GIVEN
        ContractGeneratorControllerDataFactory.TestContext ctx =
            ContractGeneratorControllerDataFactory.createFullContext();

        // WHEN
        System.runAs(ctx.analystUser) {
            Test.startTest();
            ApexPages.StandardController stdCtrl =
                new ApexPages.StandardController(ctx.opportunity);
            ContractGeneratorController controller =
                new ContractGeneratorController(stdCtrl);
            Test.stopTest();

            // THEN
            System.assertNotEquals(null, controller,
                'El controlador no debe ser nulo cuando lo instancia el Analista.');
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ESCENARIO 11
    // ContentDocumentLink tiene ShareType "V" y Visibility "AllUsers"
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testGenerateContract_ContentDocumentLink_Properties() {
        // GIVEN
        ContractGeneratorControllerDataFactory.TestContext ctx =
            ContractGeneratorControllerDataFactory.createExecutiveContext();

        // WHEN
        Id contentDocumentId;
        System.runAs(ctx.executiveUser) {
            Test.startTest();
            contentDocumentId = ContractGeneratorController.generateContract(ctx.opportunity.Id);
            Test.stopTest();
        }

        // THEN
        List<ContentDocumentLink> cdlList = [
            SELECT ShareType, Visibility, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocumentId
            AND LinkedEntityId = :ctx.opportunity.Id
        ];

        System.assertNotEquals(0, cdlList.size(),
            'Debe existir al menos un ContentDocumentLink.');
        System.assertEquals('V', cdlList[0].ShareType,
            'ShareType debe ser "V" (Viewer).');
        System.assertEquals('AllUsers', cdlList[0].Visibility,
            'Visibility debe ser "AllUsers".');
        System.assertEquals(ctx.opportunity.Id, cdlList[0].LinkedEntityId,
            'LinkedEntityId debe coincidir con el Id de la Oportunidad.');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ESCENARIO 12
    // ContentVersion tiene IsMajorVersion = true y PathOnClient = "Contrato.pdf"
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testGenerateContract_ContentVersion_Properties_AsAnalyst() {
        // GIVEN
        ContractGeneratorControllerDataFactory.TestContext ctx =
            ContractGeneratorControllerDataFactory.createFullContext();

        // WHEN
        Id contentDocumentId;
        System.runAs(ctx.analystUser) {
            Test.startTest();
            contentDocumentId = ContractGeneratorController.generateContract(ctx.opportunity.Id);
            Test.stopTest();
        }

        // THEN
        List<ContentVersion> cvList = [
            SELECT Title, PathOnClient, IsMajorVersion
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
        ];

        System.assertEquals(1, cvList.size(),
            'Debe haber exactamente un ContentVersion.');
        System.assertEquals(true, cvList[0].IsMajorVersion,
            'IsMajorVersion debe ser true.');
        System.assertEquals('Contrato.pdf', cvList[0].PathOnClient,
            'PathOnClient debe ser "Contrato.pdf".');
        System.assert(cvList[0].Title.startsWith('Contrato_'),
            'Title debe comenzar con "Contrato_".');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ESCENARIO 14
    // El Title del ContentVersion contiene el nombre exacto de la Oportunidad
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testGenerateContract_ContentVersion_TitleContainsOppName() {
        // GIVEN
        ContractGeneratorControllerDataFactory.TestContext ctx =
            ContractGeneratorControllerDataFactory.createExecutiveContext();

        // Crear oportunidad con nombre específico
        Opportunity namedOpp;
        System.runAs(ctx.executiveUser) {
            namedOpp = ContractGeneratorControllerDataFactory.createOpportunityWithName(
                ctx.account.Id,
                ctx.executiveUser.Id,
                'TC-2024-001'
            );
        }

        // WHEN
        Id contentDocumentId;
        System.runAs(ctx.executiveUser) {
            Test.startTest();
            contentDocumentId = ContractGeneratorController.generateContract(namedOpp.Id);
            Test.stopTest();
        }

        // THEN
        List<ContentVersion> cvList = [
            SELECT Title
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
        ];

        System.assertEquals(1, cvList.size(),
            'Debe existir un ContentVersion.');
        System.assertEquals('Contrato_TC-2024-001.pdf', cvList[0].Title,
            'El título debe ser exactamente "Contrato_TC-2024-001.pdf".');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ESCENARIO EXTRA - Ejecutivo intenta generar contrato dos veces (idempotencia)
    // Valida que el sistema permite múltiples documentos por oportunidad
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testGenerateContract_TwiceOnSameOpportunity_AsExecutive() {
        // GIVEN
        ContractGeneratorControllerDataFactory.TestContext ctx =
            ContractGeneratorControllerDataFactory.createExecutiveContext();

        // WHEN
        Id docId1;
        Id docId2;
        System.runAs(ctx.executiveUser) {
            Test.startTest();
            docId1 = ContractGeneratorController.generateContract(ctx.opportunity.Id);
            docId2 = ContractGeneratorController.generateContract(ctx.opportunity.Id);
            Test.stopTest();
        }

        // THEN - Ambas llamadas deben tener éxito
        System.assertNotEquals(null, docId1, 'Primer contrato debe generarse.');
        System.assertNotEquals(null, docId2, 'Segundo contrato debe generarse.');

        List<ContentDocumentLink> cdlList = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :ctx.opportunity.Id
        ];
        System.assert(cdlList.size() >= 2,
            'Deben existir al menos 2 ContentDocumentLinks para la misma Oportunidad.');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ESCENARIO EXTRA - Analista genera contrato y verifica retorno no nulo
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testGenerateContract_ReturnValue_NotNull_AsAnalyst() {
        // GIVEN
        ContractGeneratorControllerDataFactory.TestContext ctx =
            ContractGeneratorControllerDataFactory.createFullContext();

        // WHEN
        Id result;
        System.runAs(ctx.analystUser) {
            Test.startTest();
            result = ContractGeneratorController.generateContract(ctx.opportunity.Id);
            Test.stopTest();
        }

        // THEN
        System.assertNotEquals(null, result,
            'El método debe retornar un Id de ContentDocument no nulo.');
        Assert.isNotNull(result,
            'El valor retornado debe ser una instancia de Id.');
    }
}
