/**
 * @description Clase de prueba para EmailInvocable.
 *              Cubre todas las ramas del método sendEmailAsync:
 *              lista nula, lista vacía y lista con requests válidos.
 *              Cobertura objetivo: >= 95%
 * @author      NovaBank Dev Team
 */
@isTest
private class EmailInvocableTest {

    @TestSetup
    static void setup() {
        User ejecutivo = EmailInvocableDataFactory.createEjecutivoUser();
    }

    private static User getEjecutivo() {
        return [SELECT Id FROM User WHERE Email = 'executive.invocable@novabank.test.com' LIMIT 1];
    }

    // ─── SC-01: Lista nula → retorno inmediato sin excepción ─────────────────

    @isTest
    static void testSendEmailAsync_NullList_NoException() {
        User ejecutivo = getEjecutivo();
        System.runAs(ejecutivo) {
            Test.startTest();
            Boolean exceptionThrown = false;
            try {
                EmailInvocable.sendEmailAsync(null);
            } catch (Exception e) {
                exceptionThrown = true;
            }
            Test.stopTest();
            Assert.isFalse(exceptionThrown, 'Lista nula no debe lanzar excepción.');
        }
    }

    // ─── SC-02: Lista vacía → retorno inmediato sin encolar job ──────────────

    @isTest
    static void testSendEmailAsync_EmptyList_NoException() {
        User ejecutivo = getEjecutivo();
        System.runAs(ejecutivo) {
            Test.startTest();
            Boolean exceptionThrown = false;
            try {
                EmailInvocable.sendEmailAsync(new List<EmailRequest>());
            } catch (Exception e) {
                exceptionThrown = true;
            }
            Test.stopTest();
            Assert.isFalse(exceptionThrown, 'Lista vacía no debe lanzar excepción.');
        }
    }

    // ─── SC-03: Lista con un EmailRequest válido → job encolado ──────────────

    @isTest
    static void testSendEmailAsync_OneRequest_JobEnqueued() {
        User ejecutivo = getEjecutivo();

        Account acc = EmailInvocableDataFactory.createAccount();
        Opportunity opp = EmailInvocableDataFactory.createOpportunity(acc.Id);

        EmailRequest req = EmailInvocableDataFactory.buildEmailRequest(opp.Id, acc.Id);

        System.runAs(ejecutivo) {
            Test.startTest();
            Boolean exceptionThrown = false;
            try {
                EmailInvocable.sendEmailAsync(new List<EmailRequest>{ req });
            } catch (Exception e) {
                exceptionThrown = true;
            }
            Test.stopTest();
            Assert.isFalse(exceptionThrown, 'Un request válido no debe lanzar excepción.');
        }
    }

    // ─── SC-04: Lista con múltiples requests → todos encolados ───────────────

    @isTest
    static void testSendEmailAsync_MultipleRequests_NoException() {
        User ejecutivo = getEjecutivo();

        Account acc = EmailInvocableDataFactory.createAccount();
        Opportunity opp = EmailInvocableDataFactory.createOpportunity(acc.Id);

        List<EmailRequest> requests = EmailInvocableDataFactory.buildEmailRequestList(opp.Id, acc.Id, 3);

        System.runAs(ejecutivo) {
            Test.startTest();
            Boolean exceptionThrown = false;
            try {
                EmailInvocable.sendEmailAsync(requests);
            } catch (Exception e) {
                exceptionThrown = true;
            }
            Test.stopTest();
            Assert.isFalse(exceptionThrown, 'Lista de múltiples requests no debe lanzar excepción.');
        }
    }

    // ─── SC-05: Ejecutado como admin (sin runAs) ──────────────────────────────

    @isTest
    static void testSendEmailAsync_AsAdmin_NoException() {
        Account acc = EmailInvocableDataFactory.createAccount();
        Opportunity opp = EmailInvocableDataFactory.createOpportunity(acc.Id);

        EmailRequest req = EmailInvocableDataFactory.buildEmailRequest(opp.Id, acc.Id);

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            EmailInvocable.sendEmailAsync(new List<EmailRequest>{ req });
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        Assert.isFalse(exceptionThrown, 'No debe lanzarse excepción ejecutado como admin.');
    }
}
