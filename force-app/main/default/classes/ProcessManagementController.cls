/**

* Backend del LWC unificado Venta/PostVenta.

* Actualizado para proveer datos iniciales al modal estándar (Sin DML directo).

*/

public with sharing class ProcessManagementController {
    // Clase contenedora (Wrapper) para enviar todo de un solo viaje
    public class AccountDefaults {
        @AuraEnabled public Account acc;
        @AuraEnabled public Id leadRecordTypeId;
        @AuraEnabled public Id caseRecordTypeId;
    }

    @AuraEnabled(cacheable=true)
    public static AccountDefaults getAccountDefaults(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('El ID de cuenta es obligatorio.');
        }
 
        AccountDefaults defaults = new AccountDefaults();
 
        try {
            // 1. Obtener datos de la cuenta
            defaults.acc = [SELECT Id, Name, NationalId__c 

                            FROM Account 

                            WHERE Id = :accountId 

                            WITH USER_MODE 

                            LIMIT 1];
            // 2. Obtener Record Types
            defaults.leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                .get('Lead_Natural_Person').getRecordTypeId();
            defaults.caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                .get('Case_Natural_Person').getRecordTypeId();
            return defaults;
 
        } catch (QueryException e) {
            throw new AuraHandledException('No se encontró la cuenta o no tiene permisos.');
        } catch (Exception e) {
            throw new AuraHandledException('Error obteniendo configuración: ' + e.getMessage());
        }
    }
}
 