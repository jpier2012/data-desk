import { api } from "lwc";
import { ReduxElement } from 'c/lwcRedux';
import { FROM_SECTION_INDEX, FROM_COLUMN_INDEX, FROM_FIELD_INDEX, FROM_FIELD_NAME, err } from 'c/ddUtil';
import { setFieldValue, updateField } from 'c/ddActions';
import FieldEditModal from 'c/fieldEditModal'
export default class Layout extends ReduxElement {
  @api field
  @api objectApiName;
  @api sectionIndex;
  @api columnIndex;
  @api fieldIndex;

  isLoading = true;

  constructor(props){ super(); this.err = err.bind(this); }

  mapDispatchToProps(){
    return { 
      setFieldValue: setFieldValue,
      updateField: updateField
    };
  }

  connectedCallback(){
    super.connectRedux();
    console.log("FieldCell connected : " + this.field.apiName);
    this.isLoading = false;
  }

  // 
  // value changes
  //
  handleValueChange(event) {
    try {
      let addr = {
        [FROM_SECTION_INDEX]: this.sectionIndex,
        [FROM_COLUMN_INDEX]: this.columnIndex,
        [FROM_FIELD_INDEX]: this.fieldIndex
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
    let address = {
      [FROM_SECTION_INDEX]: this.sectionIndex,
      [FROM_COLUMN_INDEX]: this.columnIndex,
      [FROM_FIELD_INDEX]: this.fieldIndex,
      [FROM_FIELD_NAME]: this.field.apiName
    }

    console.log('address : ' + JSON.stringify(address));
    await FieldEditModal.open({ 
      size: 'small',
      field: this.field,
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