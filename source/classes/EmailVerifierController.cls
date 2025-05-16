public without sharing class EmailVerifierController {

    @AuraEnabled
    public static Boolean verifyEmailDomain(String email){
        List<Email_Domain__mdt> domains = Email_Domain__mdt.getAll().values();
        Boolean isValid = false;
        Boolean isEmailValid = lockEmail(email, false);

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
        Boolean isValid = lockEmail(email, true);

        if (isValid) {
            throw new AuraHandledException('Email is locked. Please contact support.');
        }

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

    public static Boolean lockEmail(String email, Boolean createAttempt){
        Boolean isLocked = false;
        List<RFP_Verification_Attempt__c> recentAttempts = [
        SELECT Id, Attempt__c, Is_Locked__c FROM RFP_Verification_Attempt__c
        WHERE Email__c = :String.escapeSingleQuotes(email)
        LIMIT 1
        ];

        if (!recentAttempts.isEmpty()) {
            if(recentAttempts[0].Is_Locked__c) {
                isLocked = true;
            }else{
                recentAttempts[0].Attempt__c += 1;
                update recentAttempts[0];
            }
        }
        if(createAttempt && !isLocked && recentAttempts.isEmpty()){
            RFP_Verification_Attempt__c attempt = new RFP_Verification_Attempt__c(
                Email__c = email,
                Attempt__c = 1
            );
            try{
                insert attempt;
            }catch(DmlException e){
                throw new AuraHandledException('Error creating verification attempt: ' + e.getMessage());
            }
        }

        return isLocked;
    }
}
