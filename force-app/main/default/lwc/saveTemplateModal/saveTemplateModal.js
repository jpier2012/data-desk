import { wire, api } from "lwc";
import LightningModal from 'lightning/modal';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { printError } from 'c/ddUtil';

import JSON_FIELD from '@salesforce/schema/DataDesk_Template__c.JSON__c';
import LAYOUT_JSON_FIELD from '@salesforce/schema/DataDesk_Template__c.Layout_JSON__c';
import FIELD_JSON_FIELD from '@salesforce/schema/DataDesk_Template__c.Field_JSON__c';``
import DESCRIPTION_FIELD from '@salesforce/schema/DataDesk_Template__c.Description__c';
import OBJECT_API_NAME_FIELD from '@salesforce/schema/DataDesk_Template__c.Object_API_Name__c';
import RECORD_TYPE_API_NAME_FIELD from '@salesforce/schema/DataDesk_Template__c.Record_Type_API_Name__c';
import RECORD_TYPE_ID_FIELD from '@salesforce/schema/DataDesk_Template__c.Record_Type_ID__c';
import RECORD_COUNT_FIELD from '@salesforce/schema/DataDesk_Template__c.Record_Count__c';

export default class SaveTemplateModal extends LightningModal {
  @api selectedTemplate;

  constructor(props){ super(); this.printError = printError.bind(this); }

  jsonFN = JSON_FIELD.fieldApiName;
  layoutJsonFN = LAYOUT_JSON_FIELD.fieldApiName;
  fieldJsonFN = FIELD_JSON_FIELD.fieldApiName;
  descriptionFN = DESCRIPTION_FIELD.fieldApiName;
  objectFN = OBJECT_API_NAME_FIELD.fieldApiName;
  recordTypeNameFN = RECORD_TYPE_API_NAME_FIELD.fieldApiName;
  recordTypeIdFN = RECORD_TYPE_ID_FIELD.fieldApiName;
  recordCountFN = RECORD_COUNT_FIELD.fieldApiName;

  objectOptions = [];
  recordTypeOptions = [];
  
  error;
  title = '';
  buttonLabel = '';
  templateName;
  description = '';
  recordCount;

  selectedObject;
  selectedRecordTypeId;
  disableObjectSelect = false;

  isLoading = true;

  connectedCallback(){
    if (this.selectedTemplate){
      this.title = 'Edit Template';
      this.templateName = this.selectedTemplate.Name;
      this.description = this.selectedTemplate[this.descriptionFN];
      this.recordCount = this.selectedTemplate[this.recordCountFN] || 1;
     } else {   
      this.title = 'Create New Template';
      this.templateName = 'New Template ' + new Date().toJSON().replace('T', ' ').slice(0, 19);
      this.recordCount = 1;
    }
  }

  @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: OBJECT_API_NAME_FIELD })
  getObjectOptions({ error, data }) {
    if (data) {
      this.objectOptions = data.values;

      if (this.selectedTemplate){
        this.selectedObject = this.selectedTemplate[this.objectFN];
        this.disableObjectSelect = true;
      } else {
        this.selectedObject = data.values[0].value;
      }

      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.objectOptions = undefined;
      this.fields = undefined;
    }
  }

  @wire(getObjectInfo, { objectApiName: '$selectedObject' })
  getRecordTypes({ error, data }) {
    this.isLoading = true;

    if (data) {
      let temp = [];
      let recTypes = data.recordTypeInfos;
      for (var id in recTypes){
        let recTypeName = recTypes[id].name;

        if (recTypeName == 'Master'){
          continue;
        }

        let recTypeId = recTypes[id].recordTypeId;
        let isDefault = recTypes[id].defaultRecordTypeMapping;
        temp.push({ label: recTypeName, value: recTypeId, isDefault: isDefault });
      }
      if (temp?.length > 0){
        temp.sort((a, b) => {
          return a?.isDefault ? -1 : 0;
        });
        this.recordTypeOptions = temp;

        if (this.selectedTemplate){
          this.selectedRecordTypeId = this.selectedTemplate[this.recordTypeIdFN];
        } else {
          this.selectedRecordTypeName = temp[0].label;
          this.selectedRecordTypeId = temp[0].value;
        }
      } else {
        this.recordTypeOptions = undefined;
        this.selectedRecordTypeId = undefined;
      }

      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.recordTypeOptions = undefined;
      this.selectedRecordTypeId = undefined;
    }
    this.isLoading = false;
  }

  recordTypeChange(event) { this.selectedRecordTypeId = event.detail.value; }
  objectChange(event) { this.selectedObject = event.detail.value; }

  async handleSave(){
    let template = {};
    
    try {
      this.template.querySelectorAll('[data-id="template"]').forEach(element => {
        template[element.name] = element.value;
      });
      template[this.recordTypeNameFN] = this.recordTypeOptions.find(item => item.value == this.selectedRecordTypeId)?.label;


    } catch(error) {
      console.log('Modal issue : ' + error.message);
    }

    this.close(template);
  }
}