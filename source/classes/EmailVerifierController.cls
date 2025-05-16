public without sharing class EmailVerifierController {

    @AuraEnabled
    public static Boolean verifyEmailDomain(String email){
        List<Email_Domain__mdt> domains = Email_Domain__mdt.getAll().values();
        Boolean isValid = false;
        if (domains.isEmpty()) {
            throw new AuraHandledException('No email domains found.');
        }
        for (Email_Domain__mdt domain : domains) {
            if ( String.isBlank(email) || (email.endsWith(domain.Label) && domain.Is_Active__c) ) {
                isValid = true;
            }else{
                throw new AuraHandledException('Invalid company email.');
            }
        }
        return isValid;
    }
    
    @AuraEnabled
    public static void requestAccessCode(String email) {
        try{
            String code = String.valueOf(Math.round((Math.random() * (900000) + 100000)));

            Email_Verification__c verification = new Email_Verification__c(
                Email__c = email,
                Access_Code__c = code,
                Expires_At__c = System.now().addMinutes(Integer.ValueOf(System.Label.RFP_Expires_Time))
            );
            insert verification;

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { email });
            mail.setSubject('Your Access Code');
            mail.setHtmlBody('Your access code is: <strong>' + code + '</strong>');
            mail.setOrgWideEmailAddressId([SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Access Code Sender' LIMIT 1].Id);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }catch(DmlException e){
            throw new AuraHandledException('Error sending email: ' + e.getMessage());  
        }   
    }

    @AuraEnabled
    public static Boolean verifyAccessCode(String email, String code) {
        List<Email_Verification__c> verification = [
            SELECT Id FROM Email_Verification__c
            WHERE Email__c = :String.escapeSingleQuotes(email)
                AND Access_Code__c = :String.escapeSingleQuotes(code)
                AND Expires_At__c >= :System.now()
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return !verification.isEmpty();
    }
}