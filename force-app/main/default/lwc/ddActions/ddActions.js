import { 
    INITIALIZE,
    FILTER_FIELDS,
    ADD_FIELD_TO_LAYOUT,
    MOVE_FIELD_ON_LAYOUT,
    REMOVE_FIELD_FROM_LAYOUT,
    ADD_NEW_SECTION, 
    REMOVE_SECTION, 
    SET_FIELD_VALUE, 
    UPDATE_TEMPLATE, 
    EDIT_SECTION_PROPERTIES,  
    EDIT_FIELD_PROPERTIES, 
    TOGGLE_FIELD_SELECTION
  } from 'c/ddUtil';
  
  export const initialize = (layoutJson, template, allFields) => ({ 
    type: INITIALIZE, 
    payload: { layoutJson: layoutJson, template: template, allFields: allFields }
  });

  //
  // template
  //
  export const updateTemplate = (template) => ({ type: UPDATE_TEMPLATE, payload: { template: template } })
  
  //
  // layout
  //
  
  // section
  export const addNewSection = () => ({ type: ADD_NEW_SECTION });  
  export const updateSection = (section) => ({ type: EDIT_SECTION_PROPERTIES, payload: { section: section } })
  export const removeSection = (addressObj) => ({ type: REMOVE_SECTION, payload: { address: addressObj }});

  // field
  export const addFieldToLayout = (addressObj) => ({ type: ADD_FIELD_TO_LAYOUT, payload: { address: addressObj }});
  export const moveFieldOnLayout = (addressObj) => ({ type: MOVE_FIELD_ON_LAYOUT, payload: { address: addressObj }});
  export const removeFieldFromLayout = (addressObj) => ({ type: REMOVE_FIELD_FROM_LAYOUT, payload: { address: addressObj }});
    
  export const setFieldValue = (addressObj, value) => ({ type: SET_FIELD_VALUE, payload: { address: addressObj, value: value } });
  export const updateField = (addressObj, fieldData) => ({ type: EDIT_FIELD_PROPERTIES, payload: { address: addressObj, fieldData: fieldData } })

  //
  // all fields
  //
  export const filterFields = (criteria) => ({ type: FILTER_FIELDS, payload: { criteria: criteria } });
  export const toggleFieldSelection = (fieldApiName) => ({ type: TOGGLE_FIELD_SELECTION, payload: { fieldApiName: fieldApiName } });