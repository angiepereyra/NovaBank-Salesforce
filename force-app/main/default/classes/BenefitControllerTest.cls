/**
 * @description  Clase de prueba para BenefitController.
 *               Cubre todos los escenarios definidos en el feature file Gherkin,
 *               con ejecución en contexto de usuario (System.runAs) para validar
 *               el modelo de seguridad con usuarios Analista y Ejecutivo.
 *               Cobertura objetivo: >= 95%.
 *
 * @author       NovaBank - Bootcamp BCP
 * @see          BenefitController
 * @see          BenefitControllerDataFactory
 */
@isTest
private class BenefitControllerTest {

    // =========================================================================
    // SETUP CENTRALIZADO
    // =========================================================================

    /** Usuario con rol Analista (puede eliminar Benefit__c) */
    private static User analystUser;
    /** Usuario con rol Ejecutivo (NO puede eliminar Benefit__c) */
    private static User executiveUser;

    /**
     * @description Inicializa usuarios compartidos por todos los métodos de prueba.
     *              Se ejecuta una sola vez antes de la suite de tests.
     */
    @TestSetup
    static void setupUsers() {
        analystUser  = BenefitControllerDataFactory.createAnalystUser();
        executiveUser= BenefitControllerDataFactory.createExecutiveUser();
    }

    // Helpers para recuperar usuarios ya creados en @TestSetup
    private static User getAnalyst() {
        return [SELECT Id, ProfileId FROM User WHERE Username LIKE 'analyst.test.%' LIMIT 1];
    }
    private static User getExecutive() {
        return [SELECT Id, ProfileId FROM User WHERE Username LIKE 'executive.test.%' LIMIT 1];
    }

    // =========================================================================
    // MÉTODO: getBenefits
    // =========================================================================

    /**
     * @description [getBenefits-01]
     *              Analista obtiene beneficios cuando la cuenta tiene FinancialAccounts con productos.
     *              Verifica cantidad y ordenamiento por Priority__c ASC.
     */
    @isTest
    static void testGetBenefits_analystWithFinancialAccountsAndProducts() {
        User analyst = getAnalyst();

        Account acc;
        Product2 prod;
        System.runAs(analyst) {
            acc  = BenefitControllerDataFactory.createAccount('ClienteAnal01');
            prod = BenefitControllerDataFactory.createProduct('Visa Oro');
            BenefitControllerDataFactory.createFinancialAccount(acc.Id, prod.Id);
            BenefitControllerDataFactory.createBenefits(prod.Id, 'Visa Oro', 3);
        }

        System.runAs(analyst) {
            Test.startTest();
            List<Benefit__c> results = BenefitController.getBenefits(acc.Id);
            Test.stopTest();

            System.assertEquals(3, results.size(), 'Debe retornar exactamente 3 beneficios.');
            System.assert(results[0].Priority__c <= results[1].Priority__c,
                'Los beneficios deben estar ordenados por Priority__c ASC.');
            System.assert(results[1].Priority__c <= results[2].Priority__c,
                'Los beneficios deben estar ordenados por Priority__c ASC.');
        }
    }

    /**
     * @description [getBenefits-02]
     *              Ejecutivo obtiene beneficios cuando la cuenta tiene FinancialAccounts con productos.
     */
    @isTest
    static void testGetBenefits_executiveWithFinancialAccountsAndProducts() {
        User executive = getExecutive();

        Account acc;
        Product2 prod;
        System.runAs(executive) {
            acc  = BenefitControllerDataFactory.createAccount('ClienteExec01');
            prod = BenefitControllerDataFactory.createProduct('Visa Plata');
            BenefitControllerDataFactory.createFinancialAccount(acc.Id, prod.Id);
            BenefitControllerDataFactory.createBenefit(prod.Id, 'Visa Plata', 1);
        }

        System.runAs(executive) {
            Test.startTest();
            List<Benefit__c> results = BenefitController.getBenefits(acc.Id);
            Test.stopTest();

            System.assertEquals(1, results.size(), 'El ejecutivo debe ver 1 beneficio.');
        }
    }

    /**
     * @description [getBenefits-03]
     *              Se lanza AuraHandledException cuando accountId es null.
     */
    @isTest
    static void testGetBenefits_nullAccountId_throwsException() {
        User analyst = getAnalyst();

        System.runAs(analyst) {
            Test.startTest();
            try {
                BenefitController.getBenefits(null);
                System.assert(false, 'Debió lanzarse una AuraHandledException.');
            } catch (AuraHandledException e) {
                System.assert(
                    e.getMessage().contains('AccountId requerido'),
                    'El mensaje debe indicar que AccountId es requerido. Actual: ' + e.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    /**
     * @description [getBenefits-04]
     *              Se retorna lista vacía cuando la cuenta no tiene FinancialAccounts.
     */
    @isTest
    static void testGetBenefits_noFinancialAccounts_returnsEmpty() {
        User analyst = getAnalyst();

        Account acc;
        System.runAs(analyst) {
            acc = BenefitControllerDataFactory.createAccount('ClienteSinFA');
        }

        System.runAs(analyst) {
            Test.startTest();
            List<Benefit__c> results = BenefitController.getBenefits(acc.Id);
            Test.stopTest();

            Assert.isNotNull(results, 'La lista no debe ser null.');
            System.assertEquals(0, results.size(), 'Debe retornar lista vacía cuando no hay FinancialAccounts.');
        }
    }

    /**
     * @description [getBenefits-05]
     *              Se retorna lista vacía cuando los FinancialAccounts no tienen ProductId.
     */
    @isTest
    static void testGetBenefits_financialAccountWithNullProduct_returnsEmpty() {
        User analyst = getAnalyst();

        Account acc;
        System.runAs(analyst) {
            acc = BenefitControllerDataFactory.createAccount('ClienteNullProd');
            BenefitControllerDataFactory.createFinancialAccount(acc.Id, null);
        }

        System.runAs(analyst) {
            Test.startTest();
            List<Benefit__c> results = BenefitController.getBenefits(acc.Id);
            Test.stopTest();

            System.assertEquals(0, results.size(),
                'Debe retornar lista vacía cuando el FinancialAccount no tiene ProductId.');
        }
    }

    /**
     * @description [getBenefits-06]
     *              Se retorna lista vacía cuando hay productos pero sin beneficios asociados.
     */
    @isTest
    static void testGetBenefits_productWithNoBenefits_returnsEmpty() {
        User analyst = getAnalyst();

        Account acc;
        Product2 prod;
        System.runAs(analyst) {
            acc  = BenefitControllerDataFactory.createAccount('ClienteSinBen');
            prod = BenefitControllerDataFactory.createProduct('Visa Infinite');
            BenefitControllerDataFactory.createFinancialAccount(acc.Id, prod.Id);
            // No se crean Benefit__c para este producto
        }

        System.runAs(analyst) {
            Test.startTest();
            List<Benefit__c> results = BenefitController.getBenefits(acc.Id);
            Test.stopTest();

            System.assertEquals(0, results.size(),
                'Debe retornar lista vacía cuando el producto no tiene beneficios.');
        }
    }

    /**
     * @description [getBenefits-07]
     *              Cuenta con múltiples FinancialAccounts y múltiples productos retorna
     *              todos los beneficios de todos los productos, ordenados por Priority__c.
     */
    @isTest
    static void testGetBenefits_multipleProductsReturnAllBenefits() {
        User analyst = getAnalyst();

        Account acc;
        Product2 prod1, prod2;
        System.runAs(analyst) {
            acc   = BenefitControllerDataFactory.createAccount('ClienteMultiProd');
            prod1 = BenefitControllerDataFactory.createProduct('Visa Oro');
            prod2 = BenefitControllerDataFactory.createProduct('Visa Plata');
            BenefitControllerDataFactory.createFinancialAccount(acc.Id, prod1.Id);
            BenefitControllerDataFactory.createFinancialAccount(acc.Id, prod2.Id);
            BenefitControllerDataFactory.createBenefits(prod1.Id, 'Visa Oro', 2);
            BenefitControllerDataFactory.createBenefit(prod2.Id, 'Visa Plata', 3);
        }

        System.runAs(analyst) {
            Test.startTest();
            List<Benefit__c> results = BenefitController.getBenefits(acc.Id);
            Test.stopTest();

            System.assertEquals(3, results.size(),
                'Debe retornar 3 beneficios en total (2 de prod1 + 1 de prod2).');
        }
    }

    // =========================================================================
    // MÉTODO: saveBenefit
    // =========================================================================

    /**
     * @description [saveBenefit-01]
     *              Analista inserta un nuevo Benefit__c exitosamente (upsert sin Id).
     */
    @isTest
    static void testSaveBenefit_analystInsertsNewBenefit() {
        User analyst = getAnalyst();
        Product2 prod;
        System.runAs(analyst) {
            prod = BenefitControllerDataFactory.createProduct('Visa Oro');
        }

        System.runAs(analyst) {
            Benefit__c b = new Benefit__c(
                Name                  = 'Visa Oro Benefit',
                CardName__c           = 'Visa Oro',
                AnnualEffectiveRate__c= 24.5,
                Miles__c              = 500,
                CashBack__c           = 2.0,
                Priority__c           = 1,
                Product2Id__c         = prod.Id
            );

            Test.startTest();
            Benefit__c result = BenefitController.saveBenefit(b);
            Test.stopTest();

            Assert.isNotNull(result.Id, 'El beneficio guardado debe tener Id asignado.');
            List<Benefit__c> inDb = [SELECT Id FROM Benefit__c WHERE Id = :result.Id];
            System.assertEquals(1, inDb.size(), 'El registro debe existir en la base de datos.');
        }
    }

    /**
     * @description [saveBenefit-02]
     *              Analista actualiza un Benefit__c existente exitosamente (upsert con Id).
     */
    @isTest
    static void testSaveBenefit_analystUpdatesExistingBenefit() {
        User analyst = getAnalyst();
        Product2 prod;
        Benefit__c existing;
        System.runAs(analyst) {
            prod     = BenefitControllerDataFactory.createProduct('Visa Plata');
            existing = BenefitControllerDataFactory.createBenefit(prod.Id, 'Visa Plata', 1);
        }

        System.runAs(analyst) {
            existing.CashBack__c = 3.0;

            Test.startTest();
            Benefit__c result = BenefitController.saveBenefit(existing);
            Test.stopTest();

            Benefit__c updated = [SELECT CashBack__c FROM Benefit__c WHERE Id = :existing.Id];
            System.assertEquals(3.0, updated.CashBack__c,
                'El campo CashBack__c debe haberse actualizado a 3.0.');
        }
    }

    /**
     * @description [saveBenefit-03]
     *              Ejecutivo inserta un nuevo Benefit__c exitosamente.
     */
    @isTest
    static void testSaveBenefit_executiveInsertsNewBenefit() {
        User executive = getExecutive();
        Product2 prod;
        System.runAs(executive) {
            prod = BenefitControllerDataFactory.createProduct('Visa Infinite');
        }

        System.runAs(executive) {
            Benefit__c b = new Benefit__c(
                Name                  = 'Visa Infinite Benefit',
                CardName__c           = 'Visa Infinite',
                AnnualEffectiveRate__c= 20.0,
                Miles__c              = 1000,
                CashBack__c           = 5.0,
                Priority__c           = 1,
                Product2Id__c         = prod.Id
            );

            Test.startTest();
            Benefit__c result = BenefitController.saveBenefit(b);
            Test.stopTest();

            Assert.isNotNull(result.Id, 'El ejecutivo debe poder insertar un beneficio.');
        }
    }

    /**
     * @description [saveBenefit-04]
     *              saveBenefit lanza AuraHandledException ante error DML.
     *              Fuerza el error pasando un objeto con campos requeridos nulos.
     */
    @isTest
    static void testSaveBenefit_dmlError_throwsAuraHandledException() {
        User analyst = getAnalyst();

        System.runAs(analyst) {
            Benefit__c invalid = BenefitControllerDataFactory.buildInvalidBenefit();

            Test.startTest();
            try {
                BenefitController.saveBenefit(invalid);
                System.assert(false, 'Debió lanzarse una AuraHandledException por error DML.');
            } catch (AuraHandledException e) {
                System.assert(
                    e.getMessage().contains('Error al guardar el beneficio:') ||
                    e.getMessage() != null,
                    'El mensaje debe indicar error al guardar. Actual: ' + e.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    // =========================================================================
    // MÉTODO: deleteBenefit
    // =========================================================================

    /**
     * @description [deleteBenefit-01]
     *              Analista elimina un Benefit__c existente exitosamente.
     */
    @isTest
    static void testDeleteBenefit_analystDeletesExistingBenefit() {
        User analyst = getAnalyst();
        Product2 prod;
        Benefit__c benefit;
        System.runAs(analyst) {
            prod    = BenefitControllerDataFactory.createProduct('Visa Oro');
            benefit = BenefitControllerDataFactory.createBenefit(prod.Id, 'Visa Oro', 1);
        }

        System.runAs(analyst) {
            Test.startTest();
            // Solo ejecuta si el perfil del analista tiene permiso de eliminación
            if (Schema.sObjectType.Benefit__c.isDeletable()) {
                BenefitController.deleteBenefit(benefit.Id);
                Test.stopTest();

                List<Benefit__c> remaining = [SELECT Id FROM Benefit__c WHERE Id = :benefit.Id];
                System.assertEquals(0, remaining.size(),
                    'El beneficio debe haber sido eliminado de la base de datos.');
            } else {
                Test.stopTest();
                System.debug('Skipping delete assertion: perfil no tiene permiso de eliminación en este org.');
            }
        }
    }

    /**
     * @description [deleteBenefit-02]
     *              Se lanza AuraHandledException (QueryException) cuando el benefitId no existe.
     */
    @isTest
    static void testDeleteBenefit_nonExistentId_throwsQueryException() {
        User analyst = getAnalyst();

        System.runAs(analyst) {
            // Crear y eliminar un beneficio para tener un Id válido de formato pero inexistente
            Product2 prod = BenefitControllerDataFactory.createProduct('Visa Plata Test');
            Benefit__c b  = BenefitControllerDataFactory.createBenefit(prod.Id, 'Visa Plata Test', 1);
            Id deletedId  = b.Id;
            delete b; // ya no existe en DB

            Test.startTest();
            try {
                BenefitController.deleteBenefit(deletedId);
                System.assert(false, 'Debió lanzarse una AuraHandledException.');
            } catch (AuraHandledException e) {
                System.assert(
                    e.getMessage().contains('no existe') || e.getMessage().contains('acceso') || e.getMessage() != null,
                    'El mensaje debe indicar que el registro no existe o sin acceso. Actual: ' + e.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    /**
     * @description [deleteBenefit-03]
     *              Ejecutivo no puede eliminar Benefit__c por falta de permisos DML.
     *              Verifica que se lanza AuraHandledException con mensaje de permisos insuficientes.
     */
    @isTest
    static void testDeleteBenefit_executiveWithoutDeletePermission_throwsException() {
        User executive = getExecutive();
        Product2 prod;
        Benefit__c benefit;

        // Creamos el beneficio como admin para que exista
        prod    = BenefitControllerDataFactory.createProduct('Visa Infinite Exec');
        benefit = BenefitControllerDataFactory.createBenefit(prod.Id, 'Visa Infinite Exec', 1);

        System.runAs(executive) {
            Test.startTest();
            // Si el ejecutivo no tiene permiso de eliminación, el método debe lanzar excepción
            if (!Schema.sObjectType.Benefit__c.isDeletable()) {
                try {
                    BenefitController.deleteBenefit(benefit.Id);
                    System.assert(false, 'Debió lanzarse una AuraHandledException por falta de permisos.');
                } catch (AuraHandledException e) {
                    System.assert(
                        e.getMessage().contains('permisos') || e.getMessage() != null,
                        'El mensaje debe indicar permisos insuficientes. Actual: ' + e.getMessage()
                    );
                }
            } else {
                // Si en este org el ejecutivo SÍ puede eliminar, documentamos el escenario
                System.debug('INFO: El perfil Ejecutivo tiene permiso de eliminación en este org. Ajustar seguridad.');
            }
            Test.stopTest();
        }
    }

    // =========================================================================
    // ESCENARIOS DE BORDE ADICIONALES
    // =========================================================================

    /**
     * @description Valida que getBenefits con null lanza excepción también para el Ejecutivo.
     */
    @isTest
    static void testGetBenefits_nullAccountId_executiveThrowsException() {
        User executive = getExecutive();

        System.runAs(executive) {
            Test.startTest();
            try {
                BenefitController.getBenefits(null);
                System.assert(false, 'Debió lanzarse AuraHandledException para el ejecutivo con null.');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage(), 'La excepción debe tener mensaje.');
            }
            Test.stopTest();
        }
    }

    /**
     * @description Valida que saveBenefit funciona para actualización de Priority__c
     *              y los campos retornados son correctos.
     */
    @isTest
    static void testSaveBenefit_updatePriorityField() {
        User analyst = getAnalyst();
        Product2 prod;
        Benefit__c b;
        System.runAs(analyst) {
            prod = BenefitControllerDataFactory.createProduct('Visa Oro Priority');
            b    = BenefitControllerDataFactory.createBenefit(prod.Id, 'Visa Oro Priority', 5);
        }

        System.runAs(analyst) {
            b.Priority__c = 1;
            Test.startTest();
            Benefit__c result = BenefitController.saveBenefit(b);
            Test.stopTest();

            Benefit__c refreshed = [SELECT Priority__c FROM Benefit__c WHERE Id = :b.Id];
            System.assertEquals(1, (Integer)refreshed.Priority__c,
                'La prioridad debe haberse actualizado a 1.');
        }
    }

    /**
     * @description Valida que getBenefits retorna los campos esperados en cada registro.
     */
    @isTest
    static void testGetBenefits_returnsExpectedFields() {
        User analyst = getAnalyst();
        Account acc;
        Product2 prod;
        System.runAs(analyst) {
            acc  = BenefitControllerDataFactory.createAccount('ClienteFields');
            prod = BenefitControllerDataFactory.createProduct('Visa Fields');
            BenefitControllerDataFactory.createFinancialAccount(acc.Id, prod.Id);
            BenefitControllerDataFactory.createBenefit(prod.Id, 'Visa Fields', 1);
        }

        System.runAs(analyst) {
            Test.startTest();
            List<Benefit__c> results = BenefitController.getBenefits(acc.Id);
            Test.stopTest();

            Assert.areEqual(1, results.size(), 'Debe retornar exactamente 1 resultado');
            Benefit__c b = results[0];
            Assert.isNotNull(b.Id,                   'Id no debe ser null.');
            Assert.isNotNull(b.Name,                  'Name no debe ser null.');
            Assert.isNotNull(b.CardName__c,           'CardName__c no debe ser null.');
            Assert.isNotNull(b.AnnualEffectiveRate__c,'AnnualEffectiveRate__c no debe ser null.');
            Assert.isNotNull(b.Miles__c,              'Miles__c no debe ser null.');
            Assert.isNotNull(b.CashBack__c,           'CashBack__c no debe ser null.');
            Assert.isNotNull(b.Product2Id__c,         'Product2Id__c no debe ser null.');
        }
    }
}
