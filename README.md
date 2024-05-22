# DataDesk
Beta V0.1

This app allows the user to create dummy data in bulk using recursive batch jobs that traverse a tree of objects. The object tree is established using DD Work Orders, each of which has an assigned object, record count, and parent-child relationship set through the Parent_Work_Order__c lookup, with Parent_Lookup_Field__c identifying the field on the object model that associates the two sObjects.

## Things to Note
- If the box "Required and Merge Fields Only" is checked, only the JSON for those fields will be processed, and the other values will be ignored
- Some errors won't get surfaced in the running code but can be found in the Apex Jobs menu, I'm still working on figuring out how to handle those. You'll see these surface when you get toast notifications that "0 records have been created", even though it looks like a success, and then the error is in the Apex job menu.
- Otherwise, errors should surface via Toast events, but the toast event launches seem a little unreliable, so if it's being weird, check Apex Jobs to see if anything got missed in the UI.
- When building a work order object tree, start at the bottom and test as you go along, running each work order individually before bringing in a parent. You can hardcode a parent record ID in the Required and Merge Fields JSON, or use a random value query to populate a random reference value.
- The parent lookup is populated on each generated record after the rest of the values have been set, so even if a random reference is generated for the parent lookup field, it will get overwritten by the generated parent record ID.

## Getting Started

1) Set the DataDesk permission set to the current user.

2) Navigate to the DataDesk app.

3) Navigate to the DD Work Orders tab and create a new DD Work Order for the top-level (or only) object in the tree. E.g. the Household Account when creating a dummy household of people.
  - Fields to populate
    - Object Name
    - Record Type Name / Label (not developer name)
    - The four JSON fields, described in the below components section. It is highly recommended this be refreshed when a record is created by using the screen flow found on the work order record. Otherwise, enter fields and values in JSON format in the Required and Merge Values JSON.
    - Base Quantity. If a work order does not receive a collection of parent IDs from the previous job, it will look to this field for the number of records to create.
    
4) Create work order records for each child object in the tree.
  - Fields to populate
    - If the "Random Quantity per Parent" box is checked, the generator will create a random number of records within the pipe delimited range, e.g. "0|3"
    - Otherwise, it will look to the "Quantity per Parent" field for the number of records to create per parent record Id, which sets the base record count for the job.

5) From the parent work order in the tree, look to the screen flow to get to work! The screenflow will process the current work order and all its children in the tree, but will not process the parents of the current work order.

6) Check the involved object list views and/or DD Logs for results.

7) Wallow in the satisfaction of having saved yourself an incredible amount of time and energy doing something very tedious and surprisingly involved, knowing it's only useful for a very specific purpose and it won't be useful for very long. Lol.

## Components
### App
- DataDesk

### Custom Objects
- DD_Work_Order__c
  - This represents an object to be created in a batch. The four JSON fields are used to generate values as records are created:
    - JSON_Random_Picklist_Values__c
      - Set a pipe-delimited string of values from which the generator randomly chooses a value.
    - JSON_Random_Reference_Queries__c
      - Defaults a query for record selection for reference fields
    - JSON_Random_Value_Ranges__c
      - Sets the value min / max range for random number or date fields
    - JSON_Required_Merge_Values__c
      - This populates by default the values required to save a record. These values are set after the rest have been assigned.
      - This includes a bracketed "merge" syntax that populates a value based on a keyword.
        - [[DATE]]
          - Date.today()
        - [[TIME]]
          - DateTime.now() formatted for just time - primarily for unique value purposes
        - [[RAND]]
          - Random 10-digit number, for unique value purposes
        - [[MILS]]
          - System.currentTimeMillis(), for unique value purposes
        - [[<<fieldname>>]]
          - As a beta feature, I've included the ability to look up values from other fields set on the record. After the generator runs, the merge fields are processed, so you can reference things like [[FirstName]] or [[Custom_Field__c]]. This needs refinement and can only look up fields on the current record, not related objects.
            - A similar problem is that Household Accounts created prior to creating Contacts will not share the last names of the Contacts within. Contacts will also not share the same last names. However, simple trigger automations can easily be written to align names created through the generator, choosing one record to copy the last name from, to the other members of the household. This is also a very small detail not likely relevant to real use cases.
    - The stack trace on the work order tracks the records created in the last run, but is truncated to fit the long text field.
- DD_Log__c
  - Contains the stack trace and timestamps for generated records. The stack trace is the last record created as a sample.
- DD_Work_Order_Log__c
  - Junction object to bridge work orders to logs. Each work order in a tree will be associated to 1 log.
- Platform_Toast__e
  - Toast platform event for delivering the message from Apex to the LWC.
  
### Apex Classes
- DD_DataDesk
  - Main batch class and also contains the invocable method to call in the Flow.
- DD_Refresher
  - Handles the JSON refresh process.
- DD_Generator
  - This does handles value generation and assignment. 
- DD_Util
  - Helper class for the rest. This performs the initial data load for the generator, parsing out each of the JSON fields and loading a Map<String, List<String>> of all possible values to assign to records, based on  picklist values and reference queries. Only active picklist values will be loaded.
- InvokeToast
  - Launches the platform toast event from the Flow. This could be hardcoded in the code but I wanted to allow the use of a standalone action if desired.
 
### Flows
- DataDesk_Process_Work_Order
  - This screen flow is on the work order record and kicks off the job for the current work order.
  - This will process all work orders below the current work order, but not anything above it.
      
- DataDesk_Refresh_Work_Order_JSON
  - This can be used when creating a work order to pre-load all fields on an object model, populated with default values based on field type and/or name.
  - There is no guarantee a record will be able to be created if the default parameters aren't within the validations for the field.

### Page Layouts / Flexipages
- DD Work Order and DD Log each have one custom record page that has related lists and screenflows.

### Lightning Web Components
- platformToast
  - This is on the Work Order layout and receives the Platform Toast platform events to notify the user on the status of the job. 

### Permission Set
- DataDesk
