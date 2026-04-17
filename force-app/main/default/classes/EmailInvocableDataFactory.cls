/**
 * @description Data Factory para pruebas de EmailInvocable.
 *              Provee métodos para crear EmailRequest y datos de soporte
 *              usados por EmailInvocableTest.
 * @author      NovaBank Dev Team
 */
@isTest
public class EmailInvocableDataFactory {

    public static final String TEMPLATE_EMISION = 'Confirmacion_Emision_Tarjeta';

    // ─── Perfil y roles ───────────────────────────────────────────────────────

    public static Profile getBaseProfile() {
        List<Profile> profiles = [
            SELECT Id FROM Profile WHERE Name = 'Asesor de Venta y Reclamos' LIMIT 1
        ];
        if (!profiles.isEmpty()) return profiles[0];
        return [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    }

    public static UserRole getOrCreateEjecutivoRole() {
        List<UserRole> roles = [SELECT Id FROM UserRole WHERE Name = 'Ejecutivo' LIMIT 1];
        if (!roles.isEmpty()) return roles[0];
        UserRole r = new UserRole(Name = 'Ejecutivo', DeveloperName = 'Ejecutivo');
        insert r;
        return r;
    }

    // ─── Usuarios ─────────────────────────────────────────────────────────────

    public static User createEjecutivoUser() {
        Profile p  = getBaseProfile();
        UserRole r = getOrCreateEjecutivoRole();
        User u = new User(
            FirstName         = 'Executive',
            LastName          = 'Test',
            Email             = 'executive.invocable@novabank.test.com',
            Username          = 'executive.invocable.' + System.currentTimeMillis() + '@novabank.test.com',
            Alias             = 'einv',
            TimeZoneSidKey    = 'America/Lima',
            LocaleSidKey      = 'es_PE',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'es',
            ProfileId         = p.Id,
            UserRoleId        = r.Id
        );
        insert u;
        return u;
    }

    // ─── Datos de negocio ─────────────────────────────────────────────────────

    public static Account createAccount() {
        Account acc = new Account(Name = 'Cliente Invocable Test');
        insert acc;
        return acc;
    }

    public static Opportunity createOpportunity(Id accountId) {
        Opportunity opp = new Opportunity(
            Name      = 'Opp Invocable Test',
            AccountId = accountId,
            StageName = 'Inicio',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        return opp;
    }

    // ─── EmailRequest builders ────────────────────────────────────────────────

    /**
     * @description Construye un EmailRequest válido con los campos que AsyncEmailSender espera.
     */
    public static EmailRequest buildEmailRequest(Id recordId, Id accountId) {
        EmailRequest req    = new EmailRequest();
        req.recordId        = recordId;
        req.accountId       = accountId;
        req.templateApiName = TEMPLATE_EMISION;
        return req;
    }

    /**
     * @description Construye lista de N EmailRequests válidos.
     */
    public static List<EmailRequest> buildEmailRequestList(Id recordId, Id accountId, Integer count) {
        List<EmailRequest> requests = new List<EmailRequest>();
        for (Integer i = 0; i < count; i++) {
            EmailRequest req    = new EmailRequest();
            req.recordId        = recordId;
            req.accountId       = accountId;
            req.templateApiName = TEMPLATE_EMISION + '_' + i;
            requests.add(req);
        }
        return requests;
    }
}
