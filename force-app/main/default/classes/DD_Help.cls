public class DD_Help {
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
        QUERY_RECORD_LIMIT = 'recordLimit';
    
    //
    // SCHEMA
    //
    // Global describe info to be referenced by all other classes
    public static final Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    
    public static sObject getNewSObject(String objectName, String recordTypeId){
        // true means set default values
        // recordTypeId can be null
        return schemaMap.get(objectName).newSObject(recordTypeId, true);
    }
    
    public static sObject getNewSObject(String objectName){
        return getNewSObject(objectName, null);
    }
    
    public static String getDefaultRecordTypeId(String objectName){
        String recTypeId = '';
        for(Schema.RecordTypeInfo rti : getObjectDescribe(objectName).getRecordTypeInfos()) {
            if(rti.isDefaultRecordTypeMapping()) {
                recTypeId = rti.getRecordTypeId();
            }
        }
        
        return recTypeId;
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
        fieldDescribe = getFieldMap(getObjectDescribe(objectName)).get(fieldName).getDescribe(); 
        return fieldDescribe;
    }
    
    public static String getDataType(String objectName, String fieldName){
        return getFieldDescribe(objectName, fieldName).getType().name();
    }
    
    
    //
    // RECORD TYPES
    //
    public static Map<String, RecordType> getRecordTypesByName(String objectName) {
        Map<String, RecordType> recordTypesByName = new Map<String, RecordType>();
        RecordType[] recordTypes = [SELECT Id, DeveloperName, Name FROM RecordType 
                                    WHERE SobjectType = :objectName];
        
        for (RecordType recType : recordTypes){
            recordTypesByName.put(recType.Name, recType);
        }
        
        return recordTypesByName;
    }
    
    //
    // PROFILE ID
    //
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
    
    //
    // TEMPLATES
    //
    public static DataDesk_Template__c getTemplateById(String templateId){
        return getTemplates(new Id[]{ templateId })[0];
    }    
    
    public static DataDesk_Template__c getLastModifiedTemplate(){
        DataDesk_Template__c template;
        Id[] ids;
        try {
            ids = new List<Id>(new Map<Id, DataDesk_Template__c>([SELECT Id FROM DataDesk_Template__c ORDER BY LastModifiedDate DESC LIMIT 1]).keySet());
            template = getTemplates(ids)[0];
        } catch(Exception e){
        }
        return template;
    }
    
    public static DataDesk_Template__c[] getTemplates(){
        return getTemplates(
            new List<Id>(
            	new Map<Id, DataDesk_Template__c>([SELECT Id FROM DataDesk_Template__c]).keySet()
            ));
    }
    
    public static DataDesk_Template__c[] getTemplates(Id[] ids){
        return [SELECT Id, Name, 
                	Description__c, 
                    Object_API_Name__c,
                    Record_Type_API_Name__c, 
                    Record_Type_ID__c,
                	Record_Count__c, 
                    Field_JSON__c, 
               		LastModifiedById 
                FROM DataDesk_Template__c WHERE Id IN :ids
                ORDER BY LastModifiedDate DESC];
    }
    //
    // Random
    //
    public static String getRandomName() {
        // generate random index between 0 and the number of celebrity names - 1
        return getValueAtRandomIndex(names);
    }
    
    public static String getRandomComment() {
        // generate random index between 0 and the number of celebrity names - 1
        return getValueAtRandomIndex(comments);
    }
    
    public static String getValueAtRandomIndex(String[] stringList){
        if (!stringList?.isEmpty()){
        	return stringList[getRandomIndex(stringList)];
        } else {
            return '';
        }
    }
    
    public static Integer getRandomIndex(Object[] oList){
        Integer returnVal;
        try {
            returnVal = (Integer)getRandomDecimal(0, oList.size() - 1, 0);
        } catch(Exception e){
            throw new DataDeskException('Error calculating random index : getRandomIndex : ' + oList);
        }
        return returnVal;
    }
    
    public static Integer getRandomInteger(Integer min, Integer max) {
        return Integer.valueOf(getRandomDecimal((Long)min, (Long)max, 0));
    }

    public static Long getRandomLong(Long min, Long max) {
        return (Long)getRandomDecimal(min, max, 0);
    }
    
    public static Decimal getRandomDecimal(Integer min, Integer max, Integer scale) {
        return getRandomDecimal((Long)min, (Long)max, scale);
    }
    
    public static Decimal getRandomDecimal(Decimal min, Decimal max, Integer scale) {
        return getRandomDecimal(min, max, scale);
    }
    
    public static Decimal getRandomDecimal(Long min, Long max, Integer scale) {
        Decimal multiplier = max - min;
        Decimal randomNumber = (Math.random() * multiplier) + min;
        
        if (scale != null){
        	return randomNumber.setScale(scale);
        } else {
        	return Math.round(randomNumber);
        }
    }
    
    public static Date getRandomDate(String minDate, String maxDate){
        Date startDate, endDate;
        Integer daysBetween, addDays;
        try {
            startDate = Date.valueOf(minDate);
            endDate = Date.valueOf(maxDate);     
            daysBetween = startDate.daysBetween(endDate);
            addDays = startDate == endDate ? 0 : Math.round(Math.random() * daysBetween);
            return startDate.addDays(addDays);
        } catch(Exception e){
            throw new DataDeskException('Error parsing date parameters : ' + minDate + ' : ' + maxDate, e);
        }
    }
    
    public static DateTime getRandomDateTime(String minDate, String maxDate){
        Date randomDate = getRandomDate(minDate, maxDate);
        DateTime randomDateTime = 
            DateTime.newInstance(
                randomDate.year(), randomDate.month(), randomDate.day(), 
                Math.round(Math.random() * 12), Math.round(Math.random() * 60), 0
            );
        
        return randomDateTime;
    }
    public static String getPicklistValueJson(String objectApiName, String fieldApiName){
        String str;
        try {
            str = JSON.serialize(new Map<String, List<Map<String, String>>>{ 'picklistValues' => DD_Help.getPicklistDescribe(DD_Help.getFieldDescribe(objectApiName, fieldApiName)).valueMapList });
        } catch(Exception e){
        	throw new DataDeskException('Error getting picklist values : ' + e.getMessage());
        }
        return str;
    }
    
    //
    // PICKLIST
    //
    public static PicklistDescribe getPicklistDescribe(Schema.DescribeFieldResult fieldDescribe){
        List<Map<String, String>> valueMapList = new List<Map<String, String>>();
        String[] values = new String[]{};
        String defaultValue;
        
        List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
        
        if (fieldDescribe.isNillable()){
            valueMapList.add(new Map<String, String>{ 
                'label' => '(blank)',
                'value' => ''
            });
        }
        
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
        
        return pld;
    }
    
    public class PicklistDescribe {
        public List<Map<String, String>> valueMapList;
        public String defaultValue;
        
        public PicklistDescribe(List<Map<String, String>> valueMapList, String defaultValue){
            this.valueMapList = valueMapList;
            this.defaultValue = defaultValue;
        } 
        
        public PicklistDescribe(){
        }
    }
    
    public static final List<String> names = new List<String>{
        'Fifty', 'Cent','Drake','Alice', 'Cooper','Angelina', 'Jolie','Angus', 'Young',
            'Axl', 'Rose','Backstreet', 'Boys','Ben', 'Affleck','Beyonce', 'Knowles','Billy', 'Joel','Bon', 'Scott',
            'Brad', 'Pitt','Brian', 'Johnson','Britney', 'Spears','Bruce', 'Springsteen','Bruce', 'Willis',
            'Bruce', 'Springsteen','Celine', 'Dion','Cristiano', 'Ronaldo','Dan', 'Brown','David', 'Bowie',
            'David', 'Beckham','Doctor', 'Dre','Dwayne', 'Johnson','Ed', 'Sheeran','Eddie', 'Vedder',
            'Ellen', 'DeGeneres','Elton', 'John','Eric', 'Clapton','Floyd', 'Mayweather Jr.',
            'Floyd', 'Mayweather','Freddie', 'Mercury','Garth', 'Brooks','Gene', 'Simmons','George', 'Lucas',
            'George', 'Clooney','Harrison', 'Ford','Howard', 'Stern','J.K.', 'Rowling',
            'James', 'Cameron','James', 'Patterson','Janis', 'Joplin','Jay', 'Z','Jennifer', 'Aniston','Jennifer', 'Lopez',
            'Jerry', 'Seinfeld','Jim', 'Morrison','Jimi', 'Hendrix','Joan', 'Jett','John', 'Lennon','Johnny', 'Depp',
            'Jon', 'Bon Jovi','Judge', 'Judy Sheindlin','Julia', 'Roberts','Justin', 'Bieber','Kanye', 'West',
            'Katy', 'Perry','Kevin', 'Hart','Kim', 'Kardashian','Kobe', 'Bryant','Kurt', 'Cobain','Kylie', 'Jenner',
            'Lady', 'Gaga','LeBron', 'James','Lemmy', 'Kilmister','Leonardo', 'DiCaprio','Lionel', 'Messi','Manny', 'Pacquiao',
            'Mariah', 'Carey','Mel', 'Gibson','Michael', 'Jordan','Mick', 'Jagger','Oprah', 'Winfrey','Ozzy', 'Osbourne',
            'Paul', 'McCartney','Paul', 'McCartney','Paula', 'Deen','Phil', 'McGraw','Robert', 'Plant','Robert', 'Downey Jr.',
            'Robin', 'Williams','Roger', 'Daltrey','Roger', 'Federer','Ronnie', 'James Dio','Rush', 'Limbaugh','Sandra', 'Bullock',
            'Saul', 'Canelo Alvarez','Sean', 'Diddy Combs','Shaquille', 'O\'Neal','Simon', 'Cowell','Spice', 'Girls','Steven', 'Tyler',
            'Steven', 'Spielberg','Taylor', 'Swift','The', 'Weeknd','Tiger', 'Woods','Tom', 'Petty','Tom', 'Hanks','Tom', 'Cruise',
            'Tyler', 'Perry', 'Eminem', 'Cher', 'Bono', 'Rihanna', 'Adele','Jimmers', 'Dudeman','Ronald', 'Washington',
            'Chip', 'Digster','Saucy', 'Thompson','Theresa', 'Recording','Marcus', 'Unread','Stella', 'Artois','Alexander', 'The Great'
     };
         
    public static final List<String> comments = new List<String>{
        'I need a vacation', 'I\'m getting too old for this', 'Where did I put my keys?', 
            'Make sure you absolutely never, under any circumstances', 'The suspense is killing me', 
            'The silence is deafening', 'I need a drink', 'Please don\'t break', 'If you need me, I\'ll be in the woods',
            'Oy vey!', 'Dios mio', 'Uh oh', 'Yowza', 'Cowabunga', 'Surf\'s up', 'Here we go', 'WHOA', 'Saddle up', 'Buckle up',
            'Oh gawd', '*Runs away*', 'Take cover!!', 'Nobody cares', 'Oh, the humanity!', 'I live for the drama',
            'YOLO', 'Time for lunch', '10/10 will do again', 'Baby Einstein Approved', 'I\'m going to regret this',
            'Welp, it\'s over', 'Let\'s try and be professional, here', 'Please try to contain your excitement', 
            '*Holds breath*', 'HOLD', 'Brace yourself', 'Check yourself before you wreck yourself', 'Don\'t start none, won\'t be none',
            'The cat\'s out of the bag!', 'My dad could beat up your dad', 'I\'m so cold', 'Ok let\'s all just try and chill out', 'EVERYONE REMAIN CALM'
     };    
         
    public static final List<String> titles = new List<String>{
        'Doctor', 'Professor', 'The Man with the Plan', 'Vice President', 
        'The Amazing', 'The Mysterious', 'The Great', 'The Real'
     };         
    
}