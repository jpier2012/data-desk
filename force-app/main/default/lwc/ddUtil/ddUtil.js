import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// indices
export const FROM_SECTION_INDEX = 'FROM_SECTION_INDEX';
export const FROM_COLUMN_INDEX = 'FROM_COLUMN_INDEX';
export const FROM_ROW_INDEX = 'FROM_ROW_INDEX';
export const FROM_FIELD_INDEX = 'FROM_FIELD_INDEX';
export const FROM_FIELD_NAME = 'FROM_FIELD_NAME';
export const TO_SECTION_INDEX = 'TO_SECTION_INDEX';
export const TO_COLUMN_INDEX = 'TO_COLUMN_INDEX';
export const TO_ROW_INDEX = 'TO_ROW_INDEX';
export const TO_FIELD_INDEX = 'TO_FIELD_INDEX';
export const TO_FIELD_NAME = 'TO_FIELD_NAME';
export const NEW_INDEX = 'NEW_INDEX';

//actions
export const INITIALIZE = "INITIALIZE";
export const FILTER_FIELDS = "FILTER_FIELDS";
export const TOGGLE_FIELD_SELECTION = "TOGGLE_FIELD_SELECTION";
export const ADD_FIELD_TO_LAYOUT = "ADD_FIELD_TO_LAYOUT";
export const MOVE_FIELD_ON_LAYOUT = "MOVE_FIELD_ON_LAYOUT"; 
export const REMOVE_FIELD_FROM_LAYOUT = "REMOVE_FIELD_FROM_LAYOUT"; 
export const ADD_NEW_SECTION = "ADD_NEW_SECTION";
export const MOVE_SECTION = "MOVE_SECTION"; 
export const REMOVE_SECTION = "REMOVE_SECTION"; 
export const SET_FIELD_VALUE = "SET_FIELD_VALUE"; 
export const UPDATE_TEMPLATE = "UPDATE_TEMPLATE"; 
export const EDIT_SECTION_PROPERTIES = "EDIT_SECTION_PROPERTIES"; 
export const EDIT_FIELD_PROPERTIES = "EDIT_FIELD_PROPERTIES"; 

//UI vars
export const SELECTED_CLASS = "selected";
export const BUTTON_CLASS = "box stretch";
export const DRAG_STYLE = "background-color: lightblue;";

// helper functions
export const getInputTypeObject = (dataType) => {
  let temp = {};

  if (dataType == 'REFERENCE'){
    temp.search = true;
  } else if (dataType == 'BOOLEAN'){
    temp.checkbox = true;
  } else if (dataType == 'EMAIL'){
    temp.email = true;
  } else if (dataType == 'DATE'){
    temp.date = true;
  } else if (dataType == 'DATETIME'){
    temp.datetime = true;
  } else if (dataType == 'PHONE'){
    temp.tel = true;
  } else if (dataType == 'PERCENT'
    || dataType == 'INTEGER'
    || dataType == 'DOUBLE'
    || dataType == 'CURRENCY'){
      temp.number = true;
  } else if (dataType == 'PICKLIST' 
    || dataType == 'MULTIPICKLIST'){
      temp.combobox = true;
  } else {
    temp.text = true;
  }

  return temp;
}

export const toggleHighlight = (selectedField) => {
  if (selectedField.isDraggable){
    selectedField.buttonClasses += " " + SELECTED_CLASS;
  } else {
    selectedField.buttonClasses = selectedField.buttonClasses.replace(" " + SELECTED_CLASS, "");
  }
  selectedField.isDraggable = !selectedField.isDraggable;
}

export function err(error){
  let message = printError(error);
  
  let title = (!!error?.title) ? error.title : 'Error';

  const event = new ShowToastEvent({
    variant: 'error',
    mode: 'sticky',
    title: title,
    message: message
  });
  this.dispatchEvent(event);
}

export function printError(error){
  let message;

  if (error?.body?.pageErrors && error.body.pageErrors.length > 0){
    message = error.body.pageErrors.map((e) => e.message).join(", ");
  } else if (error?.body?.fieldErrors){
    message = '';
    for (let key of Object.keys(error.body.fieldErrors)){
      message += error.body.fieldErrors[key].map((e) => e.message).join(", ");
    };
  } else if (error?.message){
    message = error?.message;
  } else if (error?.body?.message){
    message = error?.body?.message;
  } else {
    message = JSON.stringify(error);
  }

  console.log(`ERROR : ${message}`);

  return message;
}

export function woot(message){
  const event = new ShowToastEvent({
    title: 'Success!',
    variant: 'success',
    message: message
  });
  this.dispatchEvent(event);
}

export function resize(){
  let top = this.refs.scroller.getBoundingClientRect().top;
  let height = window.innerHeight - top - 30;
  this.refs.scroller.style.maxHeight = `${height}px`;
  this.refs.scroller.style.minHeight = `${height}px`;
}

export const getFieldParams = (field) => {
  
  let obj = {
    apiName: field.apiName,
    currentValue: field.defaultValue,
    inputType: field.inputType,
    isRequired: field.isRequired,
    dataType: field.dataType,
    label: field.label,
    generateValue: false
  };

  obj.isNameField = field.apiName.includes('Name') && (field.apiName.includes('First') || field.apiName.includes('Last'));
    
  if (field.picklistValues?.length > 0){
    // console.log('field.picklistValues ' + JSON.stringify(field.picklistValues));
    let valObj = field.picklistValues.find(option => option.value == field.defaultValue);
    // console.log('valObj ' + JSON.stringify(valObj));
    obj.values = [ valObj ];
    // console.log('obj.values ' + JSON.stringify(obj.values));
  }

  if (field.query)
    obj.query = field.query;

  return obj;
}