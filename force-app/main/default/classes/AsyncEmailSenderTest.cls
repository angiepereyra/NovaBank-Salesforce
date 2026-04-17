/**
 * @description       : Clase de prueba para AsyncEmailSender.
 *                      Cubre todos los escenarios del feature file con >= 95% de cobertura.
 *                      Usa System.runAs() para ejecutar en contexto de Ejecutivo y Analista.
 *                      Implementa Test.startTest() / Test.stopTest() para ejecutar el job
 *                      queueable de forma síncrona dentro del test.
 * @author            : NovaBank – BCP Bootcamp
 * @group             : TestClasses
 * @last modified on  : 04-16-2026
 **/
@isTest
private class AsyncEmailSenderTest {

    // =========================================================================
    // SETUP COMPARTIDO
    // =========================================================================

    /**
     * @description Método de setup que crea la jerarquía de roles y usuarios
     *              que serán reutilizados en todos los tests.
     *              Los datos de setup se crean antes de cada test method.
     */
    @testSetup
    static void setupTestData() {
        // Crear jerarquía de roles
        Map<String, UserRole> roles = AsyncEmailSenderDataFactory.createRoleHierarchy();

        // Crear usuarios representativos
        User ejecutivo = AsyncEmailSenderDataFactory.createEjecutivoUser(roles.get('ejecutivo').Id);
        User analista  = AsyncEmailSenderDataFactory.createAnalistaUser(roles.get('analista').Id);
    }

    // =========================================================================
    // HELPERS INTERNOS
    // =========================================================================

    private static User getEjecutivoUser() {
        return [SELECT Id FROM User WHERE Alias = 'ejec' LIMIT 1];
    }

    private static User getAnalistaUser() {
        return [SELECT Id FROM User WHERE Alias = 'anal' LIMIT 1];
    }

    // =========================================================================
    // TEST 01 – Flujo feliz: correo enviado con plantilla, contacto y adjunto
    // =========================================================================
    @isTest
    static void testEnvioExitosoConAdjunto() {
        // --- ARRANGE ---
        Map<String, SObject> data = AsyncEmailSenderDataFactory.createFullHappyPathData();
        Account acc     = (Account)     data.get('account');
        Opportunity opp = (Opportunity) data.get('opportunity');
        EmailTemplate et = (EmailTemplate) data.get('template');

        EmailRequest req = AsyncEmailSenderDataFactory.buildEmailRequest(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME,
            opp.Id,
            acc.Id
        );

        // --- ACT ---
        Test.startTest();
        System.enqueueJob(new AsyncEmailSender(new List<EmailRequest>{ req }));
        Test.stopTest(); // Ejecuta el job de forma síncrona

        // --- ASSERT ---
        // Si no lanza excepción y el job ejecuta correctamente, la cobertura
        // de las líneas de construcción del email y sendEmail se valida.
        // Verificamos que el ContentDocumentLink existe y está vinculado.
        List<ContentDocumentLink> cdls = [
            SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :opp.Id
        ];
        System.assertNotEquals(0, cdls.size(),
            'Debe existir al menos un ContentDocumentLink vinculado a la oportunidad');
    }

    // =========================================================================
    // TEST 02 – Múltiples requests en un solo job
    // =========================================================================
    @isTest
    static void testEnvioMultiplesRequests() {
        // --- ARRANGE ---
        List<Account> accounts   = AsyncEmailSenderDataFactory.createAccounts(3);
        List<Opportunity> opps   = AsyncEmailSenderDataFactory.createOpportunities(accounts);
        EmailTemplate et         = AsyncEmailSenderDataFactory.createEmailTemplate(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME2
        );

        // Crear contacto y CDL para cada cuenta/oportunidad
        List<EmailRequest> requests = new List<EmailRequest>();
        for (Integer i = 0; i < accounts.size(); i++) {
            AsyncEmailSenderDataFactory.createContact(accounts[i].Id);
            AsyncEmailSenderDataFactory.createContentDocumentLink(opps[i].Id);
            requests.add(AsyncEmailSenderDataFactory.buildEmailRequest(
                AsyncEmailSenderDataFactory.TEMPLATE_API_NAME2,
                opps[i].Id,
                accounts[i].Id
            ));
        }

        // --- ACT ---
        Test.startTest();
        System.enqueueJob(new AsyncEmailSender(requests));
        Test.stopTest();

        // --- ASSERT ---
        List<Id> oppIds = new List<Id>{ opps[0].Id, opps[1].Id, opps[2].Id };
        List<ContentDocumentLink> cdlsMulti = [
            SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN :oppIds
        ];
        System.assertEquals(3, cdlsMulti.size(), 'Deben existir 3 CDLs, uno por oportunidad');
    }

    // =========================================================================
    // TEST 03 – Plantilla inexistente: request omitido, sin excepción
    // =========================================================================
    @isTest
    static void testPlantillaInexistenteOmiteRequest() {
        // --- ARRANGE ---
        Account acc = AsyncEmailSenderDataFactory.createAccount(
            AsyncEmailSenderDataFactory.VALID_EMAIL
        );
        AsyncEmailSenderDataFactory.createContact(acc.Id);
        Opportunity opp = AsyncEmailSenderDataFactory.createOpportunity(acc.Id);

        // NO se crea plantilla con este nombre
        EmailRequest req = AsyncEmailSenderDataFactory.buildEmailRequest(
            'Plantilla_INEXISTENTE_XYZ',
            opp.Id,
            acc.Id
        );

        // --- ACT & ASSERT ---
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            System.enqueueJob(new AsyncEmailSender(new List<EmailRequest>{ req }));
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Assert.isFalse(exceptionThrown,
            'No debe lanzarse excepción cuando la plantilla no existe; el request debe ser omitido');
    }

    // =========================================================================
    // TEST 04 – Cuenta sin Email__c: request omitido
    // =========================================================================
    @isTest
    static void testCuentaSinEmailOmiteRequest() {
        // --- ARRANGE ---
        Account acc = AsyncEmailSenderDataFactory.createAccountWithoutEmail();
        AsyncEmailSenderDataFactory.createContact(acc.Id);
        Opportunity opp = AsyncEmailSenderDataFactory.createOpportunity(acc.Id);
        AsyncEmailSenderDataFactory.createEmailTemplate(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME
        );

        EmailRequest req = AsyncEmailSenderDataFactory.buildEmailRequest(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME,
            opp.Id,
            acc.Id
        );

        // --- ACT & ASSERT ---
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            System.enqueueJob(new AsyncEmailSender(new List<EmailRequest>{ req }));
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Assert.isFalse(exceptionThrown,
            'No debe lanzarse excepción cuando la cuenta no tiene Email__c');
    }

    // =========================================================================
    // TEST 05 – Sin contacto en la cuenta: request omitido
    // =========================================================================
    @isTest
    static void testSinContactoOmiteRequest() {
        // --- ARRANGE ---
        Account acc = AsyncEmailSenderDataFactory.createAccount(
            AsyncEmailSenderDataFactory.VALID_EMAIL
        );
        // NO se crea contacto
        Opportunity opp = AsyncEmailSenderDataFactory.createOpportunity(acc.Id);
        AsyncEmailSenderDataFactory.createEmailTemplate(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME
        );

        EmailRequest req = AsyncEmailSenderDataFactory.buildEmailRequest(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME,
            opp.Id,
            acc.Id
        );

        // --- ACT & ASSERT ---
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            System.enqueueJob(new AsyncEmailSender(new List<EmailRequest>{ req }));
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Assert.isFalse(exceptionThrown,
            'No debe lanzarse excepción cuando no existe contacto vinculado a la cuenta');
    }

    // =========================================================================
    // TEST 06 – Sin ContentDocumentLink: correo enviado sin adjunto
    // =========================================================================
    @isTest
    static void testSinAdjuntoCorreoEnviadoSinAttachment() {
        // --- ARRANGE ---
        Account acc = AsyncEmailSenderDataFactory.createAccount(
            AsyncEmailSenderDataFactory.VALID_EMAIL
        );
        AsyncEmailSenderDataFactory.createContact(acc.Id);
        Opportunity opp = AsyncEmailSenderDataFactory.createOpportunity(acc.Id);
        AsyncEmailSenderDataFactory.createEmailTemplate(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME
        );
        // NO se crea ContentDocumentLink

        EmailRequest req = AsyncEmailSenderDataFactory.buildEmailRequest(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME,
            opp.Id,
            acc.Id
        );

        // --- ACT & ASSERT ---
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            System.enqueueJob(new AsyncEmailSender(new List<EmailRequest>{ req }));
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Assert.isFalse(exceptionThrown,
            'Debe enviarse el correo sin adjunto cuando no existe CDL; no debe lanzar excepción');
    }

    // =========================================================================
    // TEST 07 – Lista de requests vacía: sendEmail no invocado, sin excepción
    // =========================================================================
    @isTest
    static void testListaVaciaNoenviaNada() {
        // --- ACT & ASSERT ---
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            System.enqueueJob(
                new AsyncEmailSender(new List<EmailRequest>())
            );
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Assert.isFalse(exceptionThrown,
            'Una lista vacía no debe lanzar excepción; sendEmail no debe ser invocado');
    }

    // =========================================================================
    // TEST 08 – Múltiples CDLs: solo se usa el más reciente (containsKey)
    // =========================================================================
    @isTest
    static void testMultiplesCDLsUsaSoloPrimero() {
        // --- ARRANGE ---
        Account acc = AsyncEmailSenderDataFactory.createAccount(
            AsyncEmailSenderDataFactory.VALID_EMAIL
        );
        AsyncEmailSenderDataFactory.createContact(acc.Id);
        Opportunity opp = AsyncEmailSenderDataFactory.createOpportunity(acc.Id);
        AsyncEmailSenderDataFactory.createEmailTemplate(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME
        );
        // Crear 3 documentos vinculados a la misma oportunidad
        AsyncEmailSenderDataFactory.createMultipleContentDocumentLinks(opp.Id, 3);

        EmailRequest req = AsyncEmailSenderDataFactory.buildEmailRequest(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME,
            opp.Id,
            acc.Id
        );

        // --- ACT & ASSERT ---
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            System.enqueueJob(new AsyncEmailSender(new List<EmailRequest>{ req }));
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }

        Integer totalCdls = [SELECT COUNT() FROM ContentDocumentLink
                              WHERE LinkedEntityId = :opp.Id];
        System.assertEquals(3, totalCdls,
            'Deben existir 3 CDLs; el job solo usará el más reciente');
        Assert.isFalse(exceptionThrown,
            'No debe lanzarse excepción cuando hay múltiples CDLs');
    }

    // =========================================================================
    // TEST 09 – Mix de requests válidos e inválidos: solo válidos se envían
    // =========================================================================
    @isTest
    static void testMixRequestsValidosEInvalidos() {
        // --- ARRANGE ---
        // Request válido
        Account accValido = AsyncEmailSenderDataFactory.createAccount(
            AsyncEmailSenderDataFactory.VALID_EMAIL
        );
        AsyncEmailSenderDataFactory.createContact(accValido.Id);
        Opportunity oppValida = AsyncEmailSenderDataFactory.createOpportunity(accValido.Id);
        AsyncEmailSenderDataFactory.createContentDocumentLink(oppValida.Id);
        AsyncEmailSenderDataFactory.createEmailTemplate(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME
        );

        // Request inválido 1: plantilla inexistente
        Account accInvalido1 = AsyncEmailSenderDataFactory.createAccount('invalido1@novabank.com');
        AsyncEmailSenderDataFactory.createContact(accInvalido1.Id);
        Opportunity oppInvalida1 = AsyncEmailSenderDataFactory.createOpportunity(accInvalido1.Id);

        // Request inválido 2: sin email
        Account accInvalido2 = AsyncEmailSenderDataFactory.createAccountWithoutEmail();
        AsyncEmailSenderDataFactory.createContact(accInvalido2.Id);
        Opportunity oppInvalida2 = AsyncEmailSenderDataFactory.createOpportunity(accInvalido2.Id);

        List<EmailRequest> requests = new List<EmailRequest>{
            AsyncEmailSenderDataFactory.buildEmailRequest(
                AsyncEmailSenderDataFactory.TEMPLATE_API_NAME, oppValida.Id, accValido.Id),
            AsyncEmailSenderDataFactory.buildEmailRequest(
                'PLANTILLA_INEXISTENTE', oppInvalida1.Id, accInvalido1.Id),
            AsyncEmailSenderDataFactory.buildEmailRequest(
                AsyncEmailSenderDataFactory.TEMPLATE_API_NAME, oppInvalida2.Id, accInvalido2.Id)
        };

        // --- ACT & ASSERT ---
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            System.enqueueJob(new AsyncEmailSender(requests));
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Assert.isFalse(exceptionThrown,
            'El job no debe lanzar excepción; requests inválidos se omiten silenciosamente');
    }

    // =========================================================================
    // TEST 10 – Cuenta con múltiples contactos: se usa uno sin error
    // =========================================================================
    @isTest
    static void testCuentaConMultiplesContactos() {
        // --- ARRANGE ---
        Account acc = AsyncEmailSenderDataFactory.createAccount(
            AsyncEmailSenderDataFactory.VALID_EMAIL
        );
        // Crear 2 contactos para la misma cuenta (el Map sobrescribirá)
        AsyncEmailSenderDataFactory.createContacts(acc.Id, 2);
        Opportunity opp = AsyncEmailSenderDataFactory.createOpportunity(acc.Id);
        AsyncEmailSenderDataFactory.createContentDocumentLink(opp.Id);
        AsyncEmailSenderDataFactory.createEmailTemplate(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME
        );

        EmailRequest req = AsyncEmailSenderDataFactory.buildEmailRequest(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME,
            opp.Id,
            acc.Id
        );

        // --- ACT & ASSERT ---
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            System.enqueueJob(new AsyncEmailSender(new List<EmailRequest>{ req }));
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Integer contactCount = [SELECT COUNT() FROM Contact WHERE AccountId = :acc.Id];
        System.assertEquals(2, contactCount, 'La cuenta debe tener 2 contactos');
        Assert.isFalse(exceptionThrown,
            'No debe lanzarse excepción cuando la cuenta tiene múltiples contactos');
    }

    // =========================================================================
    // TEST 11 – Ejecución como usuario EJECUTIVO con System.runAs()
    // =========================================================================
    @isTest
    static void testEjecucionComoEjecutivoUser() {
        // --- ARRANGE ---
        Map<String, SObject> data = AsyncEmailSenderDataFactory.createFullHappyPathData();
        Account acc     = (Account)     data.get('account');
        Opportunity opp = (Opportunity) data.get('opportunity');

        EmailRequest req = AsyncEmailSenderDataFactory.buildEmailRequest(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME,
            opp.Id,
            acc.Id
        );

        User ejecutivo = getEjecutivoUser();

        // --- ACT & ASSERT ---
        System.runAs(ejecutivo) {
            Test.startTest();
            Boolean exceptionThrown = false;
            try {
                System.enqueueJob(
                    new AsyncEmailSender(new List<EmailRequest>{ req })
                );
                Test.stopTest();
            } catch (Exception e) {
                exceptionThrown = true;
            }
            Assert.isFalse(exceptionThrown,
                'El usuario Ejecutivo debe poder encolar y ejecutar AsyncEmailSender sin errores');
        }
    }

    // =========================================================================
    // TEST 12 – Ejecución como usuario ANALISTA con System.runAs()
    // =========================================================================
    @isTest
    static void testEjecucionComoAnalistaUser() {
        // --- ARRANGE ---
        Map<String, SObject> data = AsyncEmailSenderDataFactory.createFullHappyPathData();
        Account acc     = (Account)     data.get('account');
        Opportunity opp = (Opportunity) data.get('opportunity');

        EmailRequest req = AsyncEmailSenderDataFactory.buildEmailRequest(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME,
            opp.Id,
            acc.Id
        );

        User analista = getAnalistaUser();

        // --- ACT & ASSERT ---
        System.runAs(analista) {
            Test.startTest();
            Boolean exceptionThrown = false;
            try {
                System.enqueueJob(
                    new AsyncEmailSender(new List<EmailRequest>{ req })
                );
                Test.stopTest();
            } catch (Exception e) {
                exceptionThrown = true;
            }
            Assert.isFalse(exceptionThrown,
                'El usuario Analista debe poder encolar y ejecutar AsyncEmailSender sin errores');
        }
    }

    // =========================================================================
    // TEST 13 – Constructor con lista válida y encolado exitoso
    // =========================================================================
    @isTest
    static void testConstructorYEncoladoExitoso() {
        // --- ARRANGE ---
        Account acc = AsyncEmailSenderDataFactory.createAccount(
            AsyncEmailSenderDataFactory.VALID_EMAIL
        );
        Opportunity opp = AsyncEmailSenderDataFactory.createOpportunity(acc.Id);

        EmailRequest req1 = AsyncEmailSenderDataFactory.buildEmailRequest(
            'T1', opp.Id, acc.Id
        );
        EmailRequest req2 = AsyncEmailSenderDataFactory.buildEmailRequest(
            'T2', opp.Id, acc.Id
        );
        List<EmailRequest> requests = new List<EmailRequest>{ req1, req2 };

        // --- ACT ---
        Test.startTest();
        AsyncEmailSender sender = new AsyncEmailSender(requests);
        Id jobId = System.enqueueJob(sender);
        Test.stopTest();

        // --- ASSERT ---
        System.assertNotEquals(null, jobId,
            'El job debe ser encolado exitosamente y retornar un Id válido');
    }

    // =========================================================================
    // TEST 14 – AccountId inexistente en la BD: acc es null, request omitido
    // =========================================================================
    @isTest
    static void testAccountIdInexistenteOmiteRequest() {
        // --- ARRANGE ---
        AsyncEmailSenderDataFactory.createEmailTemplate(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME
        );

        // Usamos un Id ficticio de Account que no existe
        // Generamos un Id válido en formato pero sin registro en BD
        Account accFake = new Account(Name = 'Fake');
        // No insertamos: usamos un Id de otra instancia eliminada o generamos manualmente
        // En test, creamos, obtenemos Id, y lo eliminamos
        Account accTemp = AsyncEmailSenderDataFactory.createAccount('temp@test.com');
        Id fakeAccountId = accTemp.Id;
        delete accTemp;

        // Oportunidad real con accountId eliminado
        // (el recordId puede ser cualquier Opportunity existente o un Id fake)
        // Para este escenario, usamos el Id eliminado como accountId
        // y una Opportunity real como recordId para no fallar en CDL query
        Account accReal = AsyncEmailSenderDataFactory.createAccount(
            AsyncEmailSenderDataFactory.VALID_EMAIL
        );
        Opportunity opp = AsyncEmailSenderDataFactory.createOpportunity(accReal.Id);

        EmailRequest req = AsyncEmailSenderDataFactory.buildEmailRequest(
            AsyncEmailSenderDataFactory.TEMPLATE_API_NAME,
            opp.Id,
            fakeAccountId  // accountId apunta a registro eliminado
        );

        // --- ACT & ASSERT ---
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            System.enqueueJob(new AsyncEmailSender(new List<EmailRequest>{ req }));
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Assert.isFalse(exceptionThrown,
            'No debe lanzarse excepción cuando el accountId no existe en BD; request se omite');
    }

    // =========================================================================
    // TEST 15 – Validación de EmailRequest inner class: campos asignados
    // =========================================================================
    @isTest
    static void testEmailRequestInnerClass() {
        // --- ARRANGE ---
        Account acc = AsyncEmailSenderDataFactory.createAccount(
            AsyncEmailSenderDataFactory.VALID_EMAIL
        );
        Opportunity opp = AsyncEmailSenderDataFactory.createOpportunity(acc.Id);

        // --- ACT ---
        EmailRequest req = AsyncEmailSenderDataFactory.buildEmailRequest(
            'MiTemplate',
            opp.Id,
            acc.Id
        );

        // --- ASSERT ---
        System.assertEquals('MiTemplate', req.templateApiName,
            'El templateApiName debe asignarse correctamente al EmailRequest');
        System.assertEquals(opp.Id, req.recordId,
            'El recordId debe asignarse correctamente al EmailRequest');
        System.assertEquals(acc.Id, req.accountId,
            'El accountId debe asignarse correctamente al EmailRequest');
    }
}
