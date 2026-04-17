/**
 * @description   Data Factory para las pruebas de LeadConversionService.
 *                Centraliza la creación de registros de prueba reutilizables.
 *                Cubre todos los escenarios del Feature file (14 escenarios).
 *
 * @author        NovaBank – Equipo de Desarrollo Salesforce
 * @class         LeadConversionServiceDataFactory
 */
@IsTest
public class LeadConversionServiceDataFactory {

    // ─── Constantes de configuración ──────────────────────────────────────────
    public static final String LEAD_STATUS_OPEN          = 'Open';          // Estado inicial del Lead
    public static final String LEAD_STATUS_CONVERTED     = 'Closed - Converted';
    public static final String PRODUCT_VISA_ORO          = 'Visa Oro';
    public static final String PRODUCT_VISA_PLATA        = 'Visa Plata';
    public static final String PRODUCT_VISA_INFINITE     = 'Visa Infinite';
    public static final String PRODUCT_INEXISTENTE       = 'ProductoInexistente';
    public static final String EMAIL_EJECUTIVO           = 'ejecutivo_test@novabank.com.test';
    public static final String EMAIL_ANALISTA            = 'analista_test@novabank.com.test';
    public static final String NATIONAL_ID_DEFAULT       = '12345678';
    public static final String NATIONAL_ID_EXISTING_ACC  = '99887766';

    // ─── USUARIOS ─────────────────────────────────────────────────────────────

    /**
     * @description Crea y devuelve el perfil estándar "Standard User" (base reutilizable).
     *              En proyectos reales, reemplazar por el perfil "Asesor de Venta y Reclamos".
     */
    public static Profile getStandardProfile() {
        return [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    }

    /**
     * @description Crea un usuario con rol Ejecutivo para pruebas.
     *              NO se inserta; el test decide cuándo hacerlo dentro de runAs.
     */
    public static User createEjecutivoUser() {
        Profile p = getStandardProfile();
        User u = new User(
            FirstName          = 'Ejecutivo',
            LastName           = 'Test',
            Alias              = 'ejec',
            Email              = EMAIL_EJECUTIVO,
            Username           = EMAIL_EJECUTIVO + System.currentTimeMillis(),
            ProfileId          = p.Id,
            TimeZoneSidKey     = 'America/Lima',
            LocaleSidKey       = 'es_PE',
            EmailEncodingKey   = 'UTF-8',
            LanguageLocaleKey  = 'es'
        );
        return u;
    }

    /**
     * @description Crea un usuario con rol Analista para pruebas.
     *              NO se inserta; el test decide cuándo hacerlo dentro de runAs.
     */
    public static User createAnalistaUser() {
        Profile p = getStandardProfile();
        User u = new User(
            FirstName          = 'Analista',
            LastName           = 'Test',
            Alias              = 'anal',
            Email              = EMAIL_ANALISTA,
            Username           = EMAIL_ANALISTA + System.currentTimeMillis(),
            ProfileId          = p.Id,
            TimeZoneSidKey     = 'America/Lima',
            LocaleSidKey       = 'es_PE',
            EmailEncodingKey   = 'UTF-8',
            LanguageLocaleKey  = 'es'
        );
        return u;
    }

    // ─── PRODUCTOS (Product2) ─────────────────────────────────────────────────

    /**
     * @description Crea e inserta un Product2 con los datos indicados.
     * @param  name         Nombre del producto (e.g. "Visa Oro")
     * @param  interestRate Tasa de interés anual
     * @return              Product2 insertado con Id asignado
     */
    public static Product2 createProduct(String name, Decimal interestRate) {
        Product2 prod = new Product2(
            Name             = name,
            IsActive         = true,
            InterestRate__c  = interestRate
        );
        insert prod;
        return prod;
    }

    /** Crea Visa Oro con tasa 24.5 */
    public static Product2 createVisaOro() {
        return createProduct(PRODUCT_VISA_ORO, 24.5);
    }

    /** Crea Visa Plata con tasa 18.0 */
    public static Product2 createVisaPlata() {
        return createProduct(PRODUCT_VISA_PLATA, 18.0);
    }

    /** Crea Visa Infinite con tasa 30.0 */
    public static Product2 createVisaInfinite() {
        return createProduct(PRODUCT_VISA_INFINITE, 30.0);
    }

    // ─── CUENTAS (Account) ────────────────────────────────────────────────────

    /**
     * @description Crea e inserta una Cuenta básica para uso en pruebas.
     * @param  name       Nombre de la cuenta
     * @param  nationalId DNI/NationalId del titular (puede ser null)
     * @return            Account insertada
     */
    public static Account createAccount(String name, String nationalId) {
        Account acc = new Account(
            Name           = name,
            NationalId__c  = nationalId,
            Email__c       = name.toLowerCase().replaceAll(' ', '.') + '@novabank.com'
        );
        insert acc;
        return acc;
    }

    /** Cuenta con NationalId para prueba de búsqueda por DNI */
    public static Account createAccountWithNationalId() {
        return createAccount('Cliente Existente', NATIONAL_ID_EXISTING_ACC);
    }

    // ─── LEADS ────────────────────────────────────────────────────────────────

    /**
     * @description Builder base para Lead; aplica defaults seguros.
     *              No se inserta. Permite personalización antes de insertar.
     */
    public static Lead buildLeadBase() {
        return new Lead(
            FirstName      = 'Juan',
            LastName       = 'Perez',
            Company        = 'NovaBank',
            Status         = LEAD_STATUS_OPEN,
            Email          = 'juan.perez@novabank.com',
            Product__c     = PRODUCT_VISA_ORO,
            NationalId__c  = NATIONAL_ID_DEFAULT
        );
    }

    /**
     * @description Escenario 3 – Lead completo con FirstName + LastName + Visa Oro.
     */
    public static Lead createLeadFullName() {
        Lead l = buildLeadBase();
        insert l;
        return l;
    }

    /**
     * @description Escenario 4 – Lead sin FirstName (solo LastName).
     */
    public static Lead createLeadNoFirstName() {
        Lead l = buildLeadBase();
        l.FirstName    = null;
        l.LastName     = 'Lopez';
        l.Email        = 'lopez@nova.com';
        l.Product__c   = PRODUCT_VISA_PLATA;
        l.NationalId__c = '87654321';
        insert l;
        return l;
    }

    /**
     * @description Escenario 5 – Lead con ExistingAccount__c preestablecida.
     * @param  existingAccountId Id de la Cuenta existente
     */
    public static Lead createLeadWithExistingAccount(Id existingAccountId) {
        Lead l = buildLeadBase();
        l.ExistingAccount__c = existingAccountId;
        l.Product__c         = PRODUCT_VISA_INFINITE;
        l.NationalId__c      = null;
        insert l;
        return l;
    }

    /**
     * @description Escenario 6 – Lead cuyo NationalId coincide con una Cuenta existente.
     */
    public static Lead createLeadWithMatchingNationalId() {
        Lead l = buildLeadBase();
        l.NationalId__c      = NATIONAL_ID_EXISTING_ACC;
        l.ExistingAccount__c = null;
        l.Product__c         = PRODUCT_VISA_ORO;
        insert l;
        return l;
    }

    /**
     * @description Escenario 7 – Lead sin ExistingAccount ni NationalId → nueva Cuenta.
     */
    public static Lead createLeadNoAccountLinks() {
        Lead l = buildLeadBase();
        l.ExistingAccount__c = null;
        l.NationalId__c      = null;
        l.Email              = 'nuevo@nova.com';
        l.Product__c         = PRODUCT_VISA_ORO;
        insert l;
        return l;
    }

    /**
     * @description Escenario 8 – Lead con producto que NO existe en catálogo.
     */
    public static Lead createLeadUnknownProduct() {
        Lead l = buildLeadBase();
        l.Product__c  = PRODUCT_INEXISTENTE;
        l.NationalId__c = null;
        insert l;
        return l;
    }

    /**
     * @description Escenario 9 – Lead sin producto (Product__c vacío).
     */
    public static Lead createLeadNoProduct() {
        Lead l = buildLeadBase();
        l.Product__c  = null;
        l.NationalId__c = null;
        insert l;
        return l;
    }

    /**
     * @description Escenario 10 – Lead válido para prueba con usuario Analista.
     */
    public static Lead createLeadForAnalista() {
        Lead l = buildLeadBase();
        l.Product__c = PRODUCT_VISA_INFINITE;
        insert l;
        return l;
    }

    /**
     * @description Escenario 14 – Lead con Product__c nulo y nombre completo "Ana Torres".
     */
    public static Lead createLeadNullProduct() {
        Lead l = buildLeadBase();
        l.FirstName   = 'Ana';
        l.LastName    = 'Torres';
        l.Product__c  = null;
        l.NationalId__c = null;
        insert l;
        return l;
    }

    // ─── VERIFICADORES / HELPERS ──────────────────────────────────────────────

    /**
     * @description Recupera la Oportunidad asociada al Lead convertido.
     * @param  opportunityId  Id devuelto por convertLead
     * @return                Opportunity con campos clave
     */
    public static Opportunity getOpportunity(Id opportunityId) {
        return [
            SELECT Id, Name, ProductId__c, InterestRate__c, AccountId
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
    }

    /**
     * @description Recupera la Cuenta vinculada a una Oportunidad.
     * @param  accountId  Id de la Cuenta
     * @return            Account con campos clave
     */
    public static Account getAccount(Id accountId) {
        return [
            SELECT Id, Name, Email__c, NationalId__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
    }

    /**
     * @description Recupera un Lead por su Id para validar estado post-conversión.
     * @param  leadId  Id del Lead
     * @return         Lead con campos de conversión
     */
    public static Lead getLeadAfterConversion(Id leadId) {
        return [
            SELECT Id, IsConverted, ConvertedOpportunityId, Status
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];
    }
}
