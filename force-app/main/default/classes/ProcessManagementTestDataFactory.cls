/**
 * @class       ProcessManagementTestDataFactory
 * @description Fábrica de datos de prueba para ProcessManagementController.
 *              Centraliza la creación de registros necesarios para cubrir todos
 *              los escenarios del feature file (>95% cobertura).
 *              Usuarios: analystUser (Analista) y executiveUser (Ejecutivo).
 *
 * IMPORTANTE: Los RecordTypes "Lead_Natural_Person" y "Case_Natural_Person"
 *             deben existir en el org. Si no existen, los métodos de usuario
 *             usarán el RecordType por defecto para evitar errores en el setup.
 */
@IsTest
public class ProcessManagementTestDataFactory {

    // =========================================================
    // CONSTANTES
    // =========================================================
    public static final String PROFILE_NAME        = 'Asesor de Venta y Reclamos';
    public static final String ROLE_EXECUTIVE_NAME = 'Ejecutivo';
    public static final String ROLE_ANALYST_NAME   = 'Analista';

    public static final String LEAD_RT_DEV_NAME    = 'Lead_Natural_Person';
    public static final String CASE_RT_DEV_NAME    = 'Case_Natural_Person';

    // =========================================================
    // ROLES
    // =========================================================

    /**
     * @description Obtiene o crea el rol "Ejecutivo".
     *              Los roles no pueden insertarse con DML normal en algunos orgs;
     *              se intenta obtener uno existente y, si no existe, se crea.
     * @return UserRole con nombre ROLE_EXECUTIVE_NAME
     */
    public static UserRole getOrCreateExecutiveRole() {
        List<UserRole> roles = [SELECT Id FROM UserRole WHERE DeveloperName = :ROLE_EXECUTIVE_NAME LIMIT 1];
        if (!roles.isEmpty()) {
            return roles[0];
        }
        UserRole role = new UserRole(
            Name          = ROLE_EXECUTIVE_NAME,
            DeveloperName = ROLE_EXECUTIVE_NAME
        );
        insert role;
        return role;
    }

    /**
     * @description Obtiene o crea el rol "Analista" como hijo del rol Ejecutivo.
     * @return UserRole con nombre ROLE_ANALYST_NAME
     */
    public static UserRole getOrCreateAnalystRole() {
        List<UserRole> roles = [SELECT Id FROM UserRole WHERE DeveloperName = :ROLE_ANALYST_NAME LIMIT 1];
        if (!roles.isEmpty()) {
            return roles[0];
        }
        UserRole parentRole = getOrCreateExecutiveRole();
        UserRole role = new UserRole(
            Name            = ROLE_ANALYST_NAME,
            DeveloperName   = ROLE_ANALYST_NAME,
            ParentRoleId    = parentRole.Id
        );
        insert role;
        return role;
    }

    // =========================================================
    // PERFIL
    // =========================================================

    /**
     * @description Obtiene el perfil base "Asesor de Venta y Reclamos".
     *              Si no existe, usa "Standard User" como fallback para pruebas.
     * @return Profile
     */
    public static Profile getBaseProfile() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME LIMIT 1];
        if (!profiles.isEmpty()) {
            return profiles[0];
        }
        // Fallback: Standard User (siempre existe en cualquier org Salesforce)
        return [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    }

    // =========================================================
    // USUARIOS
    // =========================================================

    /**
     * @description Crea y retorna un usuario con rol Ejecutivo.
     *              El usuario NO se inserta aquí; la clase de prueba lo inserta
     *              para poder usar System.runAs().
     * @return User con datos completos para inserción
     */
    public static User buildExecutiveUser() {
        Profile prof   = getBaseProfile();
        UserRole role  = getOrCreateExecutiveRole();

        String uniqueSuffix = String.valueOf(System.currentTimeMillis());
        return new User(
            FirstName          = 'Carlos',
            LastName           = 'Ejecutivo',
            Alias              = 'cejec',
            Email              = 'executive_test_' + uniqueSuffix + '@novabank.test.com',
            Username           = 'executive_test_' + uniqueSuffix + '@novabank.test.com',
            ProfileId          = prof.Id,
            UserRoleId         = role.Id,
            TimeZoneSidKey     = 'America/Lima',
            LocaleSidKey       = 'es_PE',
            EmailEncodingKey   = 'UTF-8',
            LanguageLocaleKey  = 'es'
        );
    }

    /**
     * @description Crea y retorna un usuario con rol Analista.
     *              El usuario NO se inserta aquí; la clase de prueba lo inserta.
     * @return User con datos completos para inserción
     */
    public static User buildAnalystUser() {
        Profile prof   = getBaseProfile();
        UserRole role  = getOrCreateAnalystRole();

        String uniqueSuffix = String.valueOf(System.currentTimeMillis()) + '1';
        return new User(
            FirstName          = 'Ana',
            LastName           = 'Analista',
            Alias              = 'aanal',
            Email              = 'analyst_test_' + uniqueSuffix + '@novabank.test.com',
            Username           = 'analyst_test_' + uniqueSuffix + '@novabank.test.com',
            ProfileId          = prof.Id,
            UserRoleId         = role.Id,
            TimeZoneSidKey     = 'America/Lima',
            LocaleSidKey       = 'es_PE',
            EmailEncodingKey   = 'UTF-8',
            LanguageLocaleKey  = 'es'
        );
    }

    // =========================================================
    // ACCOUNTS
    // =========================================================

    /**
     * @description Crea e inserta una Account estándar para el usuario Ejecutivo.
     * @param ownerId Id del propietario de la cuenta
     * @return Account insertada con Name y NationalId__c
     */
    public static Account createAccountForExecutive(Id ownerId) {
        Account acc = new Account(
            Name          = 'Juan Perez',
            NationalId__c = '12345678',
            OwnerId       = ownerId,
            // Campos adicionales para verificar que el SOQL solo retorna los requeridos
            Phone         = '999000111',
            BillingCity   = 'Lima'
        );
        insert acc;
        return acc;
    }

    /**
     * @description Crea e inserta una Account estándar para el usuario Analista.
     * @param ownerId Id del propietario de la cuenta
     * @return Account insertada
     */
    public static Account createAccountForAnalyst(Id ownerId) {
        Account acc = new Account(
            Name          = 'Maria Lopez',
            NationalId__c = '87654321',
            OwnerId       = ownerId,
            Phone         = '999000222',
            BillingCity   = 'Miraflores'
        );
        insert acc;
        return acc;
    }

    /**
     * @description Crea e inserta una Account mínima sin propietario explícito
     *              (usará el usuario en contexto). Útil para escenarios genéricos.
     * @param name         Nombre de la cuenta
     * @param nationalId   DNI / NationalId
     * @return Account insertada
     */
    public static Account createAccount(String name, String nationalId) {
        Account acc = new Account(
            Name          = name,
            NationalId__c = nationalId
        );
        insert acc;
        return acc;
    }

    // =========================================================
    // RECORD TYPES (utilidades)
    // =========================================================

    /**
     * @description Retorna el Id del RecordType Lead_Natural_Person.
     *              Si no existe, retorna null (los asserts lo detectarán).
     * @return Id del RecordType o null
     */
    public static Id getLeadNaturalPersonRTId() {
        Map<String, Schema.RecordTypeInfo> rtMap =
            Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName();
        if (rtMap.containsKey(LEAD_RT_DEV_NAME)) {
            return rtMap.get(LEAD_RT_DEV_NAME).getRecordTypeId();
        }
        return null;
    }

    /**
     * @description Retorna el Id del RecordType Case_Natural_Person.
     *              Si no existe, retorna null.
     * @return Id del RecordType o null
     */
    public static Id getCaseNaturalPersonRTId() {
        Map<String, Schema.RecordTypeInfo> rtMap =
            Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();
        if (rtMap.containsKey(CASE_RT_DEV_NAME)) {
            return rtMap.get(CASE_RT_DEV_NAME).getRecordTypeId();
        }
        return null;
    }

    /**
     * @description Genera un Id de 18 caracteres con formato Salesforce
     *              para simular un accountId inexistente en el sistema.
     *              Prefijo 001 = Account.
     * @return String con Id falso pero con formato válido de Salesforce
     */
    public static Id buildFakeAccountId() {
        // Un Id de Salesforce real tiene prefijo de objeto + 15 chars alfanuméricos
        // Usamos un Id que sabemos no existe
        return '001000000000000AAA';
    }
}
