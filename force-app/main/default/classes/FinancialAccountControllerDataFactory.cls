/**
 * @description Data Factory para pruebas de FinancialAccountController.
 *              Centraliza la creación de usuarios, cuentas, perfiles, roles
 *              y registros FinancialAccount__c necesarios para cubrir >= 95%.
 *
 *              Usuarios de prueba:
 *                - analyst_test  → Rol Analista  (puede leer/escribir CardNumber__c, puede Delete)
 *                - executive_test → Rol Ejecutivo (NO puede leer CardNumber__c, NO puede Delete)
 */
@IsTest
public class FinancialAccountControllerDataFactory {

    // ── Constantes de datos ────────────────────────────────────────────────────

    public static final String PROFILE_NAME      = 'Asesor de Venta y Reclamos';
    public static final String ROLE_ANALYST      = 'Analista';
    public static final String ROLE_EXECUTIVE    = 'Ejecutivo';
    public static final String PERMSET_ANALYST   = 'AccesoBeneficios';   // permset que da FLS Read/Write en CardNumber__c y Delete en FA
    public static final String EMAIL_ANALYST     = 'analyst_test@novabank.test.com';
    public static final String EMAIL_EXECUTIVE   = 'executive_test@novabank.test.com';
    public static final String USERNAME_ANALYST  = 'analyst_test@novabank.test.com.sandbox';
    public static final String USERNAME_EXECUTIVE= 'executive_test@novabank.test.com.sandbox';

    public static final String CARD_TYPE_ORO     = 'Visa Oro';
    public static final String CARD_TYPE_PLATA   = 'Visa Plata';
    public static final String CARD_TYPE_INFINITE= 'Visa Infinite';
    public static final String STATUS_ACTIVA     = 'Activa';
    public static final String STATUS_BLOQUEADA  = 'Bloqueada';
    public static final String STATUS_CANCELADA  = 'Cancelada';

    // ── Perfil ─────────────────────────────────────────────────────────────────

    /**
     * @description Retorna el perfil base configurado en el org.
     *              Si el perfil personalizado no existe, cae a 'Standard User'.
     */
    public static Profile getBaseProfile() {
        List<Profile> profiles = [
            SELECT Id FROM Profile WHERE Name = :PROFILE_NAME LIMIT 1
        ];
        if (!profiles.isEmpty()) {
            return profiles[0];
        }
        return [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    }

    // ── Roles ──────────────────────────────────────────────────────────────────

    /**
     * @description Retorna el rol Analista. Lo crea si no existe.
     */
    public static UserRole getOrCreateAnalystRole() {
        List<UserRole> roles = [SELECT Id FROM UserRole WHERE Name = :ROLE_ANALYST LIMIT 1];
        if (!roles.isEmpty()) return roles[0];

        UserRole role = new UserRole(Name = ROLE_ANALYST, DeveloperName = 'Analista');
        insert role;
        return role;
    }

    /**
     * @description Retorna el rol Ejecutivo. Lo crea si no existe.
     */
    public static UserRole getOrCreateExecutiveRole() {
        List<UserRole> roles = [SELECT Id FROM UserRole WHERE Name = :ROLE_EXECUTIVE LIMIT 1];
        if (!roles.isEmpty()) return roles[0];

        UserRole role = new UserRole(Name = ROLE_EXECUTIVE, DeveloperName = 'Ejecutivo');
        insert role;
        return role;
    }

    // ── Usuarios ───────────────────────────────────────────────────────────────

    /**
     * @description Crea el usuario analyst_test con rol Analista.
     *              Asigna el PermissionSet AccesoBeneficios que habilita
     *              Read/Write sobre CardNumber__c y Delete sobre FinancialAccount__c.
     * @return User insertado
     */
    public static User createAnalystUser() {
        Profile p   = getBaseProfile();
        UserRole r  = getOrCreateAnalystRole();

        User u = new User(
            FirstName            = 'Analyst',
            LastName             = 'Test',
            Email                = EMAIL_ANALYST,
            Username             = USERNAME_ANALYST,
            Alias                = 'antest',
            CommunityNickname    = 'analysttest',
            ProfileId            = p.Id,
            UserRoleId           = r.Id,
            TimeZoneSidKey       = 'America/Lima',
            LocaleSidKey         = 'es_PE',
            EmailEncodingKey     = 'UTF-8',
            LanguageLocaleKey    = 'es'
        );
        insert u;

        // Asignar PermissionSet que da acceso a CardNumber__c y Delete en FA
        assignPermissionSet(u.Id, PERMSET_ANALYST);

        return u;
    }

    /**
     * @description Crea el usuario executive_test con rol Ejecutivo.
     *              NO recibe el PermissionSet de AccesoBeneficios.
     * @return User insertado
     */
    public static User createExecutiveUser() {
        Profile p   = getBaseProfile();
        UserRole r  = getOrCreateExecutiveRole();

        User u = new User(
            FirstName            = 'Executive',
            LastName             = 'Test',
            Email                = EMAIL_EXECUTIVE,
            Username             = USERNAME_EXECUTIVE,
            Alias                = 'extest',
            CommunityNickname    = 'executivetest',
            ProfileId            = p.Id,
            UserRoleId           = r.Id,
            TimeZoneSidKey       = 'America/Lima',
            LocaleSidKey         = 'es_PE',
            EmailEncodingKey     = 'UTF-8',
            LanguageLocaleKey    = 'es'
        );
        insert u;
        return u;
    }

    // ── PermissionSet ──────────────────────────────────────────────────────────

    /**
     * @description Asigna un PermissionSet a un usuario por nombre.
     *              Si el PermSet no existe en el org, omite silenciosamente.
     * @param userId        Id del usuario destino
     * @param permSetName   Nombre API del PermissionSet
     */
    public static void assignPermissionSet(Id userId, String permSetName) {
        List<PermissionSet> ps = [
            SELECT Id FROM PermissionSet WHERE Name = :permSetName LIMIT 1
        ];
        if (ps.isEmpty()) return;

        List<PermissionSetAssignment> existing = [
            SELECT Id FROM PermissionSetAssignment
            WHERE AssigneeId = :userId AND PermissionSetId = :ps[0].Id
        ];
        if (existing.isEmpty()) {
            insert new PermissionSetAssignment(
                AssigneeId      = userId,
                PermissionSetId = ps[0].Id
            );
        }
    }

    // ── Account ────────────────────────────────────────────────────────────────

    /**
     * @description Crea y retorna una Account de prueba vinculada al usuario dado.
     * @param ownerId  OwnerId para el registro
     * @return Account insertada
     */
    public static Account createAccount(Id ownerId) {
        Account acc = new Account(
            Name    = 'Cuenta Test NovaBank',
            OwnerId = ownerId
        );
        insert acc;
        return acc;
    }

    /**
     * @description Crea una Account sin especificar owner (usa el contexto del test).
     */
    public static Account createAccount() {
        Account acc = new Account(Name = 'Cuenta Test NovaBank');
        insert acc;
        return acc;
    }

    // ── FinancialAccount__c ────────────────────────────────────────────────────

    /**
     * @description Construye (sin insertar) un FinancialAccount__c con datos mínimos.
     * @param accountId     Lookup a Account
     * @param cardType      Tipo de tarjeta (Visa Oro, Visa Plata, Visa Infinite)
     * @param creditLine    Línea de crédito aprobada
     * @param status        Estado (Activa, Bloqueada, Cancelada)
     * @param issuanceDate  Fecha de emisión
     * @param cardNumber    Número de tarjeta (puede ser null)
     * @return FinancialAccount__c (no insertado)
     */
    public static FinancialAccount__c buildFinancialAccount(
        Id      accountId,
        String  cardType,
        Decimal creditLine,
        String  status,
        Date    issuanceDate,
        String  cardNumber
    ) {
        FinancialAccount__c fa = new FinancialAccount__c(
            AccountId__c          = accountId,
            CardType__c           = cardType,
            ApprovedCreditLine__c = creditLine,
            Status__c             = status,
            IssuanceDate__c       = issuanceDate
        );
        if (cardNumber != null) {
            fa.CardNumber__c = cardNumber;
        }
        return fa;
    }

    /**
     * @description Crea e inserta un FinancialAccount__c con valores por defecto.
     * @param accountId Lookup a Account
     * @return FinancialAccount__c insertado
     */
    public static FinancialAccount__c createFinancialAccount(Id accountId) {
        FinancialAccount__c fa = buildFinancialAccount(
            accountId,
            CARD_TYPE_ORO,
            5000,
            STATUS_ACTIVA,
            Date.today(),
            '4111111111111111'
        );
        insert fa;
        return fa;
    }

    /**
     * @description Crea e inserta N registros FinancialAccount__c con fechas distintas
     *              para probar el ordenamiento DESC por IssuanceDate__c.
     * @param accountId  Lookup a Account
     * @param count      Número de registros a crear
     * @return Lista de FinancialAccount__c insertados (más reciente primero en el org)
     */
    public static List<FinancialAccount__c> createFinancialAccountsWithDates(
        Id      accountId,
        Integer count
    ) {
        List<FinancialAccount__c> faList = new List<FinancialAccount__c>();
        String[] cardTypes = new String[]{ CARD_TYPE_ORO, CARD_TYPE_PLATA, CARD_TYPE_INFINITE };
        for (Integer i = 0; i < count; i++) {
            faList.add(buildFinancialAccount(
                accountId,
                cardTypes[Math.mod(i, cardTypes.size())],
                3000 + (i * 1000),
                STATUS_ACTIVA,
                Date.today().addDays(-i),   // día 0, -1, -2 → DESC retorna 0 primero
                '411111111111111' + i
            ));
        }
        insert faList;
        return faList;
    }

    /**
     * @description Construye un FinancialAccount__c con campo requerido nulo
     *              para provocar DmlException en save().
     * @param accountId  Lookup a Account
     * @return FinancialAccount__c inválido (no insertado)
     */
    public static FinancialAccount__c buildInvalidFinancialAccount(Id accountId) {
        // CardType__c es required — omitirlo provocará DmlException
        return new FinancialAccount__c(
            AccountId__c          = accountId,
            ApprovedCreditLine__c = 1000,
            Status__c             = STATUS_ACTIVA,
            IssuanceDate__c       = Date.today()
            // CardType__c intencionalmente ausente
        );
    }

    /**
     * @description Construye un FinancialAccount__c incluyendo CardNumber__c
     *              para probar el comportamiento de stripInaccessible en save().
     * @param accountId Lookup a Account
     * @return FinancialAccount__c con CardNumber__c (no insertado)
     */
    public static FinancialAccount__c buildFaWithCardNumber(Id accountId) {
        return buildFinancialAccount(
            accountId,
            CARD_TYPE_PLATA,
            3000,
            STATUS_ACTIVA,
            Date.today(),
            '5500005555555559'
        );
    }

    // ── IDs inválidos ──────────────────────────────────────────────────────────

    /**
     * @description Retorna un Id con formato válido de Salesforce pero
     *              que no corresponde a ningún registro en la BD.
     * @return Id ficticio de FinancialAccount__c
     */
    public static Id getFakeFinancialAccountId() {
        // El prefijo del objeto debe coincidir con el key prefix de FinancialAccount__c
        // Si el prefix no es conocido, se crea un registro, se toma el prefix y luego se borra
        FinancialAccount__c tmp = new FinancialAccount__c(
            AccountId__c          = null, // se usa solo para obtener el key prefix
            CardType__c           = CARD_TYPE_ORO,
            ApprovedCreditLine__c = 1000,
            Status__c             = STATUS_ACTIVA,
            IssuanceDate__c       = Date.today()
        );
        // Usamos el key prefix del SObjectType directamente
        String prefix = FinancialAccount__c.SObjectType.getDescribe().getKeyPrefix();
        return (Id)(prefix + '000000000001AAA');
    }
}
