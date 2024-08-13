public class DD_Loader {
    public static final String 
        COMPANY = 'Company', 
        DESCRIPTION = 'Description', 
        NAME = 'Name', 
        SUBJECT = 'Subject', 
        FIRST_NAME = 'FirstName',
        LAST_NAME = 'LastName';
    
    public static Set<String> fieldIgnoreKeys = new Set<String>{
        'RecordTypeId', 'IndividualId', 'ReportsToId', 'DandbCompanyId', 'Geocode', 'IsCustomerPortal', 'OwnerId', 'CleanStatus',
        'OperatingHoursId', 'ParentId', 'EmailBouncedDate', 'Territory2Id', 'EmailBouncedReason', 'Latitude', 'Longitude', 'Preferred'
    };
        
    public static Set<String> defaultTypeIgnores = new Set<String>{
        DD_Help.DISPLAY_TYPE_URL, 
        DD_Help.DISPLAY_TYPE_ENCRYPTEDSTRING
    }; 
        
    public static String setAddressPicklist(String properCaseName){
        String defaultValue;
        if (properCaseName.contains('StateCode')){ 
            defaultValue = 'IL';
        } else if (properCaseName.contains('State')){ 
            defaultValue = 'Illinois';
        } else if (properCaseName.contains('CountryCode')){ 
            defaultValue = 'USA';
        } else if (properCaseName.contains('Country')){ 
            defaultValue = 'United States of America (the)';
        } 
        return defaultValue;
    }
 
    public static String setStringDefault(String properCaseName){
        String defaultValue;
        if (properCaseName.contains('Street')) {
            defaultValue = '123 Address Street';
        } else if (properCaseName.contains('City')) {
            defaultValue = 'Cityville';
        } else if (properCaseName.contains('PostalCode')) {
            defaultValue = '90210';
        }  else if (properCaseName.contains('Country')) {
            defaultValue = 'United States of America (the)';
        } else {
            defaultValue = 'DataDesk';
        }
        return defaultValue;
    }
       
    public static JSONLoad loadSchemaJsonForObject(String objectApiName){
        Schema.DescribeSObjectResult objectDescribe = DD_Help.getObjectDescribe(objectApiName);
        Map<String, Schema.SObjectField> fieldMap = DD_Help.getFieldMap(objectDescribe); 
            
        JSONLoad load = new JSONLoad();
        load.objectLabel = objectDescribe.getLabel();
        load.objectApiName = objectDescribe.getName();
        
        String sortKey;
        String[] keysToSort = new String[]{};
        Map<String, FieldDefinition> defsBySortKey = new Map<String, FieldDefinition>();
        
        for (String fieldName : fieldMap.keySet()){
            Schema.DescribeFieldResult fieldDescribe;
            try {
            	fieldDescribe = fieldMap.get(fieldName).getDescribe();
            } catch(Exception e){
                continue;
            }
            
            String properCaseName = fieldDescribe.getName();
            Boolean ignoreField = false;
            
            for (String key : fieldIgnoreKeys){
                if (properCaseName.contains(key)){
                    ignoreField = true;
                }
            }
            
            if (fieldDescribe.isUpdateable() && !fieldDescribe.isCalculated() && !ignoreField){
            
                String dataType = fieldDescribe.getType().name();
                Boolean 
                    isFirstName = properCaseName.contains('First') && properCaseName.contains('Name'),
                    isLastName = properCaseName.contains('Last') && properCaseName.contains('Name'),
                    isPicklist = dataType == DD_Help.DISPLAY_TYPE_PICKLIST || dataType == DD_Help.DISPLAY_TYPE_MULTIPICKLIST,
                    isString = dataType == DD_Help.DISPLAY_TYPE_STRING || dataType == DD_Help.DISPLAY_TYPE_TEXTAREA,
                    isNumber = dataType == DD_Help.DISPLAY_TYPE_PERCENT || dataType == DD_Help.DISPLAY_TYPE_INTEGER || dataType == DD_Help.DISPLAY_TYPE_DOUBLE || dataType == DD_Help.DISPLAY_TYPE_CURRENCY,
                    
                    isRequired = !fieldDescribe.isNillable() && dataType != DD_Help.DISPLAY_TYPE_BOOLEAN;
                
                if (!defaultTypeIgnores.contains(dataType)){
                    
					FieldDefinition fd = new FieldDefinition();
                    fd.label = fieldDescribe.getLabel();
                    fd.apiName = properCaseName;
                    fd.dataType = dataType;
                    fd.isRequired = isRequired;
                    
                    // First set default values for standard objects based on field name
                    Object defaultValue;
                    
                    if (dataType == DD_Help.DISPLAY_TYPE_REFERENCE){
                        
                        ReferenceQuery query = new ReferenceQuery();
                        query.referenceObjectName = 
                            fieldDescribe 
                            .getReferenceTo()[0]
                            .getDescribe()
                            .getName();
                        
                        query.referenceIdField = 'Id';
                        
                        if (query.referenceObjectName == 'User'){
                            
                            defaultValue = UserInfo.getUserId();
                            query.profileNameLike = 'Admin';
                            query.criteria = 'UserName != null AND isActive = true';
                                        
                        } else {
                            
                            query.recordTypeId = DD_Help.getDefaultRecordTypeId(query.referenceObjectName);
                            query.criteria = '(NOT Name IN (\'Example Value\'))';
                            
                        }
                        
                        query.orderBy = 'CreatedDate DESC';
                        query.recordLimit = '1';
						                        
                        fd.query = query;
                        
                        Boolean[] pageLayoutRequirements = new Boolean[]{
                            (objectApiName == 'Contact' && properCaseName == 'AccountId'),
                            (objectApiName == 'Lead' && properCaseName == 'Email')
                        };
                        
                        for (Boolean requirement : pageLayoutRequirements){
                            if (requirement)
                                fd.isRequired = requirement;
                        }
                    } else if (isPicklist) {
                        DD_Help.PicklistDescribe plDescribe = DD_Help.getPicklistDescribe(fieldDescribe);
                        fd.picklistValues.addAll(plDescribe.valueMapList);
                        defaultValue = setAddressPicklist(properCaseName);
                        defaultValue = String.isBlank(plDescribe.defaultValue) ? defaultValue : plDescribe.defaultValue;
                        
                    } else if (dataType == DD_Help.DISPLAY_TYPE_DATE) {
                        defaultValue =  Date.today();
                    } else if (dataType == DD_Help.DISPLAY_TYPE_DATETIME) {
                        defaultValue = DateTime.now();
                    } else if (dataType == DD_Help.DISPLAY_TYPE_PHONE) {
                        defaultValue = '222-222-2222';
                    } else if (dataType == DD_Help.DISPLAY_TYPE_EMAIL) {
                        defaultValue = 'datadesk@datadesk.com';
                    } else if (isString) {
                        defaultValue = setStringDefault(properCaseName);
                    } else if (isNumber) {
                        defaultValue = '1';
                    }

                    if (isFirstName || isLastName) {
                        defaultValue = DD_Help.getRandomName();
                    }
                    
                    if (fieldDescribe.getDefaultValue() != null)
                        defaultValue = String.valueOf(fieldDescribe.getDefaultValue());
                    
                    if (fieldDescribe.getDefaultValueFormula() != null)
                        defaultValue = String.valueOf(fieldDescribe.getDefaultValueFormula());
                    
                    if (defaultValue != null)
                        fd.defaultValue = defaultValue;
                    
                    sortKey = fd.label + fd.apiName;
                    keysToSort.add(sortKey);
                    
                    // sort alphabetically by label
                    defsBySortKey.put(sortKey, fd); 
                }
            }
        }
		keysToSort.sort();
        for (String key : keysToSort){
            load.fields.add(defsBySortKey.get(key));
        }
        
        return load;
    }
    
    //
    // getReferenceIds
    //
    public static String[] getReferenceIds(ReferenceQuery query){
        String queryString = 'SELECT ' + query.referenceIdField + ' FROM ' + query.referenceObjectName;
        
        if (String.isNotBlank(query.recordTypeId)){
            queryString += ' WHERE RecordTypeId = \'' + query.recordTypeId + '\'';
        } else if (String.isNotBlank(query.profileNameLike)){
            queryString += ' WHERE ProfileId = \'' + DD_Help.getProfileIdByName(query.profileNameLike) + '\'';
        }
        
        if (String.isNotBlank(query.criteria)){
            if (queryString.contains('WHERE')){
                queryString += ' AND ' + query.criteria;
            } else {
                queryString += ' WHERE ' + query.criteria;
            }
        }
        
        queryString += String.isNotBlank(query.orderBy) ? ' ORDER BY ' + query.orderBy : ' ORDER BY LastModifiedDate DESC';
        queryString += String.isNotBlank(query.recordLimit) ? ' LIMIT ' + query.recordLimit : ' LIMIT 1000';
        
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
        }
        return ids;
    }
    
    public static List<FieldDefinition> loadFieldsFromTemplate(DataDesk_Template__c template){
        List<FieldDefinition> 
            fields = new List<FieldDefinition>(),
            mergedFields = new List<FieldDefinition>();
        
        try {
            JSONParse[] sectionJson = new JSONParse(template.Field_JSON__c).asList();
            for (JSONParse sectionObj : sectionJson){
            	JSONParse[] columnJson = sectionObj.get('columns').asList();                
                for (JSONParse columnObj : columnJson){
                    JSONParse[] fieldJson = columnObj.get('fields').asList();
                    for (JSONParse fieldObj : fieldJson){
                            
                        FieldDefinition fd = new FieldDefinition();
                        fd.dataType = fieldObj.get('dataType').getStringValue();
                        fd.apiName = fieldObj.get('apiName').getStringValue();
                        fd.currentValue = fieldObj.get('currentValue').getValue();
                        fd.min = fieldObj.exists('min') ? fieldObj.get('min').getStringValue() : null;
                        fd.max = fieldObj.exists('max') ? fieldObj.get('max').getStringValue() : null;
                        fd.generateValue = fieldObj.get('generateValue').getBooleanValue();
                        // fd.iterateValues = fieldObj.get('iterateValues').getBooleanValue();
                        
                        JSONParse[] values = fieldObj.exists('values') ? fieldObj.get('values').asList() : new JSONParse[]{};
                        
                        for (JSONParse value : values){
                            fd.values.add(value.get('value').getStringValue());
                        }
                        
                        if (fieldObj.exists('query.referenceIdField') && fd.generateValue){
                            ReferenceQuery query = new ReferenceQuery();
                            JSONParse queryJson = fieldObj.get('query');
                            query.referenceIdField = queryJson.get('referenceIdField').getStringValue();
                            query.referenceObjectName = queryJson.get('referenceObjectName').getStringValue();
                            query.profileNameLike = queryJson.exists('profileNameLike') ? queryJson.get('profileNameLike').getStringValue() : null;
                            query.recordTypeId = queryJson.exists('recordTypeId') ? queryJson.get('recordTypeId').getStringValue() : null;
                            query.criteria = queryJson.exists('criteria') ? queryJson.get('criteria').getStringValue() : null;
                        	query.orderBy = queryJson.exists('orderBy') ? queryJson.get('orderBy').getStringValue() : null;
                        	query.recordLimit = queryJson.exists('recordLimit') ? queryJson.get('recordLimit').getStringValue() : null;
                        	fd.values = getReferenceIds(query);
                        }
                        if (fd.generateValue && fd.dataType == DD_Help.DISPLAY_TYPE_EMAIL){
                            mergedFields.add(fd);
                        } else {
                        	fields.add(fd);
                        }
                	}
                }
            }
        } catch(Exception e){
            throw new DataDeskException('Error parsing JSON : ' + e.getMessage() + ' : ' + e.getLineNumber() + ' : ' + e.getStackTraceString());
        }
        fields.addAll(mergedFields);
        return fields;
    }
    
    // 
    // 
    // CLASSES
    // 
    // 
    public class JSONLoad {
        String objectLabel, objectApiName;
        List<FieldDefinition> fields;
        
        public JSONLoad(){
            fields = new List<FieldDefinition>();
        }
    }
    
    public class FieldDefinition {
        public List<Map<String, String>> picklistValues;
        public String[] values;
        public String label, apiName, dataType;
        public Boolean isRequired, isFormula, includesMergeData, generateValue, iterateValues;
        public Object defaultValue, currentValue;
        public String min, max;
        public ReferenceQuery query;
        public Integer scale, countPerParent;
        
        public FieldDefinition(){
            this.picklistValues = new List<Map<String, String>>();
            this.values = new List<String>();
        }
    }
    
    public class ReferenceQuery {
        public String referenceIdField, referenceObjectName, profileNameLike, recordTypeId, criteria, orderBy, recordLimit;
    }
}