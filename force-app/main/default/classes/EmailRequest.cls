/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-15-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class EmailRequest {
    @InvocableVariable(required=true) 
    public Id recordId;
    @InvocableVariable(required=true) 
    public Id accountId;
    @InvocableVariable(required=true) 
    public String templateApiName;
}