public class DD_Util {
    public static final String
        // display data type values
        DISPLAY_TYPE_REFERENCE = 'REFERENCE', 
        DISPLAY_TYPE_PICKLIST = 'PICKLIST', 
        DISPLAY_TYPE_MULTIPICKLIST = 'MULTIPICKLIST', 
        DISPLAY_TYPE_BOOLEAN = 'BOOLEAN',
        DISPLAY_TYPE_EMAIL = 'EMAIL',
        DISPLAY_TYPE_DATE = 'DATE',
        DISPLAY_TYPE_DATETIME = 'DATETIME',
        DISPLAY_TYPE_PHONE = 'PHONE',
        DISPLAY_TYPE_STRING = 'STRING',
        DISPLAY_TYPE_TEXTAREA = 'TEXTAREA',
        DISPLAY_TYPE_DOUBLE = 'DOUBLE',
        DISPLAY_TYPE_INTEGER = 'INTEGER',
        DISPLAY_TYPE_CURRENCY = 'CURRENCY',
        DISPLAY_TYPE_PERCENT = 'PERCENT',
        DISPLAY_TYPE_URL = 'URL',
        DISPLAY_TYPE_ENCRYPTEDSTRING = 'ENCRYPTEDSTRING',
        
        // Query criteria
        QUERY_PROFILE_NAME_LIKE = 'profileNameLike',
        QUERY_RECORD_TYPE_NAME = 'recordTypeName',
        QUERY_CRITERIA = 'criteria',
        QUERY_ORDER_BY = 'orderBy',
        QUERY_RECORD_LIMIT = 'recordLimit';
    
    public static String[] split(String input){
    	return input.split('\\|');
    }
        
    // Global describe info to be referenced by all other classes
    public static final Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    
    public static sObject newSObject(String objectName, String recordTypeId){
        if (String.isNotBlank(recordTypeId)){
        	return schemaMap.get(objectName).newSObject(recordTypeId, true);
        } else {
            return schemaMap.get(objectName).newSObject();
        }
    }
    
    public static Map<String, Schema.SObjectField> getFieldMap(String objectName){
        Map<String, Schema.SObjectField> fields;
        try {
            fields = schemaMap.get(objectName).getDescribe().fields.getMap();
        } catch(Exception e) {
            throw new DataDeskException('Error locating sObject field map : ' + objectName, e);
        }
        
        return fields;
    }
    
    public static DescribeFieldResult getFieldDescribe(String objectName, String fieldName){
        Schema.DescribeFieldResult fieldDescribe;
        try {
            fieldDescribe = getFieldMap(objectName).get(fieldName).getDescribe(); 
        } catch(Exception e){
            throw new DataDeskException('Error locating FieldDescribe : ' + objectName + ', ' + fieldName, e);
        }
        return fieldDescribe;
    }
            
    public static String getDataType(String objectName, String fieldName){
        return getFieldDescribe(objectName, fieldName).getType().name();
    }
    
    public static String[] getActivePicklistValues(Schema.DescribeFieldResult fieldDescribe){
        String[] values = new String[]{};
                        
        List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.isActive()) {
                values.add(entry.getValue());
            }
        }
        
        return values;
    }
    
	public static Map<String, String> getRecordTypeIdsByName(String objectName) {
		Map<String, String> recordTypesByName = new Map<String, Id>();
        RecordType[] recordTypes = [SELECT Id, DeveloperName, Name FROM RecordType WHERE SobjectType = :objectName];
        
        if (recordTypes.isEmpty())
            throw new DataDeskException('No record types found for object name : ' + objectName);
        
		for (RecordType recordType : recordTypes) {
			recordTypesByName.put(recordType.Name, recordType.Id);
		}
		return recordTypesByName;
	}
    
	public static String getProfileIdByName(String searchKey) {
        String searchString = '%' + searchKey + '%';
        Profile profile;
        try {
			profile = [SELECT Id, Name FROM Profile WHERE Name LIKE :searchString LIMIT 1];
        } catch(Exception e){
            throw new DataDeskException('No profile found for search key : ' + searchKey);
        }
		return profile.Id;
	}
    
    private static Set<String> getAllFields(String objectType){
        return new Set<String>(schemaMap.get(objectType).getDescribe().fields.getMap().keySet());
    }
    
    public static Map<String, Object> getParamsFromJsonString(String json){
        Map<String, Object> returnMap = new Map<String, Object>();
        Map<String, JSONParse> tempMap;
        try {
            // Root JSON map
            if (String.isNotBlank(json)){
            	tempMap = new JSONParse(json)?.asMap();
                for (String key : tempMap.keySet()){
                    returnMap.put(key, tempMap.get(key).getValue());
                }
            }
            
        } catch(Exception e){
			throw new DataDeskException('Error parsing JSON parameters. Confirm the formatting is correct : ' + e.getMessage());
        }
        
        return returnMap;
    }
    
    public static Map<String, Object> getParamsFromJsonMap(Map<String, JSONParse> jsonMap){
        Map<String, Object> returnMap = new Map<String, Object>();
        try {
         
            for (String key : jsonMap.keySet()){
                returnMap.put(key, jsonMap.get(key).getValue());
            }
            
        } catch(Exception e){
			throw new DataDeskException('Error parsing JSON parameters : ' + e.getMessage());
        }
        
        return returnMap;
    }
    
    public static Map<String, String> getStringMapFromJson(Map<String, JSONParse> jsonMap){
        Map<String, String> returnMap = new Map<String, String>();
        try {
         
            for (String key : jsonMap.keySet()){
                returnMap.put(key, jsonMap.get(key).getStringValue());
            }
            
        } catch(Exception e){
			throw new DataDeskException('Error parsing JSON parameters to Strings : ' + String.join(new List<String>(returnMap.keySet()), ','), e);
        }
        
        return returnMap;
    }
    
    public static DD_Work_Order__c getWorkOrder(String workOrderId){
        DD_Work_Order__c[] workOrders = getWorkOrders(new String[]{ workOrderId });
        if (!workOrders.isEmpty()){
            return workOrders[0];
        }
        return null;
    }
    
    public static DD_Work_Order__c[] getWorkOrders(String[] ids){
        return [SELECT Id, Name, 
                Object_Name__c,
                JSON_Required_Merge_Values__c,
                JSON_Random_Value_Ranges__c, 
                JSON_Random_Reference_Queries__c,
                JSON_Random_Picklist_Values__c,
                Required_and_Merge_Fields_Only__c, 
                Parent_Work_Order__c, 
                Parent_Lookup_Field__c,
                Base_Quantity__c, 
                Quantity_Per_Parent__c, 
                Random_Range__c,
                Random_Quantity_Per_Parent__c, 
                Parent_Records_Created__c, 
                Stack_Trace__c, 
                Record_Type_Name__c, 
                Status__c FROM DD_Work_Order__c WHERE Id IN :ids];
    }
        
//
// getIncludedPicklistValues
//
    public static String[] getIncludedPicklistValues(Schema.DescribeFieldResult fieldDescribe, String includeString){
        List<String> include, values = new List<String>{};
        
        try {
        	include = split(includeString);
        } catch(Exception e){
            throw new DataDeskException('Error splitting picklist include list : ' + includeString, e);
        }
        
        for (String value : getActivePicklistValues(fieldDescribe)) {
            if (include.contains(value)) {
                values.add(value);
            }
        }
        
        return values;
    }
//
// getReferenceIds
//
    public static String[] getReferenceIds(Schema.DescribeFieldResult fieldDescribe, Map<String, String> params){
        String referencedObjectName = 
            fieldDescribe
            .getReferenceTo()[0]
            .getDescribe()
            .getName();
        
        String 
            queryString = 'SELECT Id FROM ' + referencedObjectName,
            recordTypeName = params.get(QUERY_RECORD_TYPE_NAME),
            profileNameLike = params.get(QUERY_PROFILE_NAME_LIKE),
            criteria = params.get(QUERY_CRITERIA),
            orderBy = params.get(QUERY_ORDER_BY),
            recordLimit = params.get(QUERY_RECORD_LIMIT);
        
        if (String.isNotBlank(recordTypeName)){
           Map<String, String> recordTypeIds = getRecordTypeIdsByName(referencedObjectName);
            
            if (recordTypeIds != null && recordTypeIds?.get(recordTypeName) != null)
        		queryString += ' WHERE RecordTypeId = \'' + recordTypeIds.get(recordTypeName) + '\'';
            
        } else if (String.isNotBlank(profileNameLike)){
        		queryString += ' WHERE ProfileId = \'' + getProfileIdByName(profileNameLike) + '\'';
        }
        
        if (String.isNotBlank(criteria)){
            if (queryString.contains('WHERE')){
                queryString += ' AND ' + criteria;
            } else {
                queryString += ' WHERE ' + criteria;
            }
        }
    
        queryString += String.isNotBlank(orderBy) ? ' ORDER BY ' + orderBy : '';
        queryString += String.isNotBlank(recordLimit) ? ' LIMIT ' + recordLimit : ' LIMIT 10000';
        sObject[] records;
        try {
        	records = Database.query(queryString);                
        } catch(Exception e){
            throw new DataDeskException('Error querying records. Check the query formatting : ' + queryString, e);
        }
        
        String[] ids = new String[]{};
        if (!records.isEmpty()){
            for (sObject record : records){
                ids.add(record.Id);
            }
        	return ids;
        } else {
            throw new DataDeskException('No records found in query : ' + queryString + '. Adjust criteria or create test records.');
        }
    }
    
//
// loadValues
//
    public static ValueLoad loadValues(String workOrderId){
        ValueLoad load = new ValueLoad();
        Map<String, JSONParse> fieldMap;
        
        DD_Work_Order__c workOrder = DD_Util.getWorkOrder(workOrderId);
        
        fieldMap = String.isBlank(workOrder.JSON_Required_Merge_Values__c) ? null : new JSONParse(workOrder.JSON_Required_Merge_Values__c)?.asMap();
        
        if (fieldMap != null){
            for (String fieldName : fieldMap.keySet()){
                load.mergeValuesByField.put(
                    fieldName, new List<String> { fieldMap.get(fieldName).getStringValue() }
                );
            }
        }
        
        if (!workOrder.Required_and_Merge_Fields_Only__c){
            fieldMap = String.isBlank(workOrder.JSON_Random_Reference_Queries__c) ? null : new JSONParse(workOrder.JSON_Random_Reference_Queries__c)?.asMap(); 
            
            if (fieldMap != null){
                for (String fieldName : fieldMap.keySet()){
                    if (load.mergeValuesByField.get(fieldName) == null){
                        load.randomValuesByField.put(
                            fieldName, 
                            DD_Util.getReferenceIds(
                                DD_Util.getFieldDescribe(workOrder.Object_Name__c, fieldName), 
                                DD_Util.getStringMapFromJson(fieldMap.get(fieldName).asMap()) 
                            )
                        );
                    }
                }
            }
            
            fieldMap = String.isBlank(workOrder.JSON_Random_Picklist_Values__c) ? null : new JSONParse(workOrder.JSON_Random_Picklist_Values__c)?.asMap();
            if (fieldMap != null){
                for (String fieldName : fieldMap.keySet()){
                    if (load.mergeValuesByField.get(fieldName) == null){
                        load.randomValuesByField.put(
                            fieldName, 
                            DD_Util.getIncludedPicklistValues(
                               DD_Util.getFieldDescribe(workOrder.Object_Name__c, fieldName), 
                               fieldMap.get(fieldName).getStringValue() 
                            )
                        );
                    }
                }
            }
            
            fieldMap = String.isBlank(workOrder.JSON_Random_Value_Ranges__c) ? null : new JSONParse(workOrder.JSON_Random_Value_Ranges__c)?.asMap();
            if (fieldMap != null){
                for (String fieldName : fieldMap.keySet()){
                    if (load.mergeValuesByField.get(fieldName) == null){
                        load.randomValuesByField.put(
                            fieldName, new List<String> { fieldMap.get(fieldName).getStringValue() }
                        );
                    }
                }
            }
        }
        
        return load;
    }
    
    public class ValueLoad { 
        public Map<String, List<String>> randomValuesByField, mergeValuesByField;
        
        public ValueLoad(Map<String, List<String>> randomValuesByField, Map<String, List<String>> mergeValuesByField){
            this.randomValuesByField = randomValuesByField;
            this.randomValuesByField = mergeValuesByField;
        }
        
        public ValueLoad(){
            this.randomValuesByField = new Map<String, List<String>>(); 
            this.mergeValuesByField = new Map<String, List<String>>();
        }
    }
    
    public static void deleteRecords(){
        User[] users = [SELECT Id, ContactId FROM User];
        String[] ids = new String[]{};
            
            for (User u : users){
                ids.add(u.ContactId);
            }
            
        delete [SELECT Id FROM Contact WHERE Id NOT IN :ids];
        delete [SELECT Id FROM Account WHERE RecordType.Name = 'Household Account' AND Name != 'Sample Account for Entitlements' AND Id NOT IN (SELECT AccountId FROM Contact)];
        delete [SELECT Id FROM Opportunity];
        delete [SELECT Id FROM hed__Application__c];
        delete [SELECT Id FROM Lead];
    }
}