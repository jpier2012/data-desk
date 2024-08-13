public class DD_Deleter implements Database.batchable<sObject>, Database.Stateful {
    public String objectName, startDateString, endDateString;
    public Integer recordCounter;
    public Map<String, String> errorMap;
    
    public DD_Deleter(String objectName, String startDateString, String endDateString){
        this.objectName = objectName;
        this.startDateString = startDateString;
        this.endDateString = endDateString;
        this.recordCounter = 0;
        errorMap = new Map<String, String>();
    }
    
    public static void deleteRecords(String[] objectNames, String startDateString, String endDateString){
        for (String objectName : objectNames){
        	Database.executeBatch(new DD_Deleter(objectName, startDateString, endDateString));
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        Database.QueryLocator locator;
        
        String[] contactIds = new String[]{};
        String queryString = 'SELECT Id FROM ' + objectName + 
            ' WHERE (CreatedById = \'' + UserInfo.getUserId() + 
            '\' OR OwnerId = \'' + UserInfo.getUserId() + '\')';
        
        if (String.isNotBlank(startDateString) && startDateString != 'null'){
            queryString += ' AND CreatedDate >= ' + startDateString.left(10) + 'T00:00:00Z';
        } 
        
        if (String.isNotBlank(endDateString) != null && endDateString != 'null'){
            queryString += ' AND CreatedDate <= ' + endDateString.left(10) + 'T23:59:59Z';
        }
        
        if (objectName == 'Contact'){
                
            for (User u : [SELECT ContactId FROM User WHERE ContactId != null]){
            	contactIds.add(u.ContactId);
            }
            
            queryString += ' AND Id NOT IN :contactIds';
        }
        
        try {
            locator = Database.getQueryLocator(queryString);
        } catch (Exception e){
            throw new DataDeskException('Deleter query string error : ' + e.getLineNumber() + ' : ' + e.getMessage());
        }
        
        return locator;
    }
    public void execute(Database.BatchableContext BC, List<sObject> batch) {
        Database.DeleteResult[] results;
        try {
        	results = Database.delete(batch);
            for (Database.DeleteResult result : results){
                if (result.isSuccess()){
                    recordCounter += 1;
                } else {
                    for(Database.Error err : result.getErrors()) {         
                    	errorMap.put('' + err.getStatusCode(), err.getMessage());
        			}
                }
            }
        } catch(Exception e){
            errorMap.put(e.getTypeName(),
                         'Error deleting ' + objectName + ' records : ' + e.getMessage() + 
                         '. If this is a dependency issue, just run the job again once the others have completed.'
                        );
            
        }
    }
    public void finish(Database.BatchableContext BC) {
        for (String key : errorMap.keySet()){           
            throw new DataDeskException(errorMap.get((new List<String>(errorMap.keySet())[0])));
        }
    }
    
    public class DataDeskException extends Exception {}
}