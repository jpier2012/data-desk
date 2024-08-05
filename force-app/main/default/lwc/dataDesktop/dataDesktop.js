import { ReduxElement } from 'c/lwcRedux';
import { initialize, updateTemplate } from 'c/ddActions'; 
import { err, woot } from 'c/ddUtil';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import JSON_FIELD from '@salesforce/schema/DataDesk_Template__c.JSON__c';
import LAYOUT_JSON_FIELD from '@salesforce/schema/DataDesk_Template__c.Layout_JSON__c';
import FIELD_JSON_FIELD from '@salesforce/schema/DataDesk_Template__c.Field_JSON__c';``
import DESCRIPTION_FIELD from '@salesforce/schema/DataDesk_Template__c.Description__c';
import OBJECT_NAME_FIELD from '@salesforce/schema/DataDesk_Template__c.Object_API_Name__c';
import RECORD_COUNT_FIELD from '@salesforce/schema/DataDesk_Template__c.Record_Count__c';

import SaveTemplateModal from 'c/saveTemplateModal';
import LoadTemplateModal from 'c/loadTemplateModal';
import DeleteModal from 'c/deleteModal';

import getFieldDefinitions from '@salesforce/apex/DD_Controller.getFieldDefinitions';
import getLastModifiedTemplate from '@salesforce/apex/DD_Controller.getLastModifiedTemplate';
import insertTemplate from '@salesforce/apex/DD_Controller.insertTemplate';
import updateTemplateRecord from '@salesforce/apex/DD_Controller.updateTemplate';
import refreshPageLayout from '@salesforce/apex/DD_Controller.refreshPageLayout';
import runTemplate from '@salesforce/apex/DD_Controller.runTemplate';

export default class DataDesktop extends ReduxElement {
  
  jsonFN = JSON_FIELD.fieldApiName;
  layoutJsonFN = LAYOUT_JSON_FIELD.fieldApiName;
  fieldJsonFN = FIELD_JSON_FIELD.fieldApiName;
  descriptionFN = DESCRIPTION_FIELD.fieldApiName;
  objectFN = OBJECT_NAME_FIELD.fieldApiName;
  recordCountFN = RECORD_COUNT_FIELD.fieldApiName;

  isLoading = true;

  constructor(props){ super(); this.err = err.bind(this); this.woot = woot.bind(this); }
  mapStateToProps(state){ return { template: state.template, layout: state.layout } }
  mapDispatchToProps(){ return { initialize: initialize, updateTemplate: updateTemplate } }

  connectedCallback(){
    console.log("dataDesktop connectedCallback");
    document.body.setAttribute('style', 'overflow: hidden;');
    try {
        super.connectRedux();
        this.start();
    } catch(e){
        console.log(e.message);
    }
}

async start(){
  this.isLoading = true;
  try {
    let template = await getLastModifiedTemplate();
    template = JSON.parse(template);
    this.loadLayoutAndFields(template);
  } catch(error){
    this.err(error);
  }
  console.log('DataDesktop initialization complete');
}

async handleRun(){
  console.log('Running template...');
  this.woot('Running!');
  let template = { ...this.props.template, [this.fieldJsonFN]: JSON.stringify(this.props.layout) };
  console.log(JSON.stringify(template));
  await runTemplate({ templateJson: JSON.stringify(template) })
    .then(result => {
      console.log('Result : ' + JSON.stringify(result));
      this.recSuccess(JSON.parse(result).url);
    })
    .catch(error => {
      this.err(error);
    });
  console.log('Done.');
}


async loadLayoutAndFields(template){
  try {
    let data = await getFieldDefinitions({ objectApiName: template[this.objectFN] });
    let allFields = JSON.parse(data).fields;
    this.props.initialize(template[this.fieldJsonFN], template, allFields);
  } catch(error){
    this.err(error);
  }
  this.isLoading = false;
}

async handleNewTemplate(){
  let template;
  try {
    await SaveTemplateModal.open({ size: 'small' }).then(returnData =>  template = !!returnData ? returnData : undefined );
    if (!!template){
      let result = await insertTemplate({ jsonString: JSON.stringify(template) });
      let temp = JSON.parse(result);
      if (temp.isSuccess){
        console.log('result : ' + result);
        this.woot('Template saved!');
        this.loadLayoutAndFields(result.template);
      }
    }
  } catch(error) {
    this.err(error);
  }
}

async handleSave(){
  try {
    let temp = JSON.stringify({ ...this.props.template, [this.fieldJsonFN]: JSON.stringify(this.props.layout) });
    await updateTemplateRecord({ jsonString: temp })
    .then(result => {
      console.log('Template : ' + JSON.stringify(temp));
      if(JSON.parse(result).isSuccess)
          this.woot('Template saved successfully!')
    });

    await refreshPageLayout({ jsonString: temp });
    console.log('Page layout refreshed!');
  } catch(error){
    this.err(error);
  }
}

async handleLoadTemplate(){
  let template;
  try {
    await LoadTemplateModal.open({ size: 'small' }).then(returnData => template = !!returnData ? returnData : undefined);
    if (!!template){
      this.loadLayoutAndFields(template);
      this.woot(template.Name + ' loaded!');
    }
  } catch(error) {
    this.err(error);
  }
}

async handleEditTemplate(){
  await SaveTemplateModal.open({ size: 'small', selectedTemplate: this.props.template })
  .then(returnData => { 
    if (!!returnData){
      this.props.updateTemplate({ ...this.props.template, ...returnData });
      this.handleSave();
    }
  })
  .catch(error => this.err(error));
}

async handleDeleteRecords(){
  await DeleteModal.open({ size: 'small', selectedObject: this.props.template[this.objectFN] })
  .then(returnData => { 
    if (!!returnData){
      // TODO
    }
  })
  .catch(error => this.err(error));
}

recSuccess(url){
  const event = new ShowToastEvent({
    title: 'Success!',
    message: "{0}",
    messageData: [{
      url: url,
      label: 'Link to Record'
    }],
    variant: 'success',
    role: 'status'
  });
  this.dispatchEvent(event);
  }
}