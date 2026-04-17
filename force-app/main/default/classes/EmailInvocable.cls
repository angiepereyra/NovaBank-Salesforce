/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-15-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class EmailInvocable {
    @InvocableMethod(label='Enviar Correo Asíncrono con Adjunto' category='NovaBank')
    public static void sendEmailAsync(List<EmailRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }
 
        System.enqueueJob(new AsyncEmailSender(requests));
    }
}