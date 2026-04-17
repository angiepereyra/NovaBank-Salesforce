/**
 * @description  : Data Factory para pruebas de la clase EmailRequest.
 *                 Provee métodos de creación de datos de prueba para todos
 *                 los escenarios definidos en el Feature File de EmailRequest.
 *                 Cubre usuarios Ejecutivo y Analista, Accounts, Opportunities,
 *                 Cases, Financial Accounts y Email Templates.
 * @author       : NovaBank Dev Team
 * @project      : Gestión Integral Tarjeta de Crédito - Salesforce
 * @last modified: 04-16-2026
 **/
@IsTest
public class EmailRequestDataFactory {

    // =========================================================
    // CONSTANTES DE TEMPLATES
    // =========================================================
    public static final String TEMPLATE_EMISION       = 'Confirmacion_Emision_Tarjeta';
    public static final String TEMPLATE_CIERRE_CASO   = 'Cierre_Caso_Postventa';
    public static final String TEMPLATE_FINANCIAL_ACC = 'Emision_Tarjeta_Credito';
    public static final String TEMPLATE_CONTRATO      = 'Envio_Contrato_Oportunidad_Ganada';

    // =========================================================
    // USUARIOS DE PRUEBA
    // =========================================================

    /**
     * @description Crea y retorna un usuario con rol Ejecutivo.
     *              Perfil base: Standard User (simula "Asesor de Venta y Reclamos").
     * @return User usuario Ejecutivo listo para System.runAs()
     */
    public static User createEjecutivoUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User ejecutivo = new User(
            FirstName       = 'Carlos',
            LastName        = 'Ejecutivo Test',
            Email           = 'ejecutivo.test@novabank.com.invalid',
            Username        = 'ejecutivo.test.' + System.currentTimeMillis() + '@novabank.com.invalid',
            Alias           = 'ejec',
            TimeZoneSidKey  = 'America/Lima',
            LocaleSidKey    = 'es_PE',
            EmailEncodingKey= 'UTF-8',
            LanguageLocaleKey = 'es',
            ProfileId       = p.Id
        );
        insert ejecutivo;
        return ejecutivo;
    }

    /**
     * @description Crea y retorna un usuario con rol Analista.
     *              Perfil base: Standard User (simula "Asesor de Venta y Reclamos").
     * @return User usuario Analista listo para System.runAs()
     */
    public static User createAnalistaUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User analista = new User(
            FirstName        = 'Maria',
            LastName         = 'Analista Test',
            Email            = 'analista.test@novabank.com.invalid',
            Username         = 'analista.test.' + System.currentTimeMillis() + '@novabank.com.invalid',
            Alias            = 'anal',
            TimeZoneSidKey   = 'America/Lima',
            LocaleSidKey     = 'es_PE',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey= 'es',
            ProfileId        = p.Id
        );
        insert analista;
        return analista;
    }

    // =========================================================
    // ACCOUNTS
    // =========================================================

    /**
     * @description Crea e inserta una Account de persona natural para pruebas.
     * @param nombre Nombre del titular de la cuenta
     * @return Account insertada con Id asignado
     */
    public static Account createAccount(String nombre) {
        Account acc = new Account(
            Name        = nombre,
            Phone       = '+51999000001',
            BillingCity = 'Lima',
            BillingCountry = 'Peru'
        );
        insert acc;
        return acc;
    }

    /**
     * @description Crea e inserta múltiples Accounts para pruebas bulk.
     * @param cantidad Número de accounts a crear
     * @return List<Account> lista de accounts insertadas
     */
    public static List<Account> createAccounts(Integer cantidad) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < cantidad; i++) {
            accounts.add(new Account(
                Name        = 'Cliente Test ' + i,
                Phone       = '+5199900000' + i,
                BillingCity = 'Lima',
                BillingCountry = 'Peru'
            ));
        }
        insert accounts;
        return accounts;
    }

    // =========================================================
    // OPPORTUNITIES
    // =========================================================

    /**
     * @description Crea e inserta una Opportunity en estado Cerrada-Ganada.
     * @param accountId Id de la Account relacionada
     * @param nombre    Nombre de la oportunidad
     * @return Opportunity insertada
     */
    public static Opportunity createOpportunidadGanada(Id accountId, String nombre) {
        Opportunity opp = new Opportunity(
            Name        = nombre,
            AccountId   = accountId,
            StageName   = 'Closed Won',
            CloseDate   = Date.today(),
            Amount      = 5000
        );
        insert opp;
        return opp;
    }

    /**
     * @description Crea e inserta una Opportunity en etapa de Inicio.
     * @param accountId Id de la Account relacionada
     * @return Opportunity insertada en etapa Inicio
     */
    public static Opportunity createOpportunidadInicio(Id accountId) {
        Opportunity opp = new Opportunity(
            Name        = 'Opp Inicio Test',
            AccountId   = accountId,
            StageName   = 'Prospecting',
            CloseDate   = Date.today().addDays(30),
            Amount      = 2000
        );
        insert opp;
        return opp;
    }

    /**
     * @description Crea múltiples Opportunities en estado Cerrada-Ganada para pruebas bulk.
     * @param accounts Lista de Accounts para asociar cada oportunidad
     * @return List<Opportunity> lista de oportunidades insertadas
     */
    public static List<Opportunity> createOpportunidadesGanadas(List<Account> accounts) {
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < accounts.size(); i++) {
            opps.add(new Opportunity(
                Name      = 'Opp Ganada Test ' + i,
                AccountId = accounts[i].Id,
                StageName = 'Closed Won',
                CloseDate = Date.today(),
                Amount    = 5000 + (i * 1000)
            ));
        }
        insert opps;
        return opps;
    }

    // =========================================================
    // CASES (Postventa)
    // =========================================================

    /**
     * @description Crea e inserta un Case en estado "En Revisión" para postventa.
     * @param accountId Id de la Account relacionada
     * @return Case insertado
     */
    public static Case createCase(Id accountId) {
        Case c = new Case(
            AccountId   = accountId,
            Status      = 'New',
            Origin      = 'Web',
            Subject     = 'Reclamo Test - Consumo Duplicado',
            Priority    = 'High',
            Description = 'Consumo duplicado detectado en estado de cuenta.'
        );
        insert c;
        return c;
    }

    // =========================================================
    // EMAIL TEMPLATES
    // =========================================================

    /**
     * @description Crea e inserta un EmailTemplate de prueba con el API name indicado.
     *              NOTA: En entornos reales los templates se crean en Setup.
     *              En test se inserta directamente para tener el Id referenciable.
     * @param apiName API Name único del template
     * @param nombre  Nombre legible del template
     * @return EmailTemplate insertado
     */
    public static EmailTemplate createEmailTemplate(String apiName, String nombre) {
        // Los EmailTemplates requieren un Folder. Usamos el folder personal del usuario corriente.
        EmailTemplate et = new EmailTemplate(
            Name       = nombre,
            DeveloperName = apiName,
            FolderId   = UserInfo.getUserId(), // Folder personal del usuario en test
            Subject    = 'Notificación NovaBank - ' + nombre,
            Body       = 'Estimado cliente, adjuntamos información sobre su solicitud.',
            HtmlValue  = '<p>Estimado cliente, adjuntamos información sobre su solicitud.</p>',
            TemplateType = 'text',
            IsActive   = true
        );
        insert et;
        return et;
    }

    // =========================================================
    // BUILDERS DE EmailRequest
    // =========================================================

    /**
     * @description Construye un EmailRequest con los tres campos asignados.
     * @param recordId       Id del registro origen (Opportunity, Case, FinancialAccount)
     * @param accountId      Id de la Account del cliente
     * @param templateApiName Nombre del template de correo
     * @return EmailRequest instanciado y con campos asignados
     */
    public static EmailRequest buildEmailRequest(Id recordId, Id accountId, String templateApiName) {
        EmailRequest req = new EmailRequest();
        req.recordId        = recordId;
        req.accountId       = accountId;
        req.templateApiName = templateApiName;
        return req;
    }

    /**
     * @description Construye un EmailRequest vacío (sin asignar campos).
     * @return EmailRequest con todos los campos nulos
     */
    public static EmailRequest buildEmailRequestVacio() {
        return new EmailRequest();
    }

    /**
     * @description Construye una lista de EmailRequests para pruebas bulk.
     * @param opps     Lista de Opportunities
     * @param accounts Lista de Accounts correspondientes
     * @param template API Name del template a usar
     * @return List<EmailRequest> lista de requests construidos
     */
    public static List<EmailRequest> buildEmailRequestList(
        List<Opportunity> opps,
        List<Account>     accounts,
        String            template
    ) {
        List<EmailRequest> requests = new List<EmailRequest>();
        for (Integer i = 0; i < opps.size(); i++) {
            EmailRequest req = new EmailRequest();
            req.recordId        = opps[i].Id;
            req.accountId       = accounts[i].Id;
            req.templateApiName = template;
            requests.add(req);
        }
        return requests;
    }

    /**
     * @description Construye un EmailRequest para contexto de Caso de Postventa.
     * @param caseId    Id del Case
     * @param accountId Id de la Account
     * @return EmailRequest configurado para cierre de caso
     */
    public static EmailRequest buildEmailRequestForCase(Id caseId, Id accountId) {
        EmailRequest req = new EmailRequest();
        req.recordId        = caseId;
        req.accountId       = accountId;
        req.templateApiName = TEMPLATE_CIERRE_CASO;
        return req;
    }

    /**
     * @description Construye un EmailRequest para contexto de Oportunidad Ganada.
     * @param oppId     Id de la Opportunity
     * @param accountId Id de la Account
     * @return EmailRequest configurado para envío de contrato
     */
    public static EmailRequest buildEmailRequestForOppGanada(Id oppId, Id accountId) {
        EmailRequest req = new EmailRequest();
        req.recordId        = oppId;
        req.accountId       = accountId;
        req.templateApiName = TEMPLATE_CONTRATO;
        return req;
    }
}
