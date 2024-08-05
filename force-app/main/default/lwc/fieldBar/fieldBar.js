import { ReduxElement } from "c/lwcRedux";
import { filterFields } from 'c/ddActions';
import { resize, FROM_FIELD_NAME } from 'c/ddUtil';

export default class FieldBar extends ReduxElement {

  innerHeight;

  isLoading = true;

  constructor(props){
    super();
    this.resize = resize.bind(this);
  }

  mapStateToProps(state){
    console.log("FieldBar mapStateToProps");
    return { 
      allFields: state.allFields
    }
  }

  mapDispatchToProps(){
    return { 
      filterFields: filterFields
    }
  }

  connectedCallback(){
    try {
        super.connectRedux();
    } catch(e){
        console.log(e.message);
    }
    window.addEventListener('resize', this.resize);

    this.isLoading = false;
    console.log("FieldBar redux connected");
  }

  timeoutId;
  searchLoading = false;
  handleSearchChange(event){
    this.searchLoading = true;
    try {
      let val = event.currentTarget?.value?.toLowerCase();
      if (!!!val){
        this.props.filterFields('');
      } else {
        clearTimeout(this.timeoutId); 
        this.timeoutId = setTimeout(
        () => {
          this.props.filterFields(val);
        },
        750);
      }
    } catch(error){
      this.props.filterFields('');
      console.log("handleSearchChange error : " + error.message);
    }
    this.searchLoading = false;
  }

  handleDragStart(event) {
    event.dataTransfer.setData(FROM_FIELD_NAME, event.currentTarget.dataset.id);
  }

  renderedCallback(){
    this.resize();
  }
}