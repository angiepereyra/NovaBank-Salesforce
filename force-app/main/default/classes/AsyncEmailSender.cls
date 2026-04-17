/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-15-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class AsyncEmailSender implements Queueable, Database.AllowsCallouts {
 
    private List<EmailRequest> requests;
 
    public AsyncEmailSender(List<EmailRequest> requests) {

        this.requests = requests;

    }
 
    public void execute(QueueableContext context) {

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
 
        // 1. Recolectar IDs

        Set<String> templateNames = new Set<String>();

        Set<Id> recordIds = new Set<Id>();

        Set<Id> accountIds = new Set<Id>();
 
        for(EmailRequest req : requests) {

            templateNames.add(req.templateApiName);

            recordIds.add(req.recordId);

            accountIds.add(req.accountId);

        }
 
        // 2. Consultar base de datos

        Map<Id, Account> accountMap = new Map<Id, Account>(

            [SELECT Id, Email__c FROM Account WHERE Id IN :accountIds]

        );
 
        Map<Id, Id> accountToContactMap = new Map<Id, Id>();

        for(Contact con : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds]) {

            accountToContactMap.put(con.AccountId, con.Id); 

        }
 
        Map<String, Id> templateMap = new Map<String, Id>();

        for(EmailTemplate et : [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :templateNames]) {

            templateMap.put(et.DeveloperName, et.Id);

        }
 
        // CORRECCIÓN AQUÍ: Traemos LatestPublishedVersionId en lugar de ContentDocumentId

        Map<Id, Id> latestDocumentVersionMap = new Map<Id, Id>();

        for(ContentDocumentLink cdl : [

            SELECT LinkedEntityId, ContentDocument.LatestPublishedVersionId 

            FROM ContentDocumentLink 

            WHERE LinkedEntityId IN :recordIds 

            ORDER BY SystemModstamp DESC

        ]) {

            if (!latestDocumentVersionMap.containsKey(cdl.LinkedEntityId)) {

                // Guardamos el ID de la versión (068), no del documento maestro (069)

                latestDocumentVersionMap.put(cdl.LinkedEntityId, cdl.ContentDocument.LatestPublishedVersionId);

            }

        }
 
        // 3. Armar el correo

        for (EmailRequest req : requests) {

            Id templateId = templateMap.get(req.templateApiName);

            Account acc = accountMap.get(req.accountId);

            Id dummyContactId = accountToContactMap.get(req.accountId);
 
            if (templateId == null || acc == null || acc.Email__c == null || dummyContactId == null) {

                continue; 

            }
 
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            mail.setTemplateId(templateId);

            mail.setTargetObjectId(dummyContactId); 

            mail.setWhatId(req.recordId); 

            mail.setTreatTargetObjectAsRecipient(false);

            mail.setToAddresses(new List<String>{acc.Email__c});

            mail.setSaveAsActivity(true);
 
            // Pasamos el ID corregido (ContentVersion) a los adjuntos

            if (latestDocumentVersionMap.containsKey(req.recordId)) {

                mail.setEntityAttachments(new List<Id>{latestDocumentVersionMap.get(req.recordId)});

            }
 
            emailsToSend.add(mail);

        }
 
        // 4. Ejecutar envío

        if (!emailsToSend.isEmpty()) {

            Messaging.sendEmail(emailsToSend);

        }

    }

}
 