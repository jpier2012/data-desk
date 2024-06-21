import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { subscribe, unsubscribe } from "lightning/empApi";
import Id from "@salesforce/user/Id";

export default class PlatformToast extends LightningElement {

  @track channelName = "/event/Platform_Toast__e";
  @api applicationName;
  @api isUserSpecific;
  userId = Id;
  subscription = {};

  showToast(application, title, message, variant, mode, user, URL) {
    let messageData = [
      {
        url: URL,
        label: message
      }
    ];

    if (URL != undefined && URL != null && URL != ''){
        message = "{0}";
    }

    if (
      (user == null || user === this.userId) &&
      (application == null || application === this.applicationName)
    ) {
      const evt = new ShowToastEvent({
        title: title,
        message: message,
        messageData: messageData,
        variant: variant,
        mode: mode,
        role: 'status'
      });
      this.dispatchEvent(evt);
    }
  }

  connectedCallback() {
    const messageCallback = function(response) {
      const message = response.data.payload;
      this.showToast(
        message.Application__c,
        message.Title__c,
        message.Message__c,
        message.Style__c,
        message.Mode__c,
        message.User__c,
        message.URL__c
      );
    }.bind(this);
    subscribe(this.channelName, -1, messageCallback).then(response => {
      this.subscription = response;
    });
  }

  disconnectedCallback() {
    unsubscribe(this.subscription);
  }
}