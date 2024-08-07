import LightningModal from 'lightning/modal';
import { api, wire } from "lwc";
import { printError } from 'c/ddUtil';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import deleteRecords from '@salesforce/apex/DD_Controller.deleteRecords';
import OBJECT_API_NAME_FIELD from '@salesforce/schema/DataDesk_Template__c.Object_API_Name__c';

export default class DeleteModal extends LightningModal {

  @api selectedObject;
  message;
  objectOptions;

  deleteStartDate = new Date().toJSON();
  deleteEndDate = new Date().toJSON();

  @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: OBJECT_API_NAME_FIELD })
  getObjectOptions({ error, data }) {
    if (data) {
      this.objectOptions = data.values.map(valObj => { 
        return { ...valObj, isSelected: valObj.value == this.selectedObject }
      });

    } else if (error) {
      this.objectOptions = undefined;
      console.log('getPicklistValues error : ' + error.message);
    }
  }

  handleDelete(){
    try {
      let objectNames = 
        this.objectOptions
          .filter(valObj => valObj.isSelected )
          .map(valObj => { return valObj.value });

       deleteRecords({ 
          objectNames: objectNames,
          startDate: deleteStartDate, 
          endDate: deleteEndDate
      });
      this.message = "Delete jobs initiated. Check the Apex Jobs menu for job status.";
    } catch (e){
      this.message = printError(e);
    }
  }

  handleToggleSelect(event){
    let val = this.objectOptions.find(valObj => valObj.value == event.currentTarget.dataset.id);
    val.isSelected = event.currentTarget.checked;
  }
}