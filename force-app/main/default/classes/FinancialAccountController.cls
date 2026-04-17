/**

 * @description Controller para gestionar cuentas financieras (FinancialAccount__c).

 * Cumple con seguridad CRUD/FLS y reglas de estilo PMD.

 */

public with sharing class FinancialAccountController {
    
    /**
    
     * @description Obtiene las cuentas financieras vinculadas a una cuenta.
    
     * @param accountId ID de la cuenta (Account)
    
     * @return Lista de FinancialAccount__c
    
     */
    
    @AuraEnabled(cacheable=true)
    
    public static List<FinancialAccount__c> getByAccount(Id accountId) {
        
        if (accountId == null) {
            
            return new List<FinancialAccount__c>();
            
        }
        
        Boolean canReadCardNumber = Schema.sObjectType.FinancialAccount__c
            .fields.CardNumber__c.isAccessible();
        
        String query = 'SELECT Id, Name, CardType__c, ApprovedCreditLine__c, Status__c,' +
            ' IssuanceDate__c, AccountId__r.Name';
        
        if (canReadCardNumber) {
            query += ', CardNumber__c';
        }
        
        query += ' FROM FinancialAccount__c' +
            ' WHERE AccountId__c = :accountId' +
            ' ORDER BY IssuanceDate__c DESC';
        
        // ✅ queryWithBinds evita SOQL injection pasando variables en un mapa separado
        Map<String, Object> binds = new Map<String, Object>{ 'accountId' => accountId };
        List<FinancialAccount__c> records = Database.queryWithBinds(query, binds, AccessLevel.USER_MODE);
        
        // ✅ stripInaccessible elimina campos sin permiso de lectura del usuario actual
        
        // Si Ejecutivo no tiene Read en CardNumber__c, ese campo no llega al LWC
        
        SObjectAccessDecision decision = Security.stripInaccessible(
            
        AccessType.READABLE,
        
        records
            
        );
        
        return decision.getRecords();
        
    }
    
    /**
    
     * @description Guarda o actualiza una cuenta financiera.
    
     * @param fa Registro de FinancialAccount__c
    
     * @return El registro procesado
    
     */
    
    @AuraEnabled
    public static FinancialAccount__c save(FinancialAccount__c fa) {
        try {
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.UPSERTABLE,
            new List<FinancialAccount__c>{ fa }
            );
            
            // ✅ Cast explícito a FinancialAccount__c
            List<FinancialAccount__c> cleanRecords = (List<FinancialAccount__c>) decision.getRecords();
            upsert as user cleanRecords[0];
            return cleanRecords[0];
            
        } catch (DmlException e) {
            throw new AuraHandledException('Error al guardar: ' + e.getMessage());
        }
    }
    
    /**
    
     * @description Elimina una cuenta financiera validando permisos de borrado.
    
     * @param faId ID del registro a eliminar
    
     */
    
    @AuraEnabled
    
    public static void remove(Id faId) {
        
        if (!Schema.sObjectType.FinancialAccount__c.isDeletable()) {
            
            throw new AuraHandledException('No tienes permisos para eliminar este registro.');
            
        }
        
        try {
            
            FinancialAccount__c recordToDelete = [

                SELECT Id

                FROM FinancialAccount__c

                WHERE Id = :faId

                WITH USER_MODE

                LIMIT 1

            ];
            
            delete as user recordToDelete;
            
        } catch (DmlException e) {
            
            throw new AuraHandledException('Error al eliminar: ' + e.getMessage());
            
        } catch (QueryException e) {
            
            throw new AuraHandledException('El registro no existe o no tienes acceso.');
            
        }
        
    }
    
}