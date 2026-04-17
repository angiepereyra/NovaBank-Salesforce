/**
 * @description       : Data Factory para las clases de prueba de AsyncEmailSender.
 *                      Provee métodos estáticos que crean y persisten los registros
 *                      necesarios para cubrir todos los escenarios del feature file.
 * @author            : NovaBank – BCP Bootcamp
 * @group             : TestDataFactory
 * @last modified on  : 04-16-2026
 **/
@isTest
public class AsyncEmailSenderDataFactory {

    // =========================================================================
    // CONSTANTES REUTILIZABLES
    // =========================================================================
    public static final String TEMPLATE_API_NAME  = 'Plantilla_Bienvenida';
    public static final String TEMPLATE_API_NAME2 = 'Plantilla_Cierre';
    public static final String VALID_EMAIL        = 'cliente@novabank.com';
    public static final String PROFILE_NAME       = 'Asesor de Venta y Reclamos';

    // =========================================================================
    // USUARIOS DE PRUEBA
    // =========================================================================

    /**
     * @description Crea y retorna el usuario Ejecutivo de prueba.
     *              Debe usarse dentro de System.runAs() en las test classes.
     * @param roleId Id del rol Ejecutivo previamente creado
     * @return User insertado con perfil base y rol Ejecutivo
     */
    public static User createEjecutivoUser(Id roleId) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName       = 'Ejecutivo',
            LastName        = 'Test',
            Email           = 'ejecutivo_test@novabank.test.com',
            Username        = 'ejecutivo_test_' + DateTime.now().getTime() + '@novabank.test.com',
            Alias           = 'ejec',
            TimeZoneSidKey  = 'America/Lima',
            LocaleSidKey    = 'es_PE',
            EmailEncodingKey= 'UTF-8',
            LanguageLocaleKey = 'es',
            ProfileId       = p.Id,
            UserRoleId      = roleId
        );
        insert u;
        return u;
    }

    /**
     * @description Crea y retorna el usuario Analista de prueba.
     * @param roleId Id del rol Analista previamente creado
     * @return User insertado con perfil base y rol Analista
     */
    public static User createAnalistaUser(Id roleId) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName       = 'Analista',
            LastName        = 'Test',
            Email           = 'analista_test@novabank.test.com',
            Username        = 'analista_test_' + DateTime.now().getTime() + '@novabank.test.com',
            Alias           = 'anal',
            TimeZoneSidKey  = 'America/Lima',
            LocaleSidKey    = 'es_PE',
            EmailEncodingKey= 'UTF-8',
            LanguageLocaleKey = 'es',
            ProfileId       = p.Id,
            UserRoleId      = roleId
        );
        insert u;
        return u;
    }

    /**
     * @description Crea la jerarquía de roles Ejecutivo → Analista.
     * @return Map con las claves 'ejecutivo' y 'analista' y sus respectivos UserRole
     */
    public static Map<String, UserRole> createRoleHierarchy() {
        UserRole ejecutivoRole = new UserRole(Name = 'Ejecutivo_Test_Role_' + DateTime.now().getTime());
        insert ejecutivoRole;

        UserRole analistaRole = new UserRole(
            Name           = 'Analista_Test_Role_' + DateTime.now().getTime(),
            ParentRoleId   = ejecutivoRole.Id
        );
        insert analistaRole;

        return new Map<String, UserRole>{
            'ejecutivo' => ejecutivoRole,
            'analista'  => analistaRole
        };
    }

    // =========================================================================
    // ACCOUNTS
    // =========================================================================

    /**
     * @description Crea una cuenta con Email__c válido.
     * @param email Dirección de correo del cliente
     * @return Account insertada
     */
    public static Account createAccount(String email) {
        Account acc = new Account(
            Name      = 'Cliente Test ' + DateTime.now().getTime(),
            Email__c  = email
        );
        insert acc;
        return acc;
    }

    /**
     * @description Crea una cuenta SIN Email__c (null).
     * @return Account insertada con Email__c vacío
     */
    public static Account createAccountWithoutEmail() {
        Account acc = new Account(
            Name     = 'Cliente Sin Email ' + DateTime.now().getTime(),
            Email__c = null
        );
        insert acc;
        return acc;
    }

    /**
     * @description Crea N cuentas con Email__c válido.
     * @param count Número de cuentas a crear
     * @return List<Account> insertadas
     */
    public static List<Account> createAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(
                Name     = 'Cliente Test ' + i + '_' + DateTime.now().getTime(),
                Email__c = 'cliente' + i + '@novabank.com'
            ));
        }
        insert accounts;
        return accounts;
    }

    // =========================================================================
    // CONTACTS
    // =========================================================================

    /**
     * @description Crea un contacto vinculado a una cuenta.
     * @param accountId Id de la cuenta a la que se vincula el contacto
     * @return Contact insertado
     */
    public static Contact createContact(Id accountId) {
        Contact con = new Contact(
            LastName  = 'ContactTest',
            FirstName = 'NovaBank',
            AccountId = accountId,
            Email     = 'contacto@novabank.com'
        );
        insert con;
        return con;
    }

    /**
     * @description Crea múltiples contactos vinculados a la misma cuenta.
     * @param accountId Id de la cuenta
     * @param count Cantidad de contactos
     * @return List<Contact> insertados
     */
    public static List<Contact> createContacts(Id accountId, Integer count) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            contacts.add(new Contact(
                LastName  = 'Contact_' + i,
                AccountId = accountId
            ));
        }
        insert contacts;
        return contacts;
    }

    // =========================================================================
    // OPORTUNIDADES
    // =========================================================================

    /**
     * @description Crea una oportunidad vinculada a una cuenta.
     * @param accountId Id de la cuenta
     * @return Opportunity insertada en etapa 'Inicio'
     */
    public static Opportunity createOpportunity(Id accountId) {
        Opportunity opp = new Opportunity(
            Name        = 'Opp Test ' + DateTime.now().getTime(),
            AccountId   = accountId,
            StageName   = 'Inicio',
            CloseDate   = Date.today().addDays(30)
        );
        insert opp;
        return opp;
    }

    /**
     * @description Crea N oportunidades, una por cada cuenta en la lista.
     * @param accounts Lista de cuentas
     * @return List<Opportunity> insertadas
     */
    public static List<Opportunity> createOpportunities(List<Account> accounts) {
        List<Opportunity> opps = new List<Opportunity>();
        for (Account acc : accounts) {
            opps.add(new Opportunity(
                Name      = 'Opp Test ' + acc.Name,
                AccountId = acc.Id,
                StageName = 'Inicio',
                CloseDate = Date.today().addDays(30)
            ));
        }
        insert opps;
        return opps;
    }

    // =========================================================================
    // CONTENT DOCUMENTS (adjuntos PDF)
    // =========================================================================

    /**
     * @description Crea un ContentVersion y lo vincula al record indicado.
     *              Retorna el ContentDocumentLink creado.
     * @param recordId Id del record al que se adjunta el documento
     * @return ContentDocumentLink vinculado al record
     */
    public static ContentDocumentLink createContentDocumentLink(Id recordId) {
        // Crear versión del contenido (simula un PDF)
        ContentVersion cv = new ContentVersion(
            Title           = 'Contrato_Test',
            PathOnClient    = 'Contrato_Test.pdf',
            VersionData     = Blob.valueOf('Contrato PDF simulado para pruebas'),
            IsMajorVersion  = true
        );
        insert cv;

        // Recuperar el ContentDocumentId generado automáticamente
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        // Vincular al record
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId    = recordId,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
        insert cdl;
        return cdl;
    }

    /**
     * @description Crea N ContentDocumentLinks para el mismo record (para escenario multi-doc).
     * @param recordId Id del record
     * @param count Número de documentos a vincular
     * @return List<ContentDocumentLink> insertados
     */
    public static List<ContentDocumentLink> createMultipleContentDocumentLinks(Id recordId, Integer count) {
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
        for (Integer i = 0; i < count; i++) {
            ContentVersion cv = new ContentVersion(
                Title          = 'Doc_' + i,
                PathOnClient   = 'Doc_' + i + '.pdf',
                VersionData    = Blob.valueOf('Contenido doc ' + i),
                IsMajorVersion = true
            );
            insert cv;
            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId    = recordId,
                ShareType         = 'V',
                Visibility        = 'AllUsers'
            );
            insert cdl;
            cdls.add(cdl);
        }
        return cdls;
    }

    // =========================================================================
    // EMAIL TEMPLATES
    // =========================================================================

    /**
     * @description Crea una plantilla de correo con el DeveloperName indicado.
     *              En entornos de prueba, las EmailTemplate deben insertarse
     *              con HtmlValue o Body según el tipo.
     * @param developerName API Name de la plantilla
     * @return EmailTemplate insertada
     */
    public static EmailTemplate createEmailTemplate(String developerName) {
        // Requiere un folder: se usa el folder del usuario actual (My Personal Email Templates)
        OrgWideEmailAddress[] owas = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];

        EmailTemplate et = new EmailTemplate(
            DeveloperName = developerName,
            Name          = developerName.replace('_', ' '),
            FolderId      = UserInfo.getUserId(), // folder personal del usuario de prueba
            TemplateType  = 'text',
            Subject       = 'Asunto de prueba - {!Opportunity.Name}',
            Body          = 'Estimado cliente, le confirmamos la emisión de su tarjeta.'
        );
        insert et;
        return et;
    }

    // =========================================================================
    // EMAIL REQUESTS
    // =========================================================================

    /**
     * @description Construye un EmailRequest válido (sin insertar, es inner class).
     * @param templateApiName DeveloperName de la plantilla
     * @param recordId Id del record (oportunidad)
     * @param accountId Id de la cuenta del cliente
     * @return EmailRequest configurado
     */
    public static EmailRequest buildEmailRequest(
        String templateApiName,
        Id     recordId,
        Id     accountId
    ) {
        EmailRequest req = new EmailRequest();
        req.templateApiName = templateApiName;
        req.recordId        = recordId;
        req.accountId       = accountId;
        return req;
    }

    // =========================================================================
    // SETUP COMPLETO PARA ESCENARIO FELIZ
    // =========================================================================

    /**
     * @description Crea el conjunto completo de datos para el escenario de envío exitoso:
     *              Account, Contact, Opportunity, ContentDocumentLink, EmailTemplate.
     * @return Map con claves: 'account', 'contact', 'opportunity', 'template', 'cdl'
     */
    public static Map<String, SObject> createFullHappyPathData() {
        Account acc          = createAccount(VALID_EMAIL);
        Contact con          = createContact(acc.Id);
        Opportunity opp      = createOpportunity(acc.Id);
        ContentDocumentLink cdl = createContentDocumentLink(opp.Id);
        EmailTemplate et     = createEmailTemplate(TEMPLATE_API_NAME);

        return new Map<String, SObject>{
            'account'     => acc,
            'contact'     => con,
            'opportunity' => opp,
            'template'    => et,
            'cdl'         => cdl
        };
    }
}
