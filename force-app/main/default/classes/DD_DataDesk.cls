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
    
    public String[] parentRecordIds, queuedWorkOrderIds;
    public Map<String, List<String>> recordIdsByWorkOrderId, childWorkOrdersByParentId; 
    
    public Long startMillis, stopMillis;
    public Integer parentRecordIndex = 0, totalRecords = 0;
    
    public Map<String, String> errors = new Map<String, String>(), traceMap = new Map<String, String>();
    public DD_Work_Order__c workOrder;
    public DD_Util.DDValueLoad load;
    public DD_Log__c parentLog, workOrderLog;
    
    sObject[] objectsToProcess = new sObject[]{};
        
    //
	// Constructor   
    //
    public DD_DataDesk(String workOrderId, DD_Log__c parentLog, Map<String, List<String>> recordIdsByWorkOrderId){ 
        // Queue work order records
        // Take all those in the collection without parents, add to the beginning of the list
        // Find all junction objects, add to the end of the list
        // Find children of junction objects and parents
        
        this.startMillis = System.currentTimeMillis();
        workOrder = DD_Util.getWorkOrder(workOrderId);
        
        if (workOrder == null)
            throw new DataDeskException('No Work Order record found.');
        
        if (recordIdsByWorkOrderId != null){
        	this.recordIdsByWorkOrderId = recordIdsByWorkOrderId; 
        	parentRecordIds = recordIdsByWorkOrderId.get(workOrder.Parent_Work_Order__c);
            
            String parentIdField = workOrder.Parent_ID_Field__c;
            
            if (String.isNotBlank(parentIdField) && parentIdField != 'Id'){
                try {
                    
                    sObject[] records = Database.query(
                        'SELECT ' + parentIdField + 
                        ' FROM ' + workOrder.Object_API_Name__c + 
                        ' WHERE Id IN ' + String.join(parentRecordIds, ', ')
                    );
                    
                    String[] temp = new String[]{};
                        
                    for (sObject record : records){
                        temp.add('' + record.get(parentIdField));
                    }
                    
                    parentRecordIds = temp;
                } catch(Exception e){
            		handleError('Error querying parent records for custom ID field.', e);
                }
            }
        } else {
            parentRecordIds = new String[]{};
        }
        
        this.recordIdsByWorkOrderId = new Map<String, List<String>>{
        	workOrder.Id => new List<String>()
        };
        
        if (parentLog == null){
            DateTime startTime = DateTime.newInstance(this.startMillis);
        	parentLog = new DD_Log__c(Name = (workOrder.Collection_Name__c + ' ' + startTime.format('MM-dd hh:mm:ss')).left(80), 
                                      Status__c = 'Processing',
                                      Start_Timestamp__c = startTime,
                                      Is_Parent_Log__c = true,
                             		  DD_Work_Order__c = workOrder.Id, 
                                      Records_Generated__c = 0);
            insert parentLog;
        }
        
        this.parentLog = parentLog;
        
        try {
        	this.load = DD_Util.loadGeneratorValues(workOrder.Id);
        } catch(Exception e){
            handleError('Error loading values. Check JSON.', e);
        }
        
        Map<String, RecordType> recordTypes = DD_Util.getRecordTypes(workOrder.Object_API_Name__c);
        
        for (String recTypeName : recordTypes.keySet()){
            RecordType recType = recordTypes.get(recTypeName);
            
            if (recType.DeveloperName == workOrder.Record_Type_API_Name__c){
                this.load.recordType = recType;
                trace('RecordType.Name', recType.DeveloperName);
            }
        }

        if (String.isNotBlank(workOrder.Record_Type_API_Name__c) && this.load.recordType == null){
            InvokeToast.launch('error', 
                               'sticky', 
                               'Record Type Not Found', 
                               'Available record types : ' + new List<String>(recordTypes.keySet()));
            
            throw new DataDeskException('No record type found : ' + workOrder.Record_Type_API_Name__c);
        }
    }
    //
	// Start   
    //
    public Iterable<sObject> start(Database.BatchableContext BC){

        InvokeToast.launch('warning', 
                           'dismissible', 
                           workOrder.Name + ' Batch Job Started!', 
                           DD_Generator.getRandomComment());
        
        Integer startCount = parentRecordIds?.size() > 0 ? parentRecordIds.size() : (Integer)workOrder.Base_Quantity__c;
        
        try {
            return new CustomIterable(startCount, workOrder.Object_API_Name__c, load.recordType?.Id);
        } catch(Exception e){
            throw new DataDeskException('Custom Iterable issue : ' + e.getMessage());
        }
    }
    
    //
	// Execute
    //
    public void execute(Database.BatchableContext BC, List<sObject> batch) {
        Database.SaveResult[] results;
       	massGenerateData(batch);
        
        try {
            results = Database.insert(objectsToProcess);
        } catch(Exception e){
            handleError('Error with Database.insert call', e);
        } 
        
        if (results != null){
            for (Database.SaveResult sr : results){
                if (sr.isSuccess()) {
                    recordIdsByWorkOrderId.get(workOrder.Id).add(sr.getId());
                } else {
                    handleError('Database processing error(s) : ' + String.join(sr.getErrors(), ','));
                }
            }
        }
    }
    
    //
	// End   
    //
    public void finish(Database.BatchableContext BC) {
       AsyncApexJob job = [SELECT Id, Status, ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                           FROM AsyncApexJob 
                           WHERE Id = :BC.getJobId()];
        
        stopMillis = System.currentTimeMillis();
        workOrderLog = newChildLog();
        
        String 
            traceString = '', errorString = '', firstError = '', 
            jobError = job.ExtendedStatus,
            toastStyle, toastMode, toastTitle, toastMessage;
        
        Integer errorCount = job.NumberOfErrors > 0 ? job.NumberOfErrors : errors.keySet().size();
        
        if (errorCount > 0) {   
            workOrderLog.Status__c = DD_Util.JOB_STATUS_FAILED;
            
            if (job.ExtendedStatus != null){
                firstError = job.ExtendedStatus;
            } else {
                firstError = new List<String>(errors.keySet())[0];
            }
            
            for (String error : errors.keySet()){
                errorString += error + ' :\n' + errors.get(error) + '\n\n';
            }
                
            toastStyle = 'error';
            toastMode = 'sticky';
            toastTitle = workOrder.Name + ' Batch Job Failed!';
            toastMessage = 'Errors : ' + errorCount + ' : First : ' + firstError;
            
        } else {
            workOrderLog.Status__c = DD_Util.JOB_STATUS_COMPLETED;            
            String recordTypeString = String.isBlank(workOrder.Record_Type_API_Name__c) ? '' : workOrder.Record_Type_API_Name__c + ' ';
            
            toastStyle = 'success';
            toastMode = 'dismissible';
            toastTitle = workOrder.Name + ' Batch Job Complete!';
            toastMessage = recordTypeString + workOrder.Object_API_Name__c + ' : ' + totalRecords + ' records created.';
        }
        
        traceString += 'Sample :\n';
        
        for (String fieldName : traceMap.keySet()){
            traceString += '-> ' + fieldName + ' : ' + traceMap.get(fieldName) + '\n';
        }

        workOrderLog.Stack_Trace__c = traceString.left(130000);
        workOrderLog.Errors__c = errorString.left(130000);
        workOrderLog.Stop_Timestamp__c = DateTime.newInstance(stopMillis);
        workOrderLog.Time_Elapsed_s__c = (((Decimal)stopMillis - (Decimal)startMillis) / (Decimal)1000).setScale(3);
        workOrderLog.Records_Generated__c = totalRecords;
        insert workOrderlog;

        InvokeToast.launchWithUrl(toastStyle, toastMode, toastTitle, toastMessage, workOrderLog.Id);
        
        DD_Work_Order__c[] children = [SELECT Id FROM DD_Work_Order__c 
                                       WHERE Parent_Work_Order__c = :workOrder.Id];
        if (!children.isEmpty()){
            for (DD_Work_Order__c child : children){
                
                if (recordIdsByWorkOrderId.get(child.Id) == null){
                    Database.executeBatch(
                        new DD_DataDesk(
                            child.Id, 
                            parentLog, 
                            recordIdsByWorkOrderId
                        )
                    );
                }
            }
        } else {
            parentLog.Stop_Timestamp__c = DateTime.newInstance(stopMillis);
            parentLog.Time_Elapsed_s__c = (((Decimal)stopMillis - (Decimal)startMillis) / (Decimal)1000).setScale(3);
            parentLog.Status__c = DD_Util.JOB_STATUS_COMPLETED;
            
            String errors = '';
            Integer totalRecordCount = 0;
            DD_Log__c[] childLogs = [SELECT Id, Records_Generated__c, Errors__c, Status__c, DD_Work_Order__r.Name 
                                     FROM DD_Log__c WHERE Parent_Log__c = :parentLog.Id];
            
            for (DD_Log__c log : childLogs){
                errors += log.DD_Work_Order__r.Name + ' : ' + log.Errors__c + '\n\n';
                totalRecordCount += (Integer)log.Records_Generated__c;
                if (log.Status__c == DD_Util.JOB_STATUS_FAILED)
                    parentLog.Status__c = DD_Util.JOB_STATUS_FAILED;
                
            }
            parentLog.Errors__c = errors;
            parentLog.Records_Generated__c = totalRecordCount;
            
            update parentLog;
        }
    }
   
    //
    // Mass Generate
    //
    public void massGenerateData(List<sObject> batch){
        String 
            objectName = workOrder.Object_API_Name__c,
            parentLookupField = workOrder.Parent_Lookup_Field__c,
            parentWorkOrderId = workOrder.Parent_Work_Order__c;
       
        objectsToProcess = new sObject[]{};
        errors = new Map<String, String>();
        
        // starts with top-level objects
        for (Integer parentIndex = 0; parentIndex < batch.size(); parentIndex++){
            sObject sObj = batch[parentIndex];
            
            Integer multiplier = (workOrder?.Quantity_Per_Parent__c == null || parentRecordIds.size() == 0) ? 1 : (Integer)workOrder.Quantity_Per_Parent__c;
            
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
                    record = DD_Util.getNewSObject(objectName, load.recordType?.Id);
                }    
                
                //
                // Randomizer fields
                //
                for (String fieldName : load.randomValuesByField.keySet()){ 
                    
                    Schema.DescribeFieldResult fieldDescribe = DD_Util.getFieldDescribe(objectName, fieldName);
                    try {
                        DD_Generator.setValue(record, fieldDescribe, load.randomValuesByField.get(fieldName));
                    } catch(Exception e){
                        handleError('Error setting random field value : ' + fieldName + ' : ' + record.get(fieldName), e);
                    }
                    
                    trace(fieldName, '' + record.get(fieldName));
                }
                
                //
                // merge fields
                //
                for (String fieldName : load.discreteValuesByField.keySet()){ 
                    
                    Schema.DescribeFieldResult fieldDescribe = DD_Util.getFieldDescribe(objectName, fieldName);
                    
                    try {
                        DD_Generator.setValue(record, fieldDescribe, load.discreteValuesByField.get(fieldName));
                    } catch(Exception e){
                        handleError('Error setting discrete field value : ' + fieldName + ' : ' + record.get(fieldName), e);
                    }
                    
                    trace(fieldName, '' + record.get(fieldName));
                }
                
                //
                // Populate references to parent object, overwrite random references
                // 
                if (String.isNotBlank(parentLookupField) && !parentRecordIds?.isEmpty()){
                    record.put(parentLookupField, parentRecordIds[parentIndex]);
                    trace(parentLookupField, parentRecordIds[parentIndex]);
                }
                
                objectsToProcess.add(record);
            }
        }
    }
    
    //
	// Util   
    //
    public void trace(String fieldName, String value){
        traceMap.put(fieldName, value);
    }
    
    public DD_Log__c newChildLog(){
        DateTime startTime = DateTime.newInstance(this.startMillis);
        return new DD_Log__c(Name = (workOrder.Name + ' ' + startTime.format('MM-dd hh:mm:ss') + ' : ' + workOrder.Object_API_Name__c).left(80), 
                             Status__c = 'Processing', 
                             Start_Timestamp__c = startTime,
                             Parent_Log__c = this.parentLog.Id,
                             DD_Work_Order__c = this.workOrder.Id,
                             Records_Generated__c = 0);
    }
    
    private void handleError(String message, Exception e){
        errors.put(message + ' : ' + e.getMessage(),
                   '__Type : ' + e.getTypeName() + '\n' +
                   '__Trace : ' + e.getStackTraceString()
                  );
    }
    
    private void handleError(String message){
        errors.put(workOrder.Object_API_Name__c + ' : ' + message,'');
    }
    
    //
	// Iterable   
    //
    public class CustomIterable implements Iterable<sObject>{ 
        Integer quantity;
        String objectName, recordTypeId;
        
        public CustomIterable(Decimal quantity, String objectName, String recordTypeId){
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
                recordsToCreate.add(DD_Util.getNewSObject(objectName, recordTypeId));
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

    public static void testStuff(){
        DD_DataDesk dd = new DD_DataDesk('a0g8a00001ZstD9AAJ', null, null);
        dd.massGenerateData(new List<sObject>{ new Account() });
        // Database.executeBatch(dd); 
    }
}