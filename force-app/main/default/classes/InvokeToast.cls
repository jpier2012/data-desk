public class InvokeToast {
    
    public class NewToast {
        @InvocableVariable(label='Style')
        public String style;
        
        @InvocableVariable(label='Title')
        public String title;
        
        @InvocableVariable(label='Message')
        public String message;
        
        @InvocableVariable(label='Mode')
        public String mode;
      }
    
    @InvocableMethod(label = 'Make a Toast' description = 'Create a Platform Toast event.')
    public static void newToast(List<NewToast> newToasts) {
        NewToast nt = newToasts[0];
        launch(nt.style, nt.mode, nt.title, nt.message); 
    }
    
    public static void launchError(String title, String message) {
        launchWithUrl('error', 'sticky', title, message, null);
    }
    
    public static void launch(String style, String mode, String title, String message) {
        launchWithUrl(style, mode, title, message, null);
    }
    
    public static void launchWithUrl(String style, String mode, String title, String message, String recordId) {
        Platform_Toast__e pe = getNewToast(style, mode, title, message);
        if (recordId != null)
            pe.URL__c = URL.getOrgDomainURL().toExternalForm() + '/' + recordId;
        
        Eventbus.publish(pe);
    }
    
    public static Platform_Toast__e getNewToast(String style, String mode, String title, String message){
        Platform_Toast__e pe = new Platform_Toast__e();
        pe.Style__c = style;
        pe.Mode__c = mode;
        pe.Title__c = title;        
        pe.Message__c = message;
        pe.User__c = UserInfo.getUserId();
        return pe;
    }
}