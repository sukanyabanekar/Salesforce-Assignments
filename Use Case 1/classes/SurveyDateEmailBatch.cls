/** This is batch class written to send an email notification to Contact the if Survey date  is if before today's date based upon
* the language selected at Contact level
**/
global class SurveyDateEmailBatch implements Database.Batchable<sObject>, Database.stateful{
    global List<Contact> contactListUpdate = new List<Contact>();
    global Database.QueryLocator start(Database.BatchableContext bc){
        Integer limitInt = Limits.getLimitQueryLocatorRows() - Limits.getQueryLocatorRows();
        String query = 'SELECT Id, FirstName, Language__c FROM Contact  WHERE Survey_Date__c < TODAY AND Email <> NULL AND Language__c <> NULL LIMIT '+limitInt;
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Contact> contactList){
        if(contactList <> NULL && !contactList.isEmpty()){
            try{
                List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>(); 
                for(Contact conObject: contactList){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  // here I wanted to use mass email but email template is mandatory in mass email and I can not decide the language of contact in email template
                    mail.setTargetObjectId(conObject.Id);
                    String fullRecordURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + conObject.Id;
                    fullRecordURL= '<a href="'+fullRecordURL+'">'+fullRecordURL+'</a>';
                    String body='';
                    if(conObject.Language__c.equalsIgnoreCase('En')){
                        mail.setSubject(system.label.En_Subject);
                        body = 'Hey ' +conObject.FirstName +',' + '<br/><br/> '+system.label.En_body;
                    }
                    else{
                        mail.setSubject(system.label.De_Subject);
                        body = 'Hey ' +conObject.FirstName +',' + '<br/><br/> '+system.label.De_Body;
                    }
                    body+= fullRecordURL;
                    mail.setHTMLBody(body);
                    mailList.add(mail);
                    conObject.Survey_Date__c=null;
                    contactListUpdate.add(conObject);
                }
                if(mailList <> NULL && !mailList.isEmpty()){
                    Messaging.sendEmail(mailList,false);
                }
            }
            catch(Exception e){
                System.debug('You have used up your daily allowance of mails');
                // To handle exception here we can create custom object called Error Handling and add record 
                // for each failed contact with all email details and insert the list in finish method.
            }
        }
    }
    global void finish(Database.BatchableContext BC){
        if(contactListUpdate <> NULL && !contactListUpdate.isEmpty()){
            update contactListUpdate;
        }
        SurveyDateEmailBatch batch= new SurveyDateEmailBatch();
        Database.executeBatch(batch,10);
    }
}