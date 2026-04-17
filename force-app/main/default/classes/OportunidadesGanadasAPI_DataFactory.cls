/**
 * @description  : Data Factory para pruebas de OportunidadesGanadasAPI.
 *                 Centraliza la creación de todos los registros de prueba necesarios
 *                 para cubrir los 12 escenarios definidos en el feature Gherkin.
 * @author       : NovaBank QA Team
 * @group        : Test Utilities
 * @last modified: 2026-04-16
 */
@IsTest
public class OportunidadesGanadasAPI_DataFactory {

    // =====================================================================
    // CONSTANTES DE CONFIGURACIÓN
    // =====================================================================
    public static final String NATIONAL_ID_MULTI_OPP    = '12345678';
    public static final String NATIONAL_ID_ONE_OPP      = '87654321';
    public static final String NATIONAL_ID_NO_WON_OPP   = '11111111';
    public static final String NATIONAL_ID_NOT_FOUND    = '99999999';
    public static final String NATIONAL_ID_MIXED_STAGES = '33333333';
    public static final String NATIONAL_ID_ANALISTA     = '44444444';
    public static final String NATIONAL_ID_NULL_FIELDS  = '55555555';
    public static final String NATIONAL_ID_DECIMALS     = '77777777';

    public static final String PROFILE_NAME  = 'Asesor de Venta y Reclamos';
    public static final String ROL_EJECUTIVO = 'Ejecutivo';
    public static final String ROL_ANALISTA  = 'Analista';

    public static final String USER_EJECUTIVO_EMAIL = 'ejecutivo_test@novabank.com.invalid';
    public static final String USER_ANALISTA_EMAIL  = 'analista_test@novabank.com.invalid';

    // =====================================================================
    // MÉTODOS DE CREACIÓN DE USUARIOS
    // =====================================================================

    /**
     * @description Obtiene o crea el perfil base utilizado en las pruebas.
     *              Si el perfil personalizado no existe, usa "Standard User" como fallback.
     * @return Profile - perfil encontrado
     */
    public static Profile getProfile() {
        List<Profile> profiles = [
            SELECT Id FROM Profile
            WHERE Name = :PROFILE_NAME
            LIMIT 1
        ];
        if (!profiles.isEmpty()) {
            return profiles[0];
        }
        // Fallback a Standard User si el perfil custom no existe en el org de prueba
        return [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    }

    /**
     * @description Obtiene o crea el UserRole Ejecutivo.
     * @return UserRole - rol Ejecutivo
     */
    public static UserRole getRolEjecutivo() {
        List<UserRole> roles = [
            SELECT Id FROM UserRole WHERE Name = :ROL_EJECUTIVO LIMIT 1
        ];
        if (!roles.isEmpty()) return roles[0];
        UserRole r = new UserRole(Name = ROL_EJECUTIVO, DeveloperName = 'Ejecutivo');
        insert r;
        return r;
    }

    /**
     * @description Obtiene o crea el UserRole Analista.
     * @return UserRole - rol Analista
     */
    public static UserRole getRolAnalista() {
        List<UserRole> roles = [
            SELECT Id FROM UserRole WHERE Name = :ROL_ANALISTA LIMIT 1
        ];
        if (!roles.isEmpty()) return roles[0];
        UserRole parent = getRolEjecutivo();
        UserRole r = new UserRole(
            Name         = ROL_ANALISTA,
            DeveloperName = 'Analista',
            ParentRoleId  = parent.Id
        );
        insert r;
        return r;
    }

    /**
     * @description Crea un usuario con rol Ejecutivo para pruebas.
     *              No hace INSERT — el llamador decide si inserta o usa en runAs.
     * @return User - usuario ejecutivo sin insertar
     */
    public static User buildUsuarioEjecutivo() {
        Profile p   = getProfile();
        UserRole rol = getRolEjecutivo();
        User u = new User(
            FirstName          = 'Ejecutivo',
            LastName           = 'Test',
            Email              = USER_EJECUTIVO_EMAIL,
            Username           = USER_EJECUTIVO_EMAIL + System.currentTimeMillis(),
            Alias              = 'ejetest',
            TimeZoneSidKey     = 'America/Lima',
            LocaleSidKey       = 'es_PE',
            EmailEncodingKey   = 'UTF-8',
            LanguageLocaleKey  = 'es',
            ProfileId          = p.Id,
            UserRoleId         = rol.Id
        );
        return u;
    }

    /**
     * @description Crea e inserta un usuario con rol Ejecutivo listo para usar en runAs.
     * @return User - usuario ejecutivo insertado
     */
    public static User crearUsuarioEjecutivo() {
        User u = buildUsuarioEjecutivo();
        insert u;
        return u;
    }

    /**
     * @description Crea un usuario con rol Analista para pruebas.
     * @return User - usuario analista sin insertar
     */
    public static User buildUsuarioAnalista() {
        Profile p    = getProfile();
        UserRole rol = getRolAnalista();
        User u = new User(
            FirstName          = 'Analista',
            LastName           = 'Test',
            Email              = USER_ANALISTA_EMAIL,
            Username           = USER_ANALISTA_EMAIL + System.currentTimeMillis(),
            Alias              = 'analist',
            TimeZoneSidKey     = 'America/Lima',
            LocaleSidKey       = 'es_PE',
            EmailEncodingKey   = 'UTF-8',
            LanguageLocaleKey  = 'es',
            ProfileId          = p.Id,
            UserRoleId         = rol.Id
        );
        return u;
    }

    /**
     * @description Crea e inserta un usuario con rol Analista.
     * @return User - usuario analista insertado
     */
    public static User crearUsuarioAnalista() {
        User u = buildUsuarioAnalista();
        insert u;
        return u;
    }

    // =====================================================================
    // MÉTODOS DE CREACIÓN DE CUENTAS
    // =====================================================================

    /**
     * @description Crea e inserta una Account con el NationalId__c dado.
     * @param nationalId  - valor del campo NationalId__c
     * @param nombre      - LastName de la cuenta (Name en Account)
     * @return Account - cuenta insertada
     */
    public static Account crearCuenta(String nationalId, String nombre) {
        Account acc = new Account(
            Name          = nombre,
            NationalId__c = nationalId
        );
        insert acc;
        return acc;
    }

    // =====================================================================
    // MÉTODOS DE CREACIÓN DE OPORTUNIDADES
    // =====================================================================

    /**
     * @description Crea e inserta una oportunidad Closed Won con todos los campos relevantes.
     * @param accountId   - Id de la cuenta dueña
     * @param producto    - valor del campo Product__c
     * @param monto       - Amount
     * @param lineaCredito - CreditLine__c
     * @param tasaInteres - InterestRate__c
     * @param leadSource  - LeadSource (canalOrigen)
     * @return Opportunity - oportunidad insertada
     */
    public static Opportunity crearOportunidadGanada(
        Id accountId,
        String producto,
        Decimal monto,
        Decimal lineaCredito,
        Decimal tasaInteres,
        String leadSource
    ) {
        Opportunity opp = new Opportunity(
            AccountId      = accountId,
            Name           = 'Opp Test - ' + producto,
            StageName      = 'Closed Won',
            CloseDate      = Date.today(),
            Amount         = monto,
            CreditLine__c  = lineaCredito,
            InterestRate__c = tasaInteres,
            LeadSource     = leadSource,
            Product__c     = producto
        );
        insert opp;
        return opp;
    }

    /**
     * @description Crea e inserta una oportunidad con un StageName arbitrario (no Closed Won).
     * @param accountId  - Id de la cuenta
     * @param stage      - StageName (Prospecting, Evaluation, Closed Lost, etc.)
     * @param producto   - valor del campo Product__c
     * @return Opportunity - oportunidad insertada
     */
    public static Opportunity crearOportunidadEnEtapa(
        Id accountId,
        String stage,
        String producto
    ) {
        Opportunity opp = new Opportunity(
            AccountId      = accountId,
            Name           = 'Opp Test Stage - ' + stage,
            StageName      = stage,
            CloseDate      = Date.today().addDays(30),
            Amount         = 3000,
            Product__c     = producto
        );
        insert opp;
        return opp;
    }

    /**
     * @description Crea e inserta una oportunidad Closed Won con campos opcionales en null.
     * @param accountId - Id de la cuenta
     * @return Opportunity - oportunidad sin Product__c ni LeadSource
     */
    public static Opportunity crearOportunidadGanadaCamposNulos(Id accountId) {
        Opportunity opp = new Opportunity(
            AccountId      = accountId,
            Name           = 'Opp Test Null Fields',
            StageName      = 'Closed Won',
            CloseDate      = Date.today(),
            Amount         = 5000,
            CreditLine__c  = 5000,
            InterestRate__c = 20.0
            // Product__c y LeadSource intencionalmente null
        );
        insert opp;
        return opp;
    }

    /**
     * @description Crea e inserta una oportunidad Closed Won con valores decimales precisos.
     * @param accountId - Id de la cuenta
     * @return Opportunity - oportunidad con decimales específicos
     */
    public static Opportunity crearOportunidadGanadaDecimals(Id accountId) {
        Opportunity opp = new Opportunity(
            AccountId       = accountId,
            Name            = 'Opp Test Decimals',
            StageName       = 'Closed Won',
            CloseDate       = Date.today(),
            Amount          = 15000.50,
            CreditLine__c   = 20000.75,
            InterestRate__c = 24.5,
            LeadSource      = 'Web',
            Product__c      = 'Visa Infinite'
        );
        insert opp;
        return opp;
    }

    // =====================================================================
    // MÉTODOS DE CONFIGURACIÓN DEL CONTEXTO REST
    // =====================================================================

    /**
     * @description Configura el RestContext simulando una petición GET al endpoint.
     * @param clienteId - NationalId del cliente a incluir en la URL
     */
    public static void setupRestContext(String clienteId) {
        RestRequest req  = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod   = 'GET';
        req.requestURI   = '/services/apexrest/v1/clientes/' + clienteId + '/oportunidades-ganadas';
        RestContext.request  = req;
        RestContext.response = res;
    }

    /**
     * @description Configura el RestContext con una URL vacía para forzar excepción genérica.
     *              Útil para el escenario de error 500.
     */
    public static void setupRestContextVacio() {
        RestRequest req  = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod  = 'GET';
        req.requestURI  = '/services/apexrest/v1/clientes//oportunidades-ganadas';
        RestContext.request  = req;
        RestContext.response = res;
    }

    // =====================================================================
    // MÉTODOS DE SETUP COMPUESTOS POR ESCENARIO
    // =====================================================================

    /**
     * @description Setup completo para Escenario 1: cuenta con 3 oportunidades ganadas.
     * @return Account - cuenta creada
     */
    public static Account setupEscenario_MultipleOportunidades() {
        Account acc = crearCuenta(NATIONAL_ID_MULTI_OPP, 'Juan Perez');
        crearOportunidadGanada(acc.Id, 'Visa Oro',      5000, 5000, 24.5, 'Web');
        crearOportunidadGanada(acc.Id, 'Visa Plata',    3000, 3000, 18.0, 'Office');
        crearOportunidadGanada(acc.Id, 'Visa Infinite', 7000, 7000, 30.0, 'Campaign');
        return acc;
    }

    /**
     * @description Setup completo para Escenario 2: cuenta con 1 oportunidad ganada.
     * @return Account - cuenta creada
     */
    public static Account setupEscenario_UnaOportunidad() {
        Account acc = crearCuenta(NATIONAL_ID_ONE_OPP, 'Maria Garcia');
        crearOportunidadGanada(acc.Id, 'Visa Plata', 3000, 3000, 18.0, 'Web');
        return acc;
    }

    /**
     * @description Setup para Escenario 3: cuenta sin oportunidades Closed Won.
     * @return Account - cuenta creada
     */
    public static Account setupEscenario_SinOportunidadesGanadas() {
        Account acc = crearCuenta(NATIONAL_ID_NO_WON_OPP, 'Pedro Ramirez');
        // No se crean oportunidades Closed Won
        crearOportunidadEnEtapa(acc.Id, 'Prospecting', 'Visa Plata');
        return acc;
    }

    /**
     * @description Setup para Escenario 7: cuenta con oportunidades en múltiples etapas.
     * @return Account - cuenta creada
     */
    public static Account setupEscenario_EtapasMixtas() {
        Account acc = crearCuenta(NATIONAL_ID_MIXED_STAGES, 'Rosa Campos');
        crearOportunidadGanada(acc.Id, 'Visa Oro', 5000, 5000, 24.5, 'Web');
        crearOportunidadEnEtapa(acc.Id, 'Prospecting', 'Visa Plata');
        crearOportunidadEnEtapa(acc.Id, 'Closed Lost', 'Visa Plata');
        return acc;
    }

    /**
     * @description Setup para Escenario 8: cuenta para prueba con usuario analista.
     * @return Account - cuenta creada
     */
    public static Account setupEscenario_Analista() {
        Account acc = crearCuenta(NATIONAL_ID_ANALISTA, 'Luis Torres');
        crearOportunidadGanada(acc.Id, 'Visa Oro',   5000, 5000, 24.5, 'Web');
        crearOportunidadGanada(acc.Id, 'Visa Plata', 3000, 3000, 18.0, 'Office');
        return acc;
    }

    /**
     * @description Setup para Escenario 9: oportunidad con campos opcionales nulos.
     * @return Account - cuenta creada
     */
    public static Account setupEscenario_CamposNulos() {
        Account acc = crearCuenta(NATIONAL_ID_NULL_FIELDS, 'Carmen Vargas');
        crearOportunidadGanadaCamposNulos(acc.Id);
        return acc;
    }

    /**
     * @description Setup para Escenario 12: oportunidad con valores decimales.
     * @return Account - cuenta creada
     */
    public static Account setupEscenario_ValoresDecimales() {
        Account acc = crearCuenta(NATIONAL_ID_DECIMALS, 'Jorge Mendez');
        crearOportunidadGanadaDecimals(acc.Id);
        return acc;
    }

    // =====================================================================
    // EXCEPCIÓN PERSONALIZADA
    // =====================================================================
    public class TestDataException extends Exception {}
}
