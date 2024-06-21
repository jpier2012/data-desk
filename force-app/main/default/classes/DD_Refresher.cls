public class DD_Refresher {
    public class Input {
        @InvocableVariable(label='Work Order ID') 
        public String workOrderId;
    }

    @InvocableMethod(label='DataDesk) Refresh JSON') 
    public static void refreshJson(Input[] inputs) {
        refresh(null, inputs[0]?.workOrderId);
    }
    
    public static final String 
        COMPANY = 'Company', 
        DESCRIPTION = 'Description', 
        NAME = 'Name', 
        SUBJECT = 'Subject', 
        FIRST_NAME = 'FirstName',
        LAST_NAME = 'LastName';
    
   public static JSONGenerator discreteValues, randomValueRanges, randomReferenceQueries, randomPicklistValues, qaInputOutput;
    
    public static Set<String> fieldIgnoreKeys = new Set<String>{
        'RecordTypeId', 'IndividualId', 'ReportsToId', 'DandbCompanyId', 'Geocode','OwnerId','CleanStatus',
        'OperatingHoursId', 'ParentId', 'hed__Current_Address__c', 'hed__Primary_Household__c', 'hed__Primary_Language__c',
        'hed__Primary_Organization__c', 'EmailBouncedDate', 'Territory2Id', 'EmailBouncedReason', 'Latitude', 'Longitude', 'Preferred'
    };
        
    public static Set<String> defaultTypeIgnores = new Set<String>{
        DD_Util.DISPLAY_TYPE_BOOLEAN, 
        DD_Util.DISPLAY_TYPE_PHONE, 
        DD_Util.DISPLAY_TYPE_EMAIL, 
        DD_Util.DISPLAY_TYPE_URL, 
        DD_Util.DISPLAY_TYPE_ENCRYPTEDSTRING
    }; 
        
    public static String setAddressPicklist(String properCaseName){
        String defaultValue;
        
        if (properCaseName.contains('StateCode')){ 
                                
            defaultValue = 'IL';
            
        } else if (properCaseName.contains('State')){ 
            
            defaultValue = 'Illinois';
            
        } else if (properCaseName.contains('CountryCode')){ 
            
            defaultValue = 'US';
            
        } else if (properCaseName.contains('Country')){ 
            
            defaultValue = 'United States of America (the)';
            
        } 
        
        if (defaultValue != null){
            randomPicklistValues.writeStringField(
                properCaseName, defaultValue
            );
        }
        
        return defaultValue;
    }
 
    public static String setStringDefault(String properCaseName){
        String defaultValue;
        
        if (properCaseName.contains('Street')) {
            
            defaultValue = '123 Address Street';
            discreteValues.writeStringField(properCaseName, defaultValue);
            
        } else if (properCaseName.contains('City')) {
            
            defaultValue = 'Cityville';
            discreteValues.writeStringField(properCaseName, defaultValue);
            
        }  else if (properCaseName.contains('PostalCode')) {
            
            defaultValue = '90210';
            discreteValues.writeStringField(properCaseName, defaultValue);
            
        } else if (properCaseName.contains('FirstName')) {
            
            discreteValues.writeStringField(properCaseName, '[[FNAME]]');
            
        }  else if (properCaseName.contains('LastName')) {
            
            discreteValues.writeStringField(properCaseName, '[[LNAME]]');
            
        } else {
            defaultValue = 'DataDesk [[NOW]]';
        }
        
        return defaultValue;
    }
       
    public static JSONLoad refreshFieldsByObject(String objectName){
            
        discreteValues = JSON.createGenerator(true);
        randomValueRanges = JSON.createGenerator(true);
        randomReferenceQueries = JSON.createGenerator(true);
        randomPicklistValues = JSON.createGenerator(true);
        qaInputOutput = JSON.createGenerator(true);
            
        String[] requiredFields = new String[]{};
            
        discreteValues.writeStartObject();
        randomValueRanges.writeStartObject();
        randomReferenceQueries.writeStartObject();
        randomPicklistValues.writeStartObject();
        
        qaInputOutput.writeStartObject();
        qaInputOutput.writeFieldName(DD_Util.REFERENCE_TYPE_TRIGGER + objectName);
        qaInputOutput.writeStartObject();
        
        Map<String, Schema.SObjectField> fieldMap = DD_Util.getFieldMap(objectName); 
        List<String> fieldSet = new List<String>(fieldMap.keySet());
        fieldSet.sort();
        
        for (String fieldName : fieldSet){
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            String properCaseName = fieldDescribe.getName();
            Boolean ignoreField = false;
            
            for (String key : fieldIgnoreKeys){
                if (properCaseName.contains(key)){
                    ignoreField = true;
                }
            }
            
            if (fieldDescribe.isUpdateable() && !ignoreField){
                String dataType = fieldDescribe.getType().name();
                Boolean 
                    isPicklist = 
                        dataType == DD_Util.DISPLAY_TYPE_PICKLIST 
                        || dataType == DD_Util.DISPLAY_TYPE_MULTIPICKLIST,
                    
                    isNumber = 
                        dataType == DD_Util.DISPLAY_TYPE_PERCENT
                        || dataType == DD_Util.DISPLAY_TYPE_INTEGER
                        || dataType == DD_Util.DISPLAY_TYPE_DOUBLE
                        || dataType == DD_Util.DISPLAY_TYPE_CURRENCY,
                    
                    isRequired = !fieldDescribe.isNillable();
                
                if (!defaultTypeIgnores.contains(dataType)){
                    
                    // First set default values for standard objects based on field name
                    String defaultValue;
                    
                    // Hard-code IL and USA for State and Country codes
                    if (dataType == DD_Util.DISPLAY_TYPE_DATE){
                        
                        String todayDate = DateTime.now().format('yyyy-MM-dd');
                        defaultValue = todayDate;
                        randomValueRanges.writeStringField(properCaseName, todayDate + DD_Util.DELIMITER + todayDate);
                        
                    } else if (dataType == DD_Util.DISPLAY_TYPE_DATETIME){
                        
                        String now = DateTime.now().format('yyyy-MM-dd hh:mm:ss');
                        defaultValue = now;
                        randomValueRanges.writeStringField(properCaseName, now + DD_Util.DELIMITER + now);
                        
                    } else if (dataType == DD_Util.DISPLAY_TYPE_REFERENCE){
                        
                        String referencedObjectName = 
                            fieldDescribe
                            .getReferenceTo()[0]
                            .getDescribe()
                            .getName();
                        
                        Map<String, String> queryMap;
                        
                        if (referencedObjectName == 'User'){
                            queryMap = new Map<String, String>{
                                DD_Util.QUERY_REFERENCE_ID_FIELD => 'Id',
                                    DD_Util.QUERY_PROFILE_NAME_LIKE => '',
                                    DD_Util.QUERY_CRITERIA => 'UserName != null AND isActive = true',
                                    DD_Util.QUERY_ORDER_BY => 'CreatedDate DESC',
                                    DD_Util.QUERY_RECORD_LIMIT => '1'
                                    };
                                        
                        } else {
                            queryMap = new Map<String, String>{
                                DD_Util.QUERY_REFERENCE_ID_FIELD => 'Id',
                                    DD_Util.QUERY_RECORD_TYPE_API_NAME => '',
                                    DD_Util.QUERY_CRITERIA => '(NOT Name IN (\'Example Value\'))',
                                    DD_Util.QUERY_ORDER_BY => 'CreatedDate DESC',
                                    DD_Util.QUERY_RECORD_LIMIT => '1'
                                    };
                        }
                        
                        randomReferenceQueries.writeObjectField(properCaseName, queryMap);
                        
                       	String[] refIds = DD_Util.getReferenceIds(fieldDescribe, queryMap);
                        if (!refIds?.isEmpty()){
                        	defaultValue = DD_Util.getReferenceIds(fieldDescribe, queryMap)[0];
                        }
                        
                    } else if (isNumber){
                        
                        defaultValue = '1';
                        randomValueRanges.writeStringField(properCaseName, '0' + DD_Util.DELIMITER + '10');
                        
                    } else if (isPicklist) {
                        defaultValue = setAddressPicklist(properCaseName);
                        
                        if (defaultValue == null) {
                            
                            DD_Util.PicklistDescribe plDescribe = DD_Util.getPicklistDescribe(fieldDescribe);

                            String[] valuesWithBlank = new List<String>{ };
                            if (isRequired)
                                valuesWithBlank.add('');
                                
                            valuesWithBlank.addAll(plDescribe.valueList);
                            
                            randomPicklistValues.writeStringField(
                                properCaseName, String.join(valuesWithBlank, DD_Util.DELIMITER)
                            );
                            
                            defaultValue = plDescribe.defaultValue;
                        }
                    } else {
                        defaultValue = setStringDefault(properCaseName);
                    }
                    
                    if (isRequired){
                        if (fieldDescribe.getDefaultValue() != null)
                            defaultValue = String.valueOf(fieldDescribe.getDefaultValue());
                        
                        if (fieldDescribe.getDefaultValueFormula() != null)
                            defaultValue = String.valueOf(fieldDescribe.getDefaultValueFormula());
                        
                        requiredFields.add(properCaseName);
                        
                        if (defaultValue != null){
                            discreteValues.writeStringField(properCaseName, defaultValue);
                            qaInputOutput.writeStringField(properCaseName, defaultValue);                            
                        }
                    }
                }
            }
        }
            
        JSONLoad load = new JSONLoad();
        
        qaInputOutput.writeEndObject();
        qaInputOutput.writeEndObject();
        
        load.qaInputOutput = qaInputOutput.getAsString();
        
        discreteValues.writeEndObject();
        load.discreteValues = discreteValues.getAsString();    
        
        randomValueRanges.writeEndObject();
        load.randomValueRanges = randomValueRanges.getAsString();
        
        randomReferenceQueries.writeEndObject();
        load.randomReferenceQueries = randomReferenceQueries.getAsString();
        
        randomPicklistValues.writeEndObject();
        load.randomPicklistValues = randomPicklistValues.getAsString();
        
        load.requiredFieldss = requiredFields;
        
        return load;
    }
        
    public static JSONLoad refresh(String qaTestId, String workOrderId){   
        // Boolean isQa = qaTestId != null ? true : false;
		// DD_QA_Test__c qaTest = new DD_QA_Test__c();
		DD_Work_Order__c workOrder = new DD_Work_Order__c();
        String objectName;
        
        // if (isQa){
            // qaTest = [SELECT Id, QA_Operation__c, DD_Test_Collection__r.Trigger_Object_API_Name__c FROM DD_QA_Test__c WHERE Id = :qaTestId];
            // objectName = qaTest.DD_Test_Collection__r.Trigger_Object_API_Name__c;
        // } else {
            workOrder = [SELECT Id, Object_API_Name__c FROM DD_Work_Order__c WHERE Id = :workOrderId];
            objectName = workOrder.Object_API_Name__c;
        // }
        
        JSONLoad load = refreshFieldsByObject(objectName);
        
        /* if (isQa){
            qaTest.JSON_QA_Input__c = load.qaInputOutput;
            qaTest.JSON_QA_Output__c = load.qaInputOutput;
            
            if (qaTest.QA_Operation__c == DD_Util.QA_OPERATION_RECORD_UPDATE){
                qaTest.JSON_QA_Setup_Records__c = load.qaInputOutput;
            } else {
                qaTest.JSON_QA_Setup_Records__c = '';
            }
            
            qaTest.Required_Fields__c = String.join(load.requiredFields, ', ').left(255);
            update qaTest;             
        } else { */
            workOrder.JSON_Discrete_Values__c = load.discreteValues;      
            workOrder.JSON_Random_Value_Ranges__c = load.randomValueRanges;      
            workOrder.JSON_Random_Reference_Queries__c = load.randomReferenceQueries;   
            workOrder.JSON_Random_Picklist_Values__c = load.randomPicklistValues;
            
            workOrder.Required_Fields__c = String.join(load.requiredFields, ', ').left(255);
            update workOrder;  
        // }
        
        return load;
    }
    
    public class JSONLoad {
        List<FieldDefinition> requiredFields;
        List<FieldDefinition> optionalFields;
        String[] requiredFieldss;
        
        public String discreteValues, randomValueRanges, randomReferenceQueries, randomPicklistValues, qaInputOutput;
        
        public JSONLoad(){
            requiredFieldss = new String[]{};
            requiredFields = new List<FieldDefinition>();
            optionalFields = new List<FieldDefinition>();
        }
    }
    
    public class FieldDefinition {
        public Boolean isRequired;
        public Integer min, max, scale;
        public Date startDate, endDate;
        public String dataType;
        public String[] values;
        public Object defaultValue;
        
        public FieldDefinition(){
        }
    }
    
    public static void testStuff(){
        refresh(null, 'a0g8a00001ZstAPAAZ');
    }
}