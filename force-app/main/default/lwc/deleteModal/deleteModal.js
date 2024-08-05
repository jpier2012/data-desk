import LightningModal from 'lightning/modal';
import { api } from "lwc";
import { printError } from 'c/ddUtil';
import deleteRecords from '@salesforce/apex/DD_Controller.deleteRecords';
import deleteObjectPicklistRecords from '@salesforce/apex/DD_Controller.deleteObjectPicklistRecords';

export default class DeleteModal extends LightningModal {

  @api selectedObject;
  message;

  showDateRange = true;
  deleteRecordsForAllObjects = false;

  handleDateToggle(){this.showDateRange = !this.showDateRange;}
  handleObjectToggle(){this.deleteRecordsForAllObjects = !this.deleteRecordsForAllObjects;}

  deleteStartDate = new Date().toJSON();
  deleteEndDate = new Date().toJSON();

  handleDelete(){
    try {

      let startDate = null;
      let endDate = null;
  
      if (this.showDateRange == true){
        startDate = this.deleteStartDate;
        endDate = this.deleteEndDate;
      }
  
      console.log("selected object for delete : " + this.selectedObject);
      console.log("startDate for delete : " + startDate);
      console.log("endDate for delete : " + endDate);
      console.log("deleteRecordsForAllObjects : " + this.deleteRecordsForAllObjects);
      
      if (this.deleteRecordsForAllObjects == true){
        deleteObjectPicklistRecords({ 
          startDate: startDate, 
          endDate: endDate 
        });
      } else {
        deleteRecords({ 
          objectName: this.selectedObject, 
          startDate: startDate, 
          endDate: endDate
        });
      }
      this.message = "Delete jobs initiated. Check the Apex Jobs menu for job status.";
    } catch (e){
      this.message = printError(e);
    }
  }
}