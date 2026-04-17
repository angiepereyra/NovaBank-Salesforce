/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class BenefitController {
    /**private static void assertAccess() {
        if (!FeatureManagement.checkPermission('BenefitsAccess')) {
            throw new AuraHandledException('Acceso denegado: Se requiere el permiso BenefitsAccess.');
        }
    }**/
 
    @AuraEnabled(cacheable=true)

    public static List<Benefit__c> getBenefits(Id accountId) {
        //assertAccess();
        if (accountId == null) {
            throw new AuraHandledException('AccountId requerido.');
        }
 
        List<FinancialAccount__c> financialAccounts = [
            SELECT ProductId__c
            FROM FinancialAccount__c
            WHERE AccountId__c = :accountId
            WITH USER_MODE
        ];
 
        Set<Id> productIds = new Set<Id>();
        for (FinancialAccount__c fa : financialAccounts) {
            if (fa.ProductId__c != null) {
                productIds.add(fa.ProductId__c);
            }
        }
 
        if (productIds.isEmpty()) {
            return new List<Benefit__c>();
        }

        return [
            SELECT Id, Name, CardName__c, AnnualEffectiveRate__c, Miles__c,
                   CashBack__c, Priority__c, Product2Id__c
            FROM Benefit__c
            WHERE Product2Id__c IN :productIds
            WITH USER_MODE
            ORDER BY Priority__c ASC NULLS LAST
        ];
    }
 
    @AuraEnabled
    public static Benefit__c saveBenefit(Benefit__c b) {
        //assertAccess();
        try {
            upsert as user b;
            return b;
        } catch (DmlException e) {
            throw new AuraHandledException('Error al guardar el beneficio: ' + e.getMessage());
        }
    }
 
    @AuraEnabled

    public static void deleteBenefit(Id benefitId) {
        //assertAccess();
        if (!Schema.sObjectType.Benefit__c.isDeletable()) {
            throw new AuraHandledException('No tienes permisos suficientes para eliminar beneficios.');
        }
        try {
            Benefit__c recordToDelete = [
                SELECT Id
                FROM Benefit__c
                WHERE Id = :benefitId
                WITH USER_MODE
                LIMIT 1
            ];

            delete as user recordToDelete;
        } catch (DmlException e) {
            throw new AuraHandledException('Error al eliminar el beneficio: ' + e.getMessage());
        } catch (QueryException e) {
            throw new AuraHandledException('El registro no existe o no tienes acceso a él.');
        }
    }
}
 