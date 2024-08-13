import { api, wire } from "lwc";
import { EDIT_SECTION_PROPERTIES, EDIT_FIELD_PROPERTIES } from 'c/ddUtil';
import { getObjectInfo } from "lightning/uiObjectInfoApi";

import getPicklistValues from '@salesforce/apex/DD_Controller.getPicklistValues';

import LightningModal from 'lightning/modal';
export default class FieldEditModal extends LightningModal {
  @api field;
  @api objectApiName;

  error;
  
  showName = true;
  showRemove = true;
  title = 'Edit Field';

  description;
  generateValue;
  iterateValues;
  isIterable = false;
  min;
  max;

  recordTypeOptions = [];
  valueOptions;
  allSelected = false;
  buttonLabel = '';

  referenceIdField;
  referenceObjectName;
  recordTypeId;
  profileNameLike;
  criteria;
  orderBy;
  recordLimit;
  
  isLoading = true;
  async connectedCallback(){
    console.log('FieldEditModal input field : ' + JSON.stringify(this.field));
    try {
      this.title += ' : ' + this.field.apiName;
      this.hideRemove = this.field.isRequired;
      this.generateValue = this.field.generateValue || false;
      this.min = this.field.min || this.field.currentValue;
      this.max = this.field.max || this.field.currentValue;
      this.description = this.field.description;

      if (this.field?.query?.referenceIdField){
        this.referenceIdField = this.field.query?.referenceIdField;
        this.referenceObjectName = this.field.query?.referenceObjectName;
        this.recordTypeId = this.field.query?.recordTypeId;
        this.profileNameLike = this.field.query?.profileNameLike;
        this.criteria = this.field.query?.criteria;
        this.orderBy = this.field.query?.orderBy;
        this.recordLimit = this.field.query?.recordLimit;
        this.isIterable = true;
      }

      if (this.field?.inputType.combobox){
        let data = await getPicklistValues({ objectApiName: this.objectApiName, fieldApiName: this.field?.apiName });
        let vals = JSON.parse(data)?.picklistValues;
        if (vals){
          let temp = {};
          this.field.values.forEach(valObj => temp[valObj.value] = true);
          this.valueOptions = vals.map(valObj => { 
            return { ...valObj, isSelected: !!temp[valObj.value] }
          });

          this.allSelected = this.valueOptions.length == vals.length ? true : false;
          this.buttonLabel = !!this.allSelected ? 'Exclude All Values' : 'Include All Values';
        }
        this.isIterable = true;
      }
    } catch(error){
      this.error = error.message;
      console.log(error.message);
    }
    this.isLoading = false;
  }

  @wire(getObjectInfo, { objectApiName: '$referenceObjectName' })
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
        if (!!!this.recordTypeId){
          this.recordTypeId = temp[0].value;
        }
      } else {
        this.recordTypeOptions = undefined;
        this.recordTypeId = undefined;
      }

      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.recordTypeOptions = undefined;
      this.recordTypeId = undefined;
    }
    this.isLoading = false;
  }
  
  async handleSave(){
    let data = {};

    try {
      this.template.querySelectorAll('[data-name="data"]').forEach(element => {
        data[element.dataset.id] = (element.type == 'toggle' || element.type == 'checkbox') ? element.checked : element.value;
      });

      if (this.field?.query?.referenceIdField){
        let query = {};

        if (this.generateValue){
          this.template.querySelectorAll('[data-name="query"]').forEach(element => { query[element.dataset.id] = element.value });
          query.referenceObjectName = this.referenceObjectName;
        } else {
          query = { ...this.field.query };
        }

        if (this.recordTypeOptions?.length > 0)
          query.recordTypeName = this.recordTypeOptions?.find(recType => recType.value == this.recordTypeId)?.label;
        
        data.query = query;
      }

      if (this.valueOptions){
        data.values = [];
        this.valueOptions.forEach(valObj => {
          if (valObj.isSelected){
            data.values.push({
              label: valObj.label,
              value: valObj.value
            });
          }
        });
      }
      
      this.close(data);
    } catch(error) {
      console.log('Modal issue : ' + error.message);
    }
  }

  handleSelectAllValues(){ 
    let temp = this.valueOptions.map(valObj => { return { ...valObj, isSelected: !this.allSelected }});
    this.valueOptions = temp;
    this.allSelected = !this.allSelected;
    this.buttonLabel = !!this.allSelected ? 'Exclude All Values' : 'Include All Values';
  }
  
  handleToggleGenerate(event){ this.generateValue = event.currentTarget.checked }
  handleToggleIterate(event){ this.iterateValues = event.currentTarget.checked }
  handleValueChange(event){ this.recordTypeId = event.detail.value }
  handleToggleSelect(event){
    let val = this.valueOptions.find(valObj => valObj.value == event.currentTarget.dataset.id);
    val.isSelected = event.currentTarget.checked;
  }

  handleRemove(){this.close({ REMOVE: true }) }
}