/**
 * @description Data Factory para pruebas de ContractGeneratorController.
 *              Provee métodos de creación de datos de prueba reutilizables
 *              para todos los escenarios definidos en el feature file.
 *              Cubre los dos tipos de usuario: Ejecutivo y Analista.
 * @author      NovaBank - Bootcamp BCP
 */
@isTest
public class ContractGeneratorControllerDataFactory {

    // ─────────────────────────────────────────────
    // CONSTANTES DE CONFIGURACIÓN
    // ─────────────────────────────────────────────
    public static final String PROFILE_NAME      = 'Asesor de Venta y Reclamos';
    public static final String ROLE_EXECUTIVE    = 'Ejecutivo';
    public static final String ROLE_ANALYST      = 'Analista';
    public static final String OPP_STAGE_CONTRACT = 'Contrato';
    public static final String OPP_STAGE_WON     = 'Closed Won';
    public static final String CARD_PRODUCT_GOLD = 'Visa Oro';

    // ─────────────────────────────────────────────
    // PERFILES Y ROLES
    // ─────────────────────────────────────────────

    /**
     * @description Obtiene el perfil estándar de Salesforce para pruebas.
     *              Se usa "Standard User" como base cuando el perfil custom
     *              no está disponible en el entorno de test.
     * @return Profile registro del perfil
     */
    public static Profile getStandardProfile() {
        return [
            SELECT Id FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];
    }

    /**
     * @description Obtiene el perfil custom del proyecto si existe,
     *              de lo contrario retorna el Standard User.
     * @return Profile registro del perfil
     */
    public static Profile getProjectProfile() {
        List<Profile> profiles = [
            SELECT Id FROM Profile
            WHERE Name = :PROFILE_NAME
            LIMIT 1
        ];
        return profiles.isEmpty() ? getStandardProfile() : profiles[0];
    }

    /**
     * @description Crea o recupera el rol de Ejecutivo.
     * @return UserRole registro del rol Ejecutivo
     */
    public static UserRole getOrCreateExecutiveRole() {
        List<UserRole> roles = [
            SELECT Id FROM UserRole
            WHERE DeveloperName = 'Ejecutivo'
            LIMIT 1
        ];
        if (!roles.isEmpty()) return roles[0];

        UserRole role = new UserRole(
            Name        = 'Ejecutivo',
            DeveloperName = 'Ejecutivo'
        );
        insert role;
        return role;
    }

    /**
     * @description Crea o recupera el rol de Analista (hijo de Ejecutivo).
     * @return UserRole registro del rol Analista
     */
    public static UserRole getOrCreateAnalystRole() {
        List<UserRole> roles = [
            SELECT Id FROM UserRole
            WHERE DeveloperName = 'Analista'
            LIMIT 1
        ];
        if (!roles.isEmpty()) return roles[0];

        UserRole parentRole = getOrCreateExecutiveRole();
        UserRole role = new UserRole(
            Name            = 'Analista',
            DeveloperName   = 'Analista',
            ParentRoleId    = parentRole.Id
        );
        insert role;
        return role;
    }

    // ─────────────────────────────────────────────
    // USUARIOS DE PRUEBA
    // ─────────────────────────────────────────────

    /**
     * @description Crea un usuario de tipo Ejecutivo para pruebas.
     *              NO se inserta; se devuelve para inserción controlada.
     * @return User sin insertar con rol Ejecutivo
     */
    public static User buildExecutiveUser() {
        Profile p    = getProjectProfile();
        UserRole rol = getOrCreateExecutiveRole();

        return new User(
            FirstName       = 'Ejecutivo',
            LastName        = 'Test',
            Alias           = 'exec01',
            Email           = 'ejecutivo.test@novabank.com.invalid',
            Username        = 'ejecutivo.test.' + System.currentTimeMillis() + '@novabank.com.invalid',
            ProfileId       = p.Id,
            UserRoleId      = rol.Id,
            TimeZoneSidKey  = 'America/Lima',
            LocaleSidKey    = 'es_PE',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'es'
        );
    }

    /**
     * @description Crea e inserta un usuario de tipo Ejecutivo para pruebas.
     * @return User insertado con rol Ejecutivo
     */
    public static User createExecutiveUser() {
        User u = buildExecutiveUser();
        insert u;
        return u;
    }

    /**
     * @description Crea un usuario de tipo Analista para pruebas.
     *              NO se inserta; se devuelve para inserción controlada.
     * @return User sin insertar con rol Analista
     */
    public static User buildAnalystUser() {
        Profile p    = getProjectProfile();
        UserRole rol = getOrCreateAnalystRole();

        return new User(
            FirstName        = 'Analista',
            LastName         = 'Test',
            Alias            = 'analy01',
            Email            = 'analista.test@novabank.com.invalid',
            Username         = 'analista.test.' + System.currentTimeMillis() + '@novabank.com.invalid',
            ProfileId        = p.Id,
            UserRoleId       = rol.Id,
            TimeZoneSidKey   = 'America/Lima',
            LocaleSidKey     = 'es_PE',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'es'
        );
    }

    /**
     * @description Crea e inserta un usuario de tipo Analista para pruebas.
     * @return User insertado con rol Analista
     */
    public static User createAnalystUser() {
        User u = buildAnalystUser();
        insert u;
        return u;
    }

    // ─────────────────────────────────────────────
    // CUENTA (ACCOUNT)
    // ─────────────────────────────────────────────

    /**
     * @description Crea una Cuenta de cliente persona natural.
     *              NO se inserta.
     * @param ownerUserId Id del usuario propietario
     * @return Account sin insertar
     */
    public static Account buildAccount(Id ownerUserId) {
        return new Account(
            Name    = 'Juan Perez',
            OwnerId = ownerUserId
        );
    }

    /**
     * @description Crea e inserta una Cuenta de cliente.
     * @param ownerUserId Id del usuario propietario
     * @return Account insertada
     */
    public static Account createAccount(Id ownerUserId) {
        Account acc = buildAccount(ownerUserId);
        insert acc;
        return acc;
    }

    // ─────────────────────────────────────────────
    // OPORTUNIDAD (OPPORTUNITY)
    // ─────────────────────────────────────────────

    /**
     * @description Construye una Oportunidad en etapa "Contrato" sin insertar.
     * @param accountId Id de la Cuenta asociada
     * @param ownerUserId Id del usuario propietario
     * @param oppName Nombre de la oportunidad
     * @return Opportunity sin insertar
     */
    public static Opportunity buildOpportunity(Id accountId, Id ownerUserId, String oppName) {
        return new Opportunity(
            Name        = oppName,
            AccountId   = accountId,
            StageName   = OPP_STAGE_CONTRACT,
            CloseDate   = Date.today().addDays(30),
            OwnerId     = ownerUserId
        );
    }

    /**
     * @description Crea e inserta una Oportunidad en etapa "Contrato".
     * @param accountId Id de la Cuenta asociada
     * @param ownerUserId Id del usuario propietario
     * @return Opportunity insertada
     */
    public static Opportunity createOpportunity(Id accountId, Id ownerUserId) {
        Opportunity opp = buildOpportunity(accountId, ownerUserId, 'TC-2024-001');
        insert opp;
        return opp;
    }

    /**
     * @description Crea e inserta una Oportunidad con nombre personalizado.
     * @param accountId Id de la Cuenta asociada
     * @param ownerUserId Id del usuario propietario
     * @param oppName Nombre personalizado de la oportunidad
     * @return Opportunity insertada
     */
    public static Opportunity createOpportunityWithName(Id accountId, Id ownerUserId, String oppName) {
        Opportunity opp = buildOpportunity(accountId, ownerUserId, oppName);
        insert opp;
        return opp;
    }

    // ─────────────────────────────────────────────
    // CONJUNTO COMPLETO DE DATOS (SETUP RÁPIDO)
    // ─────────────────────────────────────────────

    /**
     * @description Wrapper con todos los datos necesarios para un escenario.
     */
    public class TestContext {
        public User executiveUser;
        public User analystUser;
        public Account account;
        public Opportunity opportunity;
    }

    /**
     * @description Crea el contexto completo: Ejecutivo + Analista + Cuenta + Oportunidad.
     *              Útil para tests que necesitan ambos tipos de usuario.
     * @return TestContext con todos los registros insertados
     */
    public static TestContext createFullContext() {
        TestContext ctx = new TestContext();

        // Crear usuarios primero (fuera de runAs)
        ctx.executiveUser = createExecutiveUser();
        ctx.analystUser   = createAnalystUser();

        // Crear datos de negocio como el usuario Ejecutivo
        System.runAs(ctx.executiveUser) {
            ctx.account     = createAccount(ctx.executiveUser.Id);
            ctx.opportunity = createOpportunity(ctx.account.Id, ctx.executiveUser.Id);
        }

        return ctx;
    }

    /**
     * @description Crea el contexto básico solo con el usuario Ejecutivo.
     * @return TestContext con ejecutivo, cuenta y oportunidad
     */
    public static TestContext createExecutiveContext() {
        TestContext ctx = new TestContext();
        ctx.executiveUser = createExecutiveUser();

        System.runAs(ctx.executiveUser) {
            ctx.account     = createAccount(ctx.executiveUser.Id);
            ctx.opportunity = createOpportunity(ctx.account.Id, ctx.executiveUser.Id);
        }

        return ctx;
    }

    /**
     * @description Crea el contexto básico solo con el usuario Analista.
     * @return TestContext con analista, cuenta y oportunidad
     */
    public static TestContext createAnalystContext() {
        TestContext ctx = new TestContext();
        ctx.executiveUser = createExecutiveUser(); // dueño de los datos
        ctx.analystUser   = createAnalystUser();

        System.runAs(ctx.executiveUser) {
            ctx.account     = createAccount(ctx.executiveUser.Id);
            ctx.opportunity = createOpportunity(ctx.account.Id, ctx.executiveUser.Id);
        }

        return ctx;
    }
}
