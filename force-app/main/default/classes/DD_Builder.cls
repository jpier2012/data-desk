public class DD_Builder {
    public static String insertTemplate(String jsonString){
        DataDesk_Template__c template;
        String str;
        try {
        	template = parseTemplate(jsonString);
            insert template;
            str = JSON.serialize(new Map<String, Object>{ 'isSuccess' => true, 'template' => template });
        } catch (Exception e){
            str = JSON.serialize(new Map<String, Object>{ 'isSuccess' => false, 'message' => 'Error inserting template : ' + e.getMessage() });
        }
        return str;
    }
    
    public static String updateTemplate(String jsonString){
        DataDesk_Template__c template;
        String str;
        try {
        	template = parseTemplate(jsonString);
            update template;
            str = JSON.serialize(new Map<String, Object>{ 'isSuccess' => true, 'template' => template, 'Id' => template.Id });
        } catch (Exception e){
            throw new DataDeskException('Error updating template : ' + e.getMessage());
        }
        return str;
    }
    
    public static String runTemplateFromJson(String templateJson){
        DataDesk_Template__c template = parseTemplate(templateJson);
        
        DD_Loader.FieldDefinition[] defs = DD_Loader.loadFieldsFromTemplate(template);
        sObject[] objects = new sObject[]{};
            
        Integer ct = Integer.valueOf(template.Record_Count__c);
        
        for (Integer i = 0; i < ct; i++){
        	sObject newObject = DD_Help.getNewSObject(template.Object_API_Name__c, template?.Record_Type_ID__c);
                
            for (DD_Loader.FieldDefinition def : defs){
                setValue(newObject, def);
            }

            objects.add(newObject);
        }
                
        try {
        	insert objects;
        	return JSON.serialize(new Map<String, String>{ 'url' => URL.getOrgDomainURL().toExternalForm() + '/' + objects[0].Id });
        } catch (Exception e){
            throw new DataDeskException(e.getMessage());
        }
    }
    
    public static void setValue(sObject record, DD_Loader.FieldDefinition fd){
        
        String 
            dataType = fd.dataType,
            fieldName = fd.apiName;
        
        Boolean 
			isNumber = 
				dataType == DD_Help.DISPLAY_TYPE_PERCENT 
				|| dataType == DD_Help.DISPLAY_TYPE_INTEGER 
				|| dataType == DD_Help.DISPLAY_TYPE_DOUBLE 
				|| dataType == DD_Help.DISPLAY_TYPE_CURRENCY,
			isList = 
				dataType == DD_Help.DISPLAY_TYPE_PICKLIST 
				|| dataType == DD_Help.DISPLAY_TYPE_MULTIPICKLIST
				|| dataType == DD_Help.DISPLAY_TYPE_REFERENCE,
            
            generateValue = fd.generateValue,
            isName = fd.apiName.contains('Name') && (fd.apiName.contains('First') || fd.apiName.contains('Last'));
        
        Object value = fd.currentValue;
        String[] values = fd.values;
        
        try {
            if (isList){
                
                value = generateValue ? DD_Help.getValueAtRandomIndex(fd.values) : value;
                record.put(fieldName, String.valueOf(value));
                
            } else if (dataType == DD_Help.DISPLAY_TYPE_BOOLEAN){
                if (generateValue){
                    Decimal num = DD_Help.getRandomDecimal(0, 100, 0);
                    value = num >= (100 - Decimal.valueOf(fd.min));
                }
                record.put(fieldName, (value == 'true' || value == true));
                
            } else if (dataType == DD_Help.DISPLAY_TYPE_DATE){
                
                value = generateValue ? DD_Help.getRandomDate(fd.min, fd.max) : value;
                record.put(fieldName, Date.valueOf(String.valueOf(value)));
                
            } else if (dataType == DD_Help.DISPLAY_TYPE_DATETIME){
                
                value = generateValue ? DD_Help.getRandomDateTime(fd.min, fd.max) : value;
                record.put(fieldName, DateTime.valueOf(String.valueOf(value).replace('T', ' ').replace('Z','')));
                
            } else if (dataType == DD_Help.DISPLAY_TYPE_PHONE){
                
                String digits = String.valueOf(DD_Help.getRandomLong(10000000000L,1999999999L));
                value = '1-' + digits.left(3) + '-' + digits.mid(3, 3) + '-' + digits.right(4);
                record.put(fieldName, String.valueOf(value));
                
			} else if (isNumber){
                
                if (dataType == DD_Help.DISPLAY_TYPE_INTEGER){
                    
                	value = generateValue ? DD_Help.getRandomInteger(Integer.valueOf(fd.min), Integer.valueOf(fd.max)) : value;
                    record.put(fieldName, Integer.valueOf(value));
                    
                } else if (dataType == DD_Help.DISPLAY_TYPE_DOUBLE 
                           || dataType == DD_Help.DISPLAY_TYPE_CURRENCY){
                    
                    value = generateValue ? DD_Help.getRandomDecimal(Integer.valueOf(fd.min), Integer.valueOf(fd.max), 2) : value;
                	record.put(fieldName, Double.valueOf(value));
                               
                } else {
                    value = generateValue ? DD_Help.getRandomDecimal(Integer.valueOf(fd.min), Integer.valueOf(fd.max), 2) : value;
                	record.put(fieldName, (Decimal)value); 
                }               
                
            } else if (generateValue && isName){
                
                record.put(fieldName, DD_Help.getRandomName());
                
            } else if (generateValue && dataType == DD_Help.DISPLAY_TYPE_EMAIL){
                String email;
                
                if (record.get('LastName') != null){
                    value = getMergeValue(record, 'i.am.[[FirstName]].[[LastName]].' + 
                                                    Math.ceil(Math.random() * 1000000000.0) +
                                                   '@datadesk.com').replaceAll(' ', '.');
                } else {
                    value = Math.ceil(Math.random() * 1000000000.0) + '@datadesk.com';
                }
                
                record.put(fieldName, value);
                
            } else {
                value = generateValue ? getMergeValue(record, String.valueOf(value)) : value;
                record.put(fieldName, String.valueOf(value));
            }
            
        } catch(Exception e){
            throw new DataDeskException('Error setting object value : ' + fieldName + ' : ' + value + ' : ' + e.getMessage());
        }
    }

    public static String getMergeValue(sObject record, String input){
        String output = input, replacementValue;
        
        for (String match : parseMergeFields(output)){
            try {
                if (match.contains('FNAME') || match.contains('LNAME')){
                    
                    replacementValue = DD_Help.getRandomName();
                    
                } else if (match.contains('COMMENT')){
                    
                    replacementValue = DD_Help.getValueAtRandomIndex(DD_Help.comments);
                    
                } else if (match.contains('TITLE')){
                    
                    replacementValue = DD_Help.getValueAtRandomIndex(DD_Help.titles);
                    
                } else if (match.contains('RAND')){
                    // [[RAND|9]] generates a 9 digit number
                    Integer digits = Integer.valueOf(match.replace('RAND|', ''));
                    String val = String.valueOf(DD_Help.getRandomDecimal((Long)1, (Long)Math.pow(10, digits), 0));
                    for (Integer i = 0; i < (digits - val.length()); i++){
                        val = '0' + val;
                    }
                    replacementValue = val;
                    
                } else {
					replacementValue = record.get(match) != null ? String.valueOf(record.get(match)) : '';
                }
                
                output = output.replace('[[' + match + ']]', replacementValue);
            } catch(Exception e){
                throw new DataDeskException('Error parsing merge field. Match : ' + match + ' : input : ' + input + ' : ' + e.getMessage());
            }
        }
        
        return output;
    }
    
    public static List<String> parseMergeFields(String input) {
        List<String> matches = new List<String>();
        Pattern pattern = Pattern.compile('\\[\\[(.*?)\\]\\]');
        Matcher matcher = pattern.matcher(input);
        while (matcher.find()) {
            matches.add(matcher.group(1));
        }
        
        return matches;
    }

    public static void refreshPageLayout(String jsonString){
        DataDesk_Template__c template;
        try {
        	template = parseTemplate(jsonString);
            refreshPageLayout(template);
        } catch (Exception e){
            throw new DataDeskException('Error updating page layout : ' + e.getMessage());
        }
    }
    
    public static void refreshPageLayout(DataDesk_Template__c template){
        Boolean nameAdded = false, address1Added = false, address2Added = false;
        
        JSONParse[] sectionJson = new JSONParse(template.Field_JSON__c).asList();

        Metadata.Layout layout = new Metadata.Layout(); 
        layout.fullName = template.Object_API_Name__c + '-DATADESK-' + template.Record_Type_API_Name__c;

        for (JSONParse sectionObj : sectionJson){
            
            Metadata.LayoutSection section = new Metadata.LayoutSection();
            section.label = sectionObj.get('name').getStringValue();
            section.style = Metadata.LayoutSectionStyle.OneColumn;
            section.detailHeading  = true;
            section.editHeading = true;
            
            section.style = sectionObj.get('columnCount').getIntegerValue() == 1 ? Metadata.LayoutSectionStyle.OneColumn : Metadata.LayoutSectionStyle.TwoColumnsLeftToRight;
            section.layoutColumns = new List<Metadata.LayoutColumn>();
            
            JSONParse[] columnJson = sectionObj.get('columns').asList();                
            for (JSONParse columnObj : columnJson){
                
                Metadata.LayoutColumn column = new Metadata.LayoutColumn();
                column.layoutItems = new Metadata.LayoutItem[]{};
                    
                JSONParse[] fieldJson = columnObj.get('fields').asList();
                for (JSONParse fieldObj : fieldJson){
                    
                    Metadata.LayoutItem item = new Metadata.LayoutItem();
                    item.field = fieldObj.get('apiName').getStringValue();
                    
                    Boolean 
                        isLead = template.Object_API_Name__c == 'Lead',
                        isAccount = template.Object_API_Name__c == 'Account',
                        isContact = template.Object_API_Name__c == 'Contact',
                        isName = (item.field == 'FirstName' || item.field == 'LastName'),
                        isAddress = (
                            item.field.contains('Street') 
                            || item.field.contains('City') 
                            || item.field.contains('State') 
                            || item.field.contains('ZipPostalCode') 
                            || item.field.contains('Country')
                        ),
                        isAddress1 = isAddress && (isLead || item.field.contains('Mailing') || item.field.contains('Shipping')),
                        isAddress2 = isAddress && (item.field.contains('Other') || item.field.contains('Billing'));
                    
                    if (isName & !nameAdded){
                        item.field = 'Name';
                        nameAdded = true;
                        item.behavior = Metadata.UiBehavior.Required;
                    	column.layoutItems.add(item);
                    } else if (isAddress){
                        if (isAddress1 && !address1Added){
                            if (isLead){
                        		item.field = 'Address';
                            } else if (isAccount){
                        		item.field = 'ShippingAddress';
                            } else if (isContact){
                        		item.field = 'MailingAddress';
                            }
                        	address1Added = true;
                            item.behavior = Metadata.UiBehavior.Edit;
                            column.layoutItems.add(item);
                        } else if (isAddress2 && !address2Added){
                            if (isAccount){
                        		item.field = 'BillingAddress';
                            } else if (isContact){
                        		item.field = 'OtherAddress';
                            }
                        	address2Added = true;
                            item.behavior = Metadata.UiBehavior.Edit;
                            column.layoutItems.add(item);
                        }
                    } else if (!isName && !isAddress) {                        
                    	item.behavior = fieldObj.exists('isRequired') && fieldObj.get('isRequired').getBooleanValue() ? Metadata.UiBehavior.Required : Metadata.UiBehavior.Edit;
                    	column.layoutItems.add(item);
                    }
                }
                section.layoutColumns.add(column);
            }
            layout.layoutSections.add(section);
        }
    
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(layout);

    	// Enqueue custom metadata deployment
    	Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, null);
    }
    
    private static DataDesk_Template__c parseTemplate(String jsonString){
        DataDesk_Template__c temp = (DataDesk_Template__c)JSON.deserialize(jsonString, DataDesk_Template__c.class);
        return temp;
    }
}