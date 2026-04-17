/**

* @description       :

* @author            : ChangeMeIn@UserSettingsUnder.SFDoc

* @group             :

* @last modified on  : 04-16-2026

* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc

**/

public with sharing class LeadConversionService {
 
    // ✅ Inner class que agrupa los datos del Lead necesarios post-conversión

    private class LeadConversionData {

        String fullName;

        String productName;

        String email;
 
        LeadConversionData(Lead l) {

            this.fullName    = String.isBlank(l.FirstName) ? l.LastName : l.FirstName + ' ' + l.LastName;

            this.productName = l.Product__c;

            this.email       = l.Email;

        }

    }
 
    @AuraEnabled

    public static Id convertLead(Id leadId) {

        if (leadId == null) {

            throw new AuraHandledException('ID de Lead inválido.');

        }

        try {

            Lead l = [SELECT Id, FirstName, LastName, Company, NationalId__c, Product__c, Email,

                             ExistingAccount__c, IsConverted, ConvertedOpportunityId

                      FROM Lead

                      WHERE Id = :leadId

                      WITH USER_MODE

                      LIMIT 1];
 
            if (l.IsConverted) {

                return l.ConvertedOpportunityId;

            }
 
            LeadConversionData data = new LeadConversionData(l); // ✅ un solo objeto

            Database.LeadConvert lc = prepareLeadConvert(l, data.fullName);

            Database.LeadConvertResult r = Database.convertLead(lc);
 
            handlePostConversion(r, data); // ✅ solo 2 parámetros
 
            return processResult(r);
 
        } catch (AuraHandledException e) {

            throw e;

        } catch (Exception e) {

            throw new AuraHandledException('Error en conversión: ' + e.getMessage());

        }

    }
 
    private static void handlePostConversion(Database.LeadConvertResult r, LeadConversionData data) {

        if (!r.isSuccess()) { return; }
 
        if (r.getAccountId() != null) {

            update as user new Account(

                Id      = r.getAccountId(),

                Name    = data.fullName,

                Email__c = data.email

            );

        }
 
        if (r.getOpportunityId() != null && String.isNotBlank(data.productName)) {

            enrichOpportunity(r.getOpportunityId(), data.productName);

        }

    }
 
    private static Database.LeadConvert prepareLeadConvert(Lead l, String fullName) {

        Database.LeadConvert lc = new Database.LeadConvert();

        lc.setLeadId(l.Id);

        lc.setConvertedStatus('Closed - Converted');

        lc.setDoNotCreateOpportunity(false);

        lc.setOpportunityName('Opp ' + fullName + ' ' + l.Product__c);
 
        Id targetAccount = findTargetAccount(l);

        if (targetAccount != null) {

            lc.setAccountId(targetAccount);

        }

        return lc;

    }
 
    private static void enrichOpportunity(Id opportunityId, String productName) {

        List<Product2> products = [

            SELECT Id, InterestRate__c

            FROM Product2

            WHERE Name = :productName

            WITH USER_MODE

            LIMIT 1

        ];
 
        if (products.isEmpty()) { return; }
 
        Product2 p = products[0];

        update as user new Opportunity(

            Id             = opportunityId,

            ProductId__c   = p.Id,

            InterestRate__c = p.InterestRate__c

        );

    }
 
    private static Id findTargetAccount(Lead l) {

        if (l.ExistingAccount__c != null) {

            return l.ExistingAccount__c;

        }
 
        if (String.isNotBlank(l.NationalId__c)) {

            List<Account> accounts = [SELECT Id FROM Account

                                      WHERE NationalId__c = :l.NationalId__c

                                      WITH USER_MODE

                                      LIMIT 1];

            if (!accounts.isEmpty()) {

                return accounts[0].Id;

            }

        }

        return null;

    }
 
    private static Id processResult(Database.LeadConvertResult r) {

        if (r.isSuccess()) {

            return r.getOpportunityId();

        }

        throw new AuraHandledException(r.getErrors()[0].getMessage());

    }

}
 