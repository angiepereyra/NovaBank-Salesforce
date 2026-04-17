/**
 * @description  Data Factory para pruebas de BenefitController.
 *               Centraliza la creación de datos de prueba (Account, Product2,
 *               FinancialAccount__c y Benefit__c) para todos los escenarios
 *               definidos en el feature file.
 * @author       NovaBank - Bootcamp BCP
 */
@isTest
public class BenefitControllerDataFactory {

    // ─────────────────────────────────────────────────────────────────────────
    // USUARIOS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Crea y retorna el usuario Analista de prueba.
     *              Usa el perfil "Gestión Tarjeta" (ajustar al nombre real del org).
     *              El analista puede leer, crear, editar y eliminar Benefit__c.
     * @return User  Usuario Analista insertado.
     */
    public static User createAnalystUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Gestión Tarjeta' LIMIT 1];
        User u = new User(
            FirstName       = 'Analista',
            LastName        = 'Test',
            Email           = 'analyst.test@novabank.test',
            Username        = 'analyst.test.' + System.currentTimeMillis() + '@novabank.test',
            Alias           = 'anlst',
            TimeZoneSidKey  = 'America/Lima',
            LocaleSidKey    = 'es_PE',
            EmailEncodingKey= 'UTF-8',
            LanguageLocaleKey= 'es',
            ProfileId       = p.Id
        );
        insert u;
        return u;
    }

    /**
     * @description Crea y retorna el usuario Ejecutivo de prueba.
     *              Usa el perfil "Asesor de Venta y Reclamos".
     *              El ejecutivo NO puede eliminar Benefit__c.
     * @return User  Usuario Ejecutivo insertado.
     */
    public static User createExecutiveUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Asesor de Venta y Reclamos' LIMIT 1];
        User u = new User(
            FirstName       = 'Ejecutivo',
            LastName        = 'Test',
            Email           = 'executive.test@novabank.test',
            Username        = 'executive.test.' + System.currentTimeMillis() + '@novabank.test',
            Alias           = 'exec',
            TimeZoneSidKey  = 'America/Lima',
            LocaleSidKey    = 'es_PE',
            EmailEncodingKey= 'UTF-8',
            LanguageLocaleKey= 'es',
            ProfileId       = p.Id
        );
        insert u;
        return u;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ACCOUNT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Crea e inserta una Account de persona natural.
     * @param lastName  Apellido del cliente (distingue registros entre escenarios).
     * @return Account  Registro insertado con Id asignado.
     */
    public static Account createAccount(String lastName) {
        Account acc = new Account(
            Name        = lastName,
            Email__c     = lastName.toLowerCase() + '@novabank.test',
            RecordTypeId    = getPersonAccountRecordTypeId()
        );
        insert acc;
        return acc;
    }

    /**
     * @description Obtiene el RecordType Id de Person Account.
     *              Si el org no tiene Person Accounts habilitado, retorna null
     *              y los tests deberán ajustar la creación de Account.
     * @return Id
     */
    private static Id getPersonAccountRecordTypeId() {
        List<RecordType> rtList = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount'
            LIMIT 1
        ];
        return rtList.isEmpty() ? null : rtList[0].Id;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PRODUCT2
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Crea e inserta un Product2 que representa una tarjeta de crédito.
     * @param productName  Nombre del producto (ej: 'Visa Oro', 'Visa Plata').
     * @return Product2  Registro insertado con Id asignado.
     */
    public static Product2 createProduct(String productName) {
        Product2 prod = new Product2(
            Name        = productName,
            IsActive    = true,
            Description = 'Tarjeta de crédito ' + productName
        );
        insert prod;
        return prod;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // FINANCIAL ACCOUNT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Crea e inserta un FinancialAccount__c asociado a una Account y un Product2.
     * @param accountId  Id de la Account titular.
     * @param productId  Id del Product2 asociado (puede ser null para probar ese escenario).
     * @return FinancialAccount__c  Registro insertado.
     */
    public static FinancialAccount__c createFinancialAccount(Id accountId, Id productId) {
        FinancialAccount__c fa = new FinancialAccount__c(
            AccountId__c    = accountId,
            ProductId__c    = productId,
            CardNumber__c   = '4111111111111' + String.valueOf(Math.round(Math.random() * 999)).leftPad(3,'0'),
            CardType__c     = 'Visa Oro',
            ApprovedCreditLine__c = 5000,
            IssuanceDate__c    = Date.today(),
            Status__c       = 'Activa'
        );
        insert fa;
        return fa;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // BENEFIT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Crea e inserta un único Benefit__c asociado a un Product2.
     * @param productId   Id del Product2 al que pertenece el beneficio.
     * @param cardName    Nombre de la tarjeta (ej: 'Visa Oro').
     * @param priority    Orden de presentación (menor número = mayor prioridad).
     * @return Benefit__c Registro insertado.
     */
    public static Benefit__c createBenefit(Id productId, String cardName, Integer priority) {
        Benefit__c b = new Benefit__c(
            Name                  = cardName + ' - Beneficio ' + priority,
            CardName__c           = cardName,
            AnnualEffectiveRate__c= 24.5,
            Miles__c              = 500,
            CashBack__c           = 2.0,
            Priority__c           = priority,
            Product2Id__c         = productId
        );
        insert b;
        return b;
    }

    /**
     * @description Crea e inserta una lista de Benefit__c asociados a un Product2,
     *              con prioridades correlativas comenzando en 1.
     * @param productId  Id del Product2.
     * @param cardName   Nombre de la tarjeta.
     * @param quantity   Cantidad de beneficios a crear.
     * @return List<Benefit__c>  Lista de registros insertados.
     */
    public static List<Benefit__c> createBenefits(Id productId, String cardName, Integer quantity) {
        List<Benefit__c> benefits = new List<Benefit__c>();
        for (Integer i = 1; i <= quantity; i++) {
            benefits.add(new Benefit__c(
                Name                  = cardName + ' - Beneficio ' + i,
                CardName__c           = cardName,
                AnnualEffectiveRate__c= 24.5 + i,
                Miles__c              = 100 * i,
                CashBack__c           = i * 0.5,
                Priority__c           = i,
                Product2Id__c         = productId
            ));
        }
        insert benefits;
        return benefits;
    }

    /**
     * @description Construye (sin insertar) un Benefit__c con campos mínimos nulos
     *              para provocar un error DML al llamar a saveBenefit.
     *              Ajustar según los campos requeridos reales del objeto.
     * @return Benefit__c  Objeto sin insertar con campo requerido nulo.
     */
    public static Benefit__c buildInvalidBenefit() {
        // Se retorna sin Name (campo requerido en Salesforce por defecto)
        return new Benefit__c(
            CardName__c           = null,
            AnnualEffectiveRate__c= null,
            Product2Id__c         = null
        );
    }
}
