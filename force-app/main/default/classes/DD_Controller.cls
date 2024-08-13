public class DD_Controller {
	@AuraEnabled
    public static String getFieldDefinitions(String objectApiName){
        return JSON.serialize(DD_Loader.loadSchemaJsonForObject(objectApiName));
    }
    
    @AuraEnabled
    public static String getPicklistValues(String objectApiName, String fieldApiName){
        return DD_Help.getPicklistValueJson(objectApiName, fieldApiName);
    }
    
	@AuraEnabled
    public static String getLastModifiedTemplate(){ 
        return JSON.serialize(DD_Help.getLastModifiedTemplate());
    }
    
	@AuraEnabled
    public static String getTemplates(){ 
        return JSON.serialize(DD_Help.getTemplates());
    }
    
	@AuraEnabled
    public static String runTemplate(String templateJson){             
        return DD_Builder.runTemplateFromJson(templateJson);
    }
    
	@AuraEnabled
    public static String insertTemplate(String jsonString){
        return DD_Builder.insertTemplate(jsonString);
    }
    
	@AuraEnabled
    public static String updateTemplate(String jsonString){ 
        return DD_Builder.updateTemplate(jsonString);
    }
    
    @AuraEnabled
    public static void refreshPageLayout(String jsonString){
        DD_Builder.refreshPageLayout(jsonString);
    }
    
	@AuraEnabled
    public static void deleteRecords(String[] objectNames, String startDate, String endDate){ 
        DD_Deleter.deleteRecords(objectNames, startDate, endDate);
    }
}