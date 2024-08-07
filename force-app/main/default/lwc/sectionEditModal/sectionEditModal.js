import { api } from "lwc";

import LightningModal from 'lightning/modal';
export default class SectionEditModal extends LightningModal {
  @api section;

  name;
  description;
  position;
  title = 'Edit Section : ' + name;

  error;
  
  showRemove = true;
  
  isLoading = true;
  connectedCallback(){
    this.name = this.section.name;
    this.description = this.section.description;
    this.position = Number(this.section.index) + 1;
    
    this.isLoading = false;
  }

  async handleSave(){
    let data = {};

    try {
      this.template.querySelectorAll('[data-name="data"]').forEach(element => {
        data[element.dataset.id] = element.value;
      });

      this.close(data);
    } catch(error) {
      console.log('Modal issue : ' + error.message);
    }
  }

  handleRemove(){this.close({ REMOVE: true }) }
}