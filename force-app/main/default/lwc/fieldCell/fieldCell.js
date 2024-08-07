import { api } from "lwc";
import { ReduxElement } from 'c/lwcRedux';
import { 
  FROM_SECTION_INDEX, FROM_COLUMN_INDEX, FROM_FIELD_INDEX, FROM_FIELD_NAME, 
  TO_SECTION_INDEX, TO_COLUMN_INDEX, TO_FIELD_INDEX, TO_FIELD_NAME, NEW_INDEX,
  
  DRAG_STYLE,

  err
 } from 'c/ddUtil';
import { 
  addFieldToLayout, moveFieldOnLayout, removeFieldFromLayout, setFieldValue,
  updateField
 } from 'c/ddActions';

 import FieldEditModal from 'c/fieldEditModal'

export default class Layout extends ReduxElement {
  @api field;
  @api sectionIndex;
  @api columnIndex;
  @api fieldIndex;
  @api objectApiName;

  isLoading = true;

  constructor(props){ super(); this.err = err.bind(this); }

  mapDispatchToProps(){
    console.log('Layout mapDispatchToProps');
    return { 
      addFieldToLayout: addFieldToLayout,
      moveFieldOnLayout: moveFieldOnLayout,
      removeFieldFromLayout: removeFieldFromLayout,
      setFieldValue: setFieldValue,
      updateField: updateField
    };
  }

  connectedCallback(){
    super.connectRedux();

    console.log("FieldCell  connected : " + this.field.apiName);
    this.isLoading = false;
  }
  
  handleDragStart(event) {
    event.dataTransfer.setData(FROM_FIELD_NAME, event.currentTarget.dataset.id);
    event.dataTransfer.setData(FROM_SECTION_INDEX, event.currentTarget.dataset?.sectionIndex);
    event.dataTransfer.setData(FROM_COLUMN_INDEX, event.currentTarget.dataset?.columnIndex);
    event.dataTransfer.setData(FROM_FIELD_INDEX, event.currentTarget.dataset?.fieldIndex);
  }

  handleDragOver(event) {
    event.preventDefault();
    const toFieldName = event.currentTarget.dataset.id;

    if (toFieldName == 'spot'){
      event.currentTarget.style = DRAG_STYLE;
    } else {
      let dims = 
        this.template.querySelector(`[data-id="${toFieldName}"]`)
        .getBoundingClientRect();
        
      if (event.clientY <= ((dims.height / 2) + dims.top)){
        event.currentTarget.style = DRAG_STYLE + ' border-radius: .5em; border-top: 5px solid gray;';
      } else {
        event.currentTarget.style = DRAG_STYLE + ' border-radius: .5em; border-bottom: 5px solid gray;';
      }
    }
  }
  
  handleDragLeave(event) {
    event.preventDefault();
    event.currentTarget.style = '';
  }

  handleDrop(event) {
    console.log('Handle drop');
    this.handleDragLeave(event);
    
    let addr = {
      [FROM_SECTION_INDEX]: event.dataTransfer.getData(FROM_SECTION_INDEX),
      [FROM_COLUMN_INDEX]: event.dataTransfer.getData(FROM_COLUMN_INDEX),
      [FROM_FIELD_INDEX]: event.dataTransfer.getData(FROM_FIELD_INDEX),
      [FROM_FIELD_NAME]: event.dataTransfer.getData(FROM_FIELD_NAME),
      [TO_SECTION_INDEX]: event.currentTarget.dataset.sectionIndex,
      [TO_COLUMN_INDEX]: event.currentTarget.dataset.columnIndex,
      [TO_FIELD_INDEX]: event.currentTarget.dataset.fieldIndex,
      [TO_FIELD_NAME]: event.currentTarget.dataset.id,

      [NEW_INDEX]: 0
    };

    if (addr[TO_FIELD_NAME] != addr[FROM_FIELD_NAME]){
      if (addr[TO_FIELD_NAME] != 'spot'){
        let dims = this.template.querySelector(`[data-id="${addr[TO_FIELD_NAME]}"]`)
        .getBoundingClientRect();
          
        let isAbove = event.clientY <= ((dims.height / 2) + dims.top);
        addr[NEW_INDEX] = isAbove ? addr[TO_FIELD_INDEX] : Number(addr[TO_FIELD_INDEX]) + 1;
        console.log('addr.newIndex : ' + addr[NEW_INDEX]);
      }
    
      // indicates it's coming from a field button, e.g. loaded value
      if (!!!addr[FROM_SECTION_INDEX]){
        this.props.addFieldToLayout(addr);
      } else {
        this.props.moveFieldOnLayout(addr);
      }
    }
  }
  // 
  // value changes
  //
  handleValueChange(event) {
    try {
      let inputDiv = this.template.querySelector(`div[data-id="${event.currentTarget.dataset.id}"]`)
      let addr = {
        [FROM_SECTION_INDEX]: inputDiv.dataset.sectionIndex,
        [FROM_COLUMN_INDEX]: inputDiv.dataset.columnIndex,
        [FROM_FIELD_INDEX]: inputDiv.dataset.fieldIndex
      }

      let value = event.currentTarget.value;
      if (event.currentTarget.type == 'checkbox' || event.currentTarget.type == 'toggle'){
        value = event.currentTarget.checked;
      }

      this.props.setFieldValue(addr, value);
      console.log('changed value : ' + value);
    } catch(error){
      this.err(error);
    }
  }

  async handleFieldEditModal(event){
    let field = 
      this.props.layout[event.currentTarget.dataset.sectionIndex]
      .columns[event.currentTarget.dataset.columnIndex]
      .fields[event.currentTarget.dataset.fieldIndex];

    let address = {
      [FROM_SECTION_INDEX]: event.currentTarget.dataset.sectionIndex,
      [FROM_COLUMN_INDEX]: event.currentTarget.dataset.columnIndex,
      [FROM_FIELD_INDEX]: event.currentTarget.dataset.fieldIndex,
      [FROM_FIELD_NAME]: event.currentTarget.dataset.id
    }

    console.log('address : ' + JSON.stringify(address));
    await FieldEditModal.open({ 
      size: 'small',
      field: field,
      objectApiName: this.objectApiName
    })
    .then(returnData => { 
      console.log('ReturnData : ' + JSON.stringify(returnData));
      if (!!returnData){
        if (returnData.REMOVE){
          this.props.removeFieldFromLayout(address);
        } else {
          this.props.updateField(address, returnData);
        }
      }
    })
    .catch(error => this.err(error));
  }
}