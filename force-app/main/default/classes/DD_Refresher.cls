public class DD_Refresher {
    public class Input {
        @InvocableVariable(label='Work Order ID') 
        public String workOrderId;
    }

    @InvocableMethod(label='Refresh Work Order JSON')
    public static void refreshWorkOrder(Input[] inputs) {
        String workOrderId = inputs[0].workOrderId;
        refreshWorkOrders(new String[]{ workOrderId });
    }
    
    public static final String 
        COMPANY = 'Company', 
        DESCRIPTION = 'Description', 
        NAME = 'Name', 
        SUBJECT = 'Subject', 
        FIRST_NAME = 'FirstName', 
        LAST_NAME = 'LastName';
    
        
    public static Set<String> defaultFieldIgnores = new Set<String>{
        'RecordTypeId', 'IndividualId', 'ReportsToId', 'DandbCompanyId', 'BillingGeocodeAccuracy', 'BillingLatitude',
        'BillingLongitude', 'ShippingGeocodeAccuracy','ShippingLatitude', 'ShippingLongitude', 'OtherGeocodeAccuracy',
        'OtherLatitude', 'OtherLongitude', 'OwnerId', 'MailingGeocodeAccuracy', 'MailingLatitude', 'MailingLongitude','CleanStatus',
        'OperatingHoursId', 'ParentId', 'hed__Current_Address__c', 'hed__Primary_Household__c', 'hed__Primary_Language__c',
        'hed__Primary_Organization__c', 'EmailBouncedDate', 'Territory2Id', 'EmailBouncedReason', 'GeocodeAccuracy', 'Latitude', 'Longitude'
    };
        
    public static Set<String> defaultTypeIgnores = new Set<String>{
        DD_Util.DISPLAY_TYPE_BOOLEAN, 
        DD_Util.DISPLAY_TYPE_STRING, 
        DD_Util.DISPLAY_TYPE_TEXTAREA, 
        DD_Util.DISPLAY_TYPE_PHONE, 
        DD_Util.DISPLAY_TYPE_EMAIL, 
        DD_Util.DISPLAY_TYPE_URL, 
        DD_Util.DISPLAY_TYPE_ENCRYPTEDSTRING
    }; 
       
    public static void refreshWorkOrders(String[] workOrderIds){   
        DD_Work_Order__c[] workOrders = DD_Util.getWorkOrders(workOrderIds);
        
        for (DD_Work_Order__c workOrder : workOrders){
    
       		JSONGenerator 
                requiredMergeValues = JSON.createGenerator(true),
                randomValueRanges = JSON.createGenerator(true),
                randomReferenceQueries = JSON.createGenerator(true),
                randomPicklistValues = JSON.createGenerator(true),
                qaInputOutput = JSON.createGenerator(true);
            
            requiredMergeValues.writeStartObject();
            randomValueRanges.writeStartObject();
            randomReferenceQueries.writeStartObject();
            randomPicklistValues.writeStartObject();
            
            qaInputOutput.writeStartObject();
            qaInputOutput.writeFieldName(DD_Util.INPUT_RECORD_PREFIX + workOrder.Object_Type__c);
            qaInputOutput.writeStartObject();
            
            Map<String, Schema.SObjectField> fieldMap = DD_Util.getFieldMap(workOrder.Object_Type__c); 
            List<String> fieldSet = new List<String>(fieldMap.keySet());
            fieldSet.sort();
            
            for (String fieldName : fieldSet){
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                String properCaseName = fieldDescribe.getName();
                
                if (fieldDescribe.isUpdateable() && !defaultFieldIgnores.contains(properCaseName)){
                    String dataType = fieldDescribe.getType().name();
					Boolean 
                        isPicklist = 
                        	dataType == DD_Util.DISPLAY_TYPE_PICKLIST 
                        	|| dataType == DD_Util.DISPLAY_TYPE_MULTIPICKLIST,
                        
                        isString = 
                        	dataType == DD_Util.DISPLAY_TYPE_REFERENCE 
                       	 	|| dataType == DD_Util.DISPLAY_TYPE_PICKLIST 
                        	|| dataType == DD_Util.DISPLAY_TYPE_MULTIPICKLIST, 
                        
                        isNumber = 
                        	dataType == DD_Util.DISPLAY_TYPE_PERCENT
                            || dataType == DD_Util.DISPLAY_TYPE_INTEGER
                            || dataType == DD_Util.DISPLAY_TYPE_DOUBLE
                            || dataType == DD_Util.DISPLAY_TYPE_CURRENCY;
                     
                    String defaultValue;
                    if (fieldName == NAME || fieldName == COMPANY) { 
                        defaultValue = 'DataDesk';
                    } else if (fieldName == FIRST_NAME) {
                        defaultValue = 'Data';
                    }  else if (fieldName == LAST_NAME) {
                        defaultValue = 'Desk';
                    } else if (fieldName == DESCRIPTION) { 
                        defaultValue = 'Description';
                    } else if (fieldName == SUBJECT) {
                        defaultValue = 'DataDesk Rocks Too Hard, Plz Help';
                    }
                    
                    if (!fieldDescribe.isNillable()){
                        if (dataType == DD_Util.DISPLAY_TYPE_DATE){
                            defaultValue = DateTime.now().format('yyyy-MM-dd');
                        } if (dataType == DD_Util.DISPLAY_TYPE_DATETIME){
                            defaultValue = DateTime.now().format('yyyy-MM-dd hh:mm:ss');
                        } else if (isNumber){
                            defaultValue = '100';
                        } else if (isString) {
                            defaultValue = 'DataDesk';
                        }
                        
                        if (defaultValue != null){
                            requiredMergeValues.writeStringField(properCaseName, defaultValue);
                            qaInputOutput.writeStringField(properCaseName, defaultValue);
                        }               
                    } else {
                        if (!defaultTypeIgnores.contains(dataType)){
                            if (dataType == DD_Util.DISPLAY_TYPE_DATE){
                                randomValueRanges.writeStringField(properCaseName, DateTime.now().format('yyyy-MM-dd') + '|' + DateTime.now().format('yyyy-MM-dd'));
                            } if (dataType == DD_Util.DISPLAY_TYPE_DATETIME){
                                randomValueRanges.writeStringField(properCaseName, DateTime.now().format('yyyy-MM-dd hh:mm:ss') + '|' + DateTime.now().format('yyyy-MM-dd hh:mm:ss'));
                            } else if (isNumber){
                                randomValueRanges.writeStringField(properCaseName, '0|100');
                            } else if (dataType == DD_Util.DISPLAY_TYPE_REFERENCE){
                                
                                String referencedObjectName = 
                                    fieldDescribe
                                    .getReferenceTo()[0]
                                    .getDescribe()
                                    .getName();
                                
                                if (referencedObjectName == 'User'){
                                    randomReferenceQueries.writeObjectField(properCaseName, new Map<String, String>{
                                        DD_Util.QUERY_PROFILE_NAME_LIKE => '',
                                        DD_Util.QUERY_CRITERIA => 'UserName != null AND isActive = true',
                                        DD_Util.QUERY_ORDER_BY => 'CreatedDate DESC',
                                        DD_Util.QUERY_RECORD_LIMIT => '1000'
                                    });
                                } else {
                                    randomReferenceQueries.writeObjectField(properCaseName, new Map<String, String>{
                                        DD_Util.QUERY_RECORD_TYPE_NAME => '',
                                        DD_Util.QUERY_CRITERIA => '(NOT Name IN (\'Example Value\'))',
                                        DD_Util.QUERY_ORDER_BY => 'CreatedDate DESC',
                                        DD_Util.QUERY_RECORD_LIMIT => '1000'
                                    });
                                }
                            } else if (isPicklist) {
                                randomPicklistValues.writeStringField(
                                    properCaseName, String.join(DD_Util.getActivePicklistValues(fieldDescribe), '|')
                                );
                            }
                        }
                    }
                }
            }
            
            if (workOrder.Work_Order_Type__c == DD_Util.WORK_ORDER_TYPE_MASS_RECORD_GENERATION){
                requiredMergeValues.writeEndObject();
                workOrder.JSON_Required_Merge_Values__c = requiredMergeValues.getAsString();  
                
                randomValueRanges.writeEndObject();
                workOrder.JSON_Random_Value_Ranges__c = randomValueRanges.getAsString();            
                
                randomReferenceQueries.writeEndObject();
                workOrder.JSON_Random_Reference_Queries__c = randomReferenceQueries.getAsString();      
                
                randomPicklistValues.writeEndObject();
                workOrder.JSON_Random_Picklist_Values__c = randomPicklistValues.getAsString();
            } else if (workOrder.Work_Order_Type__c == DD_Util.WORK_ORDER_TYPE_AUTOMATED_QA) {
                qaInputOutput.writeEndObject();
                workOrder.JSON_QA_Input__c = qaInputOutput.getAsString();
                workOrder.JSON_QA_Output__c = qaInputOutput.getAsString();
            }
            
        }
        update workOrders;    
    }
 
    public static void testStuff(){
        // 'a0g8a00001ZsqwDAAR', 'a0g8a00001ZsqvoAAB', 'a0g8a00001ZsqvoAAB', 
        refreshWorkOrders(new String[]{ 'a0g8a00001Zsr1DAAR' });
    }    
}