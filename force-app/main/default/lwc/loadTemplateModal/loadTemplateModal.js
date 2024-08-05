import LightningModal from 'lightning/modal';
import { printError } from 'c/ddUtil';

import getTemplates from '@salesforce/apex/DD_Controller.getTemplates';

export default class LoadTemplateModal extends LightningModal {
  error;
  templates;
  templateOptions = [];
  
  isLoading = true;

  constructor(props){ super(); this.printError = printError.bind(this); }

  async connectedCallback(){
    try {
      let data = await getTemplates();
      let templates = JSON.parse(data);
      let templateOptions = [];

      templates.forEach(template => {
        templateOptions.push({
          label: template.Name,
          value: template.Id
        });
      });
      
      this.templates = templates;
      this.templateOptions = templateOptions;
    } catch(error){
      this.error = this.printError(error);
    }
    this.isLoading = false;
  }

  async handleLoad(){
    let template;
    try {
      let templateId = this.template.querySelector('[data-name="templateSelect"]').value;
      template = this.templates.find(template => template.Id == templateId);
      this.close(template);
    } catch(error){
      this.error = this.printError(error);
    }
  }
}