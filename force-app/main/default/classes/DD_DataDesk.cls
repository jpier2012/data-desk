global class DD_DataDesk implements Database.batchable<sObject>, Database.Stateful{
    public class Input {
        @InvocableVariable(label='Work Order Record Id')
        public String workOrderId;
    }
  
    @InvocableMethod(label='Process DataDesk Work Order') 
    public static void processWorkOrder(List<Input> inputs){
        if (inputs.size() == 0 || inputs[0].workOrderId == null)
        	throw new DataDeskException('No Work Order ID provided.'); 
        
        Database.executeBatch(new DD_DataDesk(inputs[0].workOrderId, null, null)); 
    }
    public String[] 
        recordIds = new String[]{},
        parentRecordIds = new String[]{};
            
    public Map<String, List<String>> 
            randomValuesByField = new Map<String, List<String>>(),
            mergeValuesByField = new Map<String, List<String>>();
            
    public Long startMillis, stopMillis;
    public Integer parentRecordIndex = 0, totalRecords = 0;
    
    public String recordTypeId, logId, stackTrace = '';
    public Map<String, String> errors = new Map<String, String>(), traceMap = new Map<String, String>();
    public DD_Work_Order__c workOrder;
    
    //
	// Constructor   
    //
    public DD_DataDesk(String workOrderId, String existingLogId, String[] parentRecordIds){ 
        this.startMillis = System.currentTimeMillis();
        workOrder = DD_Util.getWorkOrder(workOrderId);
        
        if (workOrder == null)
            throw new DataDeskException('No Work Order record found.');
        
        if (parentRecordIds != null)
        	this.parentRecordIds = parentRecordIds; 
        
        String recordTypeId = [SELECT Id, DeveloperName, Name FROM RecordType 
                               WHERE SobjectType = :workOrder.Object_Name__c
                               AND Name = :workOrder.Record_Type_Name__c
                               LIMIT 1]?.Id;
        
        DD_Log__c log = getLog(existingLogId);
        
        if (log == null){
        	log = new DD_Log__c();
        	log.Start_Timestamp__c = DateTime.newInstance(this.startMillis);
        	log.Status__c = 'Processing';
            insert log;
        }
        
        this.logId = log.Id;

        DD_Work_Order_Log__c workOrderLog = new DD_Work_Order_Log__c();
        workOrderLog.Work_Order__c = workOrder.Id;
        workOrderLog.Log__c = log.Id;
        insert workOrderLog;
    }
    //
	// Start   
    //
    public Iterable<sObject> start(Database.BatchableContext BC){
        Integer startCount = parentRecordIds.size() > 0 ? parentRecordIds.size() : (Integer)workOrder.Base_Quantity__c;
        
        try {
            DD_Util.ValueLoad load = DD_Util.loadValues(workOrder.Id);
            randomValuesByField = load.randomValuesByField;
            mergeValuesByField = load.mergeValuesByField;
        } catch(Exception e){
            handleError('Error loading values. Check JSON : ' + e.getCause() + ' : ' + e.getMessage());
        }
        
        try {
        	return new CustomIterable(startCount, workOrder.Object_Name__c);
        } catch(Exception e){
            
            throw new DataDeskException('Custom Iterable issue : ' + e.getMessage());
        }
    }
    
    //
	// Execute
    //
    public void execute(Database.BatchableContext BC, List<sObject> batch) {
        
        String 
            objectName = workOrder.Object_Name__c,
            parentLookupField = workOrder.Parent_Lookup_Field__c,
            parentWorkOrderId = workOrder.Parent_Work_Order__c;
       
        sObject[] objectsToInsert = new sObject[]{};
        errors = new Map<String, String>();
        
        // starts with top-level objects
        for (sObject sObj : batch){
            Integer multiplier = workOrder.Quantity_Per_Parent__c == null ? 1 : (Integer)workOrder.Quantity_Per_Parent__c;
            
            //
            // Determine the record count multiplier, if random quantity is selected
            // 
            if (workOrder.Random_Quantity_Per_Parent__c && String.isNotBlank(workOrder.Random_Range__c)){
                String[] range;
                try {
                	range = DD_Util.split(workOrder.Random_Range__c);
                } catch(Exception e){
                    handleError('Error parsing random number range : ' + workOrder.Random_Range__c, e);
                }
                Integer min = Integer.valueOf(range[0]), max = Integer.valueOf(range[1]);
                multiplier = (Integer)DD_Generator.getRandomDecimal(min, max, null);
            }
            
            for (Integer i = 0; i < multiplier; i++){
                totalRecords++;
                
                sObject record = sObj;
                
                // if this is iteration 2+, create a new object, 
                // don't use the existing (created through the iterable)
                if (i > 0){
                    record = DD_Util.newSObject(objectName, recordTypeId);
                }    
                
                //
                // Randomizer fields
                //
                if (!workOrder.Required_and_Merge_Fields_Only__c){
                    for (String fieldName : randomValuesByField.keySet()){ 
    
                        Schema.DescribeFieldResult fieldDescribe = DD_Util.getFieldDescribe(objectName, fieldName);
                        
                        Object value;
                        try {
                            value = DD_Generator.getValue(fieldDescribe, randomValuesByField.get(fieldName), null);
                            record.put(fieldName, value);
                        } catch(Exception e){
                            handleError('Error setting random field value : ' + fieldName, e);
                        }
                        
                        trace(fieldName, '' + record.get(fieldName));
                    }
                    // add spaces to separate out override fields
                    stackTrace += '\n';
                    //
                    // Set defaults and required fields
                    if (objectName == 'Lead' || objectName == 'Contact'){
                        String[] names = DD_Generator.getRandomName();
                        record.put('FirstName', names[0]);
                        record.put('LastName', names[1]);
                        trace('FirstName', names[0]);
                        trace('LastName', names[1]);
                    }
                }
                
                //
                // merge fields
                //
                for (String fieldName : mergeValuesByField.keySet()){ 
                    
                    Schema.DescribeFieldResult fieldDescribe = DD_Util.getFieldDescribe(objectName, fieldName);
                    Object value, mergedValue = DD_Generator.getMergedValue(record, mergeValuesByField.get(fieldName)[0]);
                    
                    try {
                        value = DD_Generator.getValue(fieldDescribe, randomValuesByField.get(fieldName), mergedValue);
                        record.put(fieldName, value);
                    } catch(Exception e){
                        handleError('Error setting merge field value : ' + fieldName + ' : ' + value, e);
                    }
                    
                    trace(fieldName, '' + record.get(fieldName));
                }
                // add spaces to separate out override fields
                stackTrace += '\n';
                
                //
                // Populate references to parent object, overwrite random references
                // 
                if (String.isNotBlank(parentLookupField) && !parentRecordIds?.isEmpty()){
                    record.put(parentLookupField, parentRecordIds[parentRecordIndex]);
                    trace(parentLookupField, parentRecordIds[parentRecordIndex]);
                }
                
                objectsToInsert.add(record);
                
            	stackTrace += '\n\n';
            }
            
            parentRecordIndex++;
        }
        Database.SaveResult[] results;
        try {
        	results = Database.insert(objectsToInsert);
        } catch(Exception e){
            handleError('Error with Database.insert call', e);
        } 
        
        if (results != null){
            for (Database.SaveResult sr : results){
                if (sr.isSuccess()) {
                    recordIds.add(sr.getId());
                } else {
                    handleError('Record insert error(s) : ' + String.join(sr.getErrors(), ','));
                }
            }
        }
    }
    
    //
	// End   
    //
    public void finish(Database.BatchableContext BC) {
        workOrder.Stack_Trace__c = stackTrace.left(130000);
        workOrder.Total_Records_Created__c = totalRecords;
        update workOrder;
        
        DD_Work_Order__c[] children = [SELECT Id FROM DD_Work_Order__c 
                                       WHERE Parent_Work_Order__c = :workOrder.Id];
        
        // Select the work orders that have the same parent workorder,
        // That are NOT the existing work order
        // and see if they have children
        DD_Work_Order__c[] siblingsChildren = [SELECT Id FROM DD_Work_Order__c 
                                               WHERE Parent_Work_Order__r.Parent_Work_Order__c = :workOrder.Parent_Work_Order__c
                                               AND Parent_Work_Order__r.Parent_Work_Order__c != null 
                                               AND Parent_Work_Order__c != :workOrder.Id];
        
                
        String recordTypeString = String.isBlank(workOrder.Record_Type_Name__c) ? '' : workOrder.Record_Type_Name__c + ' ';
        
        DD_Log__c log = getLog(logId);
        
        if (log == null){
            throw new DataDeskException('Log is null : logId : ' + logId);
        }
        
        String errorString = '';
        if (!errors.isEmpty()) {   
            stopMillis = System.currentTimeMillis();
            log.Stop_Timestamp__c = DateTime.newInstance(stopMillis);
            log.Status__c = 'Failed';
            log.Time_Elapsed_s__c = (((Decimal)stopMillis - (Decimal)startMillis) / (Decimal)1000).setScale(3);
            
            for (String error : errors.keySet()){
                errorString += error + '\n:\n' + errors.get(error);
            }
            
            if (log.Errors__c == 'null' || log.Errors__c == null){
                log.Errors__c = '';
            }
            
            log.Errors__c = (log.Errors__c + '\n\n' + errorString).left(130000);
            update log;
            
            InvokeToast.launch('error',
                               'sticky', 
                               workOrder.Name + ' Batch Job Failed!', 
                               'Total errors : ' + errors.keySet().size() + ' : ' + new List<String>(errors.keySet()));
        } else {
            String sampleRecord = '';
            
            for (String fieldName : traceMap.keySet()){
                sampleRecord += '-> ' + fieldName + ' : ' + traceMap.get(fieldName) + '\n';
            }
            
            if (log.Stack_Trace__c == 'null' || log.Stack_Trace__c == null){
                log.Stack_Trace__c = '';
            }
            
            log.Stack_Trace__c = (log.Stack_Trace__c + '\n\n' + 
                workOrder.Object_Name__c + ' : '+  totalRecords + ' records created.\n\n' +
                'Sample :\n' + sampleRecord + '\n').left(130000);
            
            if (!children.isEmpty()){
                update log;
                for (DD_Work_Order__c child : children){
                    Database.executeBatch(new DD_DataDesk(child.Id, log.Id, recordIds));
                }
            } else if (siblingsChildren.isEmpty()){
                stopMillis = System.currentTimeMillis();
                log.Stop_Timestamp__c = DateTime.newInstance(stopMillis);
                log.Status__c = 'Complete';
                log.Time_Elapsed_s__c = (((Decimal)stopMillis - (Decimal)startMillis) / (Decimal)1000).setScale(3);
            }
            update log;
            InvokeToast.launch('success', 
                              'dismissible', 
                               workOrder.Name + ' Batch Job Complete!', 
                               recordTypeString + workOrder.Object_Name__c + ' : ' + totalRecords + ' records created.');
        }
    }
    
    //
	// Iterable   
    //
    public class CustomIterable implements Iterable<sObject>{ 
        Integer quantity;
        String objectName, recordTypeId;
        
        public CustomIterable(Decimal quantity, String objectName){
            this.quantity = (Integer)quantity;
            this.objectName = objectName;
            this.recordTypeId = recordTypeId;
        }
        
        public Iterator<sObject> Iterator(){
            return new CustomIterator(quantity, objectName, recordTypeId);
        }
    }
    
    public class CustomIterator implements Iterator<sObject>{
        public sObject[] recordsToCreate = new sObject[]{}; 
        Integer index = -1;
        
        public CustomIterator(Integer quantity, String objectName, String recordTypeId){
            for (Integer i = 0; i < quantity; i++){
                recordsToCreate.add(DD_Util.newSObject(objectName, recordTypeId));
            }
        }
        
        public Boolean hasNext(){
            if (index >= (recordsToCreate.size() - 1)){
                return false;
            } else {
                return true;
            }
        }    
        
        public sObject next(){
            return recordsToCreate[++index];
        } 
    }
    
    //
	// Util   
    //
    public void trace(String fieldName, String value){
        stackTrace = (stackTrace + '*** ' + fieldName + ' : ' + value + '\n').left(130000);
        traceMap.put(fieldName, value);
    }
    
    public DD_Log__c getLog(String logId){
        DD_Log__c[] logs = [SELECT Id, Stack_Trace__c, Start_Timestamp__c, Stop_Timestamp__c, Errors__c FROM DD_Log__c WHERE Id = :logId];
        
        if (logs.isEmpty()){
            return null;
        } else {
            return logs[0];
        }
    }
    
    private void handleError(String message, Exception e){
        errors.put(workOrder.Object_Name__c + ' : ' + message + ' : ' + e.getMessage(),
                   e.getCause() + ' : ' + e.getLineNumber() + ' : ' + e.getStackTraceString());
    }
    
    private void handleError(String message){
        errors.put(workOrder.Object_Name__c + ' : ' + message,'');
    }
    
}