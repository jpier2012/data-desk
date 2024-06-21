public class DD_Util {
    public static final String
        // display data type values
        DELIMITER = '|', 
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
        QUERY_REFERENCE_ID_FIELD = 'referenceIdField',
        QUERY_PROFILE_NAME_LIKE = 'profileNameLike',
        QUERY_RECORD_TYPE_API_NAME = 'recordTypeApiName',
        QUERY_CRITERIA = 'criteria',
        QUERY_ORDER_BY = 'orderBy',
        QUERY_RECORD_LIMIT = 'recordLimit',
        
        // Work order types
        WORK_ORDER_TYPE_QA = 'QA',
        WORK_ORDER_TYPE_GENERATOR = 'Generator',
        
        //QA Process Type
        QA_OPERATION_RECORD_CREATE = 'Record Create',
        QA_OPERATION_RECORD_UPDATE = 'Record Update',
        QA_OPERATION_LEAD_CONVERSION = 'Lead Conversion',
        
        //MISC
        REFERENCE_TYPE_TRIGGER = 'TRIGGER_',
        REFERENCE_TYPE_JUNCTION = 'JUNCTION_',
        REFERENCE_TYPE_SIBLING = 'SIBLING_',
        REFERENCE_TYPE_PARENT = 'PARENT_',
        REFERENCE_TYPE_CHILD = 'CHILD_',
        
        // Log Statii
        JOB_STATUS_COMPLETED = 'Completed',
        JOB_STATUS_FAILED = 'Failed';
    
    public static String[] split(String input){
        String[] result;
        
        try {
            result = input.split('\\' + DELIMITER);
        } catch(Exception e){
            throw new DataDeskException('Error splitting string : ' + e.getMessage());
        }
        
        return result;
    }
    
    // Global describe info to be referenced by all other classes
    public static final Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    
    public static sObject getNewSObject(String objectName, String recordTypeId){
        return schemaMap.get(objectName).newSObject(recordTypeId, true);
    }
    
    public static sObject getNewSObject(String objectName){
        return getNewSObject(objectName, null);
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
    
    public static Schema.DescribeSObjectResult getObjectDescribe(String objectName){
        Schema.DescribeSObjectResult result;
        try {
            result = schemaMap.get(objectName).getDescribe();
        } catch(Exception e) {
            throw new DataDeskException('Error locating sObject describe : ' + objectName, e);
        }
        
        return result;
    }
    
    public static Map<String, Schema.SObjectField> getFieldMap(Schema.DescribeSObjectResult objectDescribe){
        Map<String, Schema.SObjectField> fields;
        try {
            fields = objectDescribe.fields.getMap();
        } catch(Exception e) {
            throw new DataDeskException('Error locating sObject field map : ' + objectDescribe.getName(), e);
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
    
    public static PicklistDescribe getPicklistDescribe(Schema.DescribeFieldResult fieldDescribe){
        List<Map<String, String>> valueMapList = new List<Map<String, String>>();
        String[] values = new String[]{};
        String defaultValue;
        
        List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.isActive()) {
                values.add(entry.getValue());
                
                valueMapList.add(new Map<String, String>{
                   'label' => entry.getLabel(),
                   'value' => entry.getValue()
                });
                
                if (entry.isDefaultValue()) {
                    defaultValue = entry.getValue();
                }    
            }
        }
        
        if (defaultValue == null)
            defaultValue = valueMapList[0].get('value');
        
        PicklistDescribe pld = new PicklistDescribe();
        pld.valueMapList = valueMapList;
        pld.defaultValue = defaultValue;
        pld.valueList = values;
        
        return pld;
    }
    
    public static Map<String, RecordType> getRecordTypes(String objectName) {
        Map<String, RecordType> recordTypesByName = new Map<String, RecordType>();
        RecordType[] recordTypes = [SELECT Id, DeveloperName, Name FROM RecordType 
                                    WHERE SobjectType = :objectName];
        
        for (RecordType recType : recordTypes){
            recordTypesByName.put(recType.DeveloperName, recType);
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
    
    public static DD_Work_Order__c[] getWorkOrders(){
        return getWorkOrders(
            new List<String>(
            	new Map<String, DD_Work_Order__c>([SELECT Id FROM DD_Work_Order__c]).keySet()
            ));
    }
    
    public static DD_Work_Order__c[] getWorkOrders(String[] ids){
        return [SELECT Id, Name, 
                    Object_API_Name__c,
                    JSON_Discrete_Values__c,
                    JSON_Random_Value_Ranges__c, 
                    JSON_Random_Reference_Queries__c,
                    JSON_Random_Picklist_Values__c,
                    Discrete_Values_Only__c, 
                    Parent_Work_Order__c, 
                    Parent_ID_Field__c,
                    Parent_Lookup_Field__c,
                    Base_Quantity__c, 
                    Quantity_Per_Parent__c, 
                    Random_Range__c,
                    Random_Quantity_Per_Parent__c, 
                    Record_Type_API_Name__c, 
                    Record_Type_ID__c, 
                    Collection_Name__c, 
                    Required_Fields__c, 
                    Exclude_Fields__c, 
                    Field_JSON__c, 
               		LastModifiedById 
                FROM DD_Work_Order__c WHERE Id IN :ids
                ORDER BY LastModifiedDate DESC];
    }
    /*
    public static DD_QA_Test__c[] getQaTestsByCollectionId(String collectionId){
        return [SELECT Name, 
                     JSON_QA_Input__c,
                     JSON_QA_Output__c,
                     JSON_QA_Setup_Records__c,
                     Record_Type_API_Name__c, 
                     QA_Operation__c,
                     DD_Test_Collection__c 
                 FROM DD_QA_Test__c
                 WHERE DD_Test_Collection__c = :collectionId
                 ORDER BY Id ASC];
    }
    
    public static DD_Test_Collection__c getTestCollection(String collectionId){
        return [SELECT Name, Trigger_Object_API_Name__c 
                 FROM DD_Test_Collection__c
                 WHERE Id = :collectionId];
    }
    */
    //
    // getIncludedPicklistValues
    //
    public static String[] getIncludedPicklistValues(Schema.DescribeFieldResult fieldDescribe, String includeString){
        List<String> include, values = new List<String>{ };
            
        try {
            include = split(includeString);
        } catch(Exception e){
            throw new DataDeskException('Error splitting picklist include list : ' + includeString, e);
        }
        
        if (String.isBlank(include[0]))
            values.add('');
        
        for (String value : getPicklistDescribe(fieldDescribe).valueList) {
            if (include.contains(value)) {
                values.add(value);
            }
        }
        
        return values;
    }
    
    //
    // splitPicklistValues
    //
    public static String[] splitPicklistValues(String includeString){
        List<String> include, values = new List<String>{ };
            
        try {
            include = split(includeString);
        } catch(Exception e){
            throw new DataDeskException('Error splitting picklist include list : ' + includeString, e);
        }
        
        if (String.isBlank(include[0]))
            values.add('');
        
        values.addAll(include);
        
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
            referenceIdField = params.get(QUERY_REFERENCE_ID_FIELD),
            recordTypeApiName = params.get(QUERY_RECORD_TYPE_API_NAME),
            profileNameLike = params.get(QUERY_PROFILE_NAME_LIKE),
            criteria = params.get(QUERY_CRITERIA),
            orderBy = params.get(QUERY_ORDER_BY),
            recordLimit = params.get(QUERY_RECORD_LIMIT);
        
        String queryString = 'SELECT ' + referenceIdField + ' FROM ' + referencedObjectName;
        
        if (String.isNotBlank(recordTypeApiName)){
            
            queryString += ' WHERE RecordTypeId = \'' + getRecordTypes(referencedObjectName).get(recordTypeApiName).Id + '\'';
            
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
                ids.add(String.valueOf(record.get(referenceIdField)));
            }
        }
        return ids;
    }
        
    //
    // loadGeneratorValues
    //
    public static DDValueLoad loadGeneratorValues(String workOrderId){
        DDValueLoad load = new DDValueLoad();
        Map<String, JSONParse> fieldMap;
        
        DD_Work_Order__c workOrder = getWorkOrder(workOrderId);
        String[] excludeFields = String.isNotBlank(workOrder.Exclude_Fields__c) ? workOrder.Exclude_Fields__c.split(',+\\s*') : new String[]{};
        
        fieldMap = String.isBlank(workOrder.JSON_Discrete_Values__c) ? null : new JSONParse(workOrder.JSON_Discrete_Values__c)?.asMap();
        
        if (fieldMap != null){
            for (String fieldName : fieldMap.keySet()){
                load.discreteValuesByField.put(
                    fieldName, new List<String> { fieldMap.get(fieldName).getStringValue() }
                );
            }
        }
        
        if (!workOrder.Discrete_Values_Only__c){
            fieldMap = String.isBlank(workOrder.JSON_Random_Reference_Queries__c) ? null : new JSONParse(workOrder.JSON_Random_Reference_Queries__c)?.asMap(); 
            
            if (fieldMap != null){
                for (String fieldName : fieldMap.keySet()){
                    if (nix(fieldName, excludeFields, load.discreteValuesByField.keySet()))
                        continue;
                    
                    load.randomValuesByField.put(
                        fieldName, 
                        DD_Util.getReferenceIds(
                            DD_Util.getFieldDescribe(workOrder.Object_API_Name__c, fieldName), 
                            DD_Util.getStringMapFromJson(fieldMap.get(fieldName).asMap()) 
                        )
                    );
                }
            }
            
            fieldMap = String.isBlank(workOrder.JSON_Random_Picklist_Values__c) ? null : new JSONParse(workOrder.JSON_Random_Picklist_Values__c)?.asMap();
            if (fieldMap != null){
                for (String fieldName : fieldMap.keySet()){
                    if (nix(fieldName, excludeFields, load.discreteValuesByField.keySet()))
                        continue;
                    /*
                    load.randomValuesByField.put(
                        fieldName, 
                        DD_Util.getIncludedPicklistValues(
                            DD_Util.getFieldDescribe(workOrder.Object_API_Name__c, fieldName), 
                            fieldMap.get(fieldName).getStringValue() 
                        )
                    );
					*/
                    load.randomValuesByField.put(fieldName, splitPicklistValues(fieldMap.get(fieldName).getStringValue()));
                }
            }
            
            fieldMap = String.isBlank(workOrder.JSON_Random_Value_Ranges__c) ? null : new JSONParse(workOrder.JSON_Random_Value_Ranges__c)?.asMap();
            if (fieldMap != null){
                for (String fieldName : fieldMap.keySet()){
                    if (nix(fieldName, excludeFields, load.discreteValuesByField.keySet()))
                        continue;
                    
                    load.randomValuesByField.put(
                        fieldName, new List<String> { fieldMap.get(fieldName).getStringValue() }
                    );
                }
            }
        }
        
        return load;
    }
    
    public static Boolean nix(String fieldName, String[] excludeFields, Set<String> discreteFields){
        return excludeFields.contains(fieldName) || discreteFields.contains(fieldName);
    }
       
    public class DDValueLoad { 
        public RecordType recordType;
        public Map<String, List<String>> discreteValuesByField, randomValuesByField;
        
        public DDValueLoad(){
            this.discreteValuesByField = new Map<String, List<String>>();
            this.randomValuesByField = new Map<String, List<String>>();
        }
    }
    public class PicklistDescribe {
        public String[] valueList;
        public List<Map<String, String>> valueMapList;
        public String defaultValue;
        
        public PicklistDescribe(String[] valueList, String defaultValue){
            this.valueList = valueList;
            this.defaultValue = defaultValue;
        }
        
        public PicklistDescribe(List<Map<String, String>> valueMapList, String defaultValue){
            this.valueMapList = valueMapList;
            this.defaultValue = defaultValue;
        } 
        
        public PicklistDescribe(){
        }
    }
    
    public static void deleteStuff(){
        delete [SELECT Id FROM Contact WHERE Id NOT IN (SELECT ContactId FROM User)];
    } 
    
    /*
    //
    // loadQaValues
    //
    public static QAValueLoad loadQaValues(String testCollectionId){
        Map<String, JSONParse> recordMap, inputMap, outputMap;
        DD_Test_Collection__c testCollection = getTestCollection(testCollectionId);
        QAValueLoad load = new QAValueLoad();
        load.tests = testCollection.DD_QA_Tests__r;
        
        for (DD_QA_Test__c test : load.tests){
            try {
                inputMap = String.isBlank(test.JSON_QA_Input__c) ? null : new JSONParse(test.JSON_QA_Input__c)?.asMap();
                outputMap = String.isBlank(test.JSON_QA_Output__c) ? null : new JSONParse(test.JSON_QA_Output__c)?.asMap();
            } catch(Exception e){
                throw new DataDeskException('Error parsing QA input or output JSON : ' + test.Name + ' : ' + e.getMessage());
            }
            
            QAObject qa = new QAObject();
            
            for (String reference : inputMap.keySet()){
                recordMap = inputMap.get(reference).asMap();
                Map<String, String> temp = new Map<String, String>();
                for (String fieldName : recordMap.keySet()){
                    temp.put(fieldName, recordMap.get(fieldName).getStringValue());
                }
                qa.triggerObjectApiName = load.testCollection.Trigger_Object_API_Name__c;
                qa.triggerRecordTypeApiName = test.Record_Type_API_Name__c;
                qa.triggerInputValues = temp;
            }
            
            for (String reference : outputMap.keySet()){
                recordMap = outputMap.get(reference)?.asMap();
                Map<String, String> temp = new Map<String, String>();
                for (String fieldName : recordMap.keySet()){
                    temp.put(fieldName, recordMap.get(fieldName).getStringValue());
                }
                qa.outputValuesByReference.put(reference, temp);
            }
            
            load.qaObjectsByTestId.put(test.Id, qa);
        }
        
        return load;
    }
    

    public class QAValueLoad { 
        public Map<String, Set<String>> fieldNamesByObject;
        public String[] triggerRecordIds;
        public Map<String, QAObject> qaObjectsByTestId;
        public DD_Test_Collection__c testCollection;
        public DD_QA_Test__c[] tests;
        public DD_Log__c parentLog;
        public DD_Log__c[] childLogs;
        
        public QAValueLoad(){
            this.triggerRecordIds = new String[]{}; 
            this.fieldNamesByObject = new Map<String, Set<String>>();
            this.qaObjectsByTestId = new Map<String, QAObject>();
            this.childLogs = new DD_Log__c[]{};
        }
    }
    public class QAObject {
        public String 
            triggerRecordId, 
            triggerObjectApiName, 
            triggerRecordTypeApiName;
        
        public Map<String, String> triggerInputValues;
        
        public Map<String, Map<String, String>> 
            setupValuesByReference, 
            outputValuesByReference;
        
        DD_QA_Test__c qaTest;
        
        public QAObject(){
            triggerInputValues = new Map<String, String>();
            setupValuesByReference = new Map<String, Map<String, String>>();
            outputValuesByReference = new Map<String, Map<String, String>>();
        }
    }
    */
}