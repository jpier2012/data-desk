import { 
    INITIALIZE, 
    ADD_FIELD_TO_LAYOUT, MOVE_FIELD_ON_LAYOUT, REMOVE_FIELD_FROM_LAYOUT,
    ADD_NEW_SECTION, MOVE_SECTION, REMOVE_SECTION, EDIT_SECTION_PROPERTIES, 
    SET_FIELD_VALUE, UPDATE_TEMPLATE, EDIT_FIELD_PROPERTIES, FILTER_FIELDS, TOGGLE_FIELD_SELECTION, 
    BUTTON_CLASS, 

    FROM_SECTION_INDEX, FROM_COLUMN_INDEX, FROM_ROW_INDEX, FROM_FIELD_INDEX, FROM_FIELD_NAME, 
    TO_SECTION_INDEX, TO_COLUMN_INDEX, TO_ROW_INDEX, TO_FIELD_INDEX, NEW_INDEX, 

    toggleHighlight, getInputTypeObject, getFieldParams
} from 'c/ddUtil';

const initialState = { template: {}, layout: [], allFields: [] };

const reducer = (state = initialState, action) => {   
    let temp;
    let allFields;
    let layout;
    let selectedField;
    let sourceFields;
    let targetFields;
    let addr;
    try {
        switch (action.type) {
////////////////  
            case INITIALIZE: 
                let layoutJson = action.payload.layoutJson;
                allFields = action.payload.allFields;
                layout = [];
                let layoutFields = {};
                let defaultSection;

                if (!!layoutJson){
                    layout = JSON.parse(layoutJson)

                    layout.forEach(section => {
                        section.columns.forEach(column => {
                            column.fields.forEach(field => {
                                layoutFields[field.apiName] = true;
                            });
                        });
                    });
                } else {
                    defaultSection = { 
                        name: 'Default Fields', isDefault: true, columnCount: 2, index: 0, rows: [], columns: [],
                        description: 'This is a default section created for new templates. Click the gear icon to edit...'
                    };

                    for (let c = 0; c < defaultSection.columnCount; c++){
                        defaultSection.columns[c] = { index: c, fields: [] };
                    }
                }

                let counter = 0;
                allFields = allFields.map(field => {

                    field.inputType = getInputTypeObject(field.dataType);
                    field.isDraggable = true;
                    field.buttonClasses = BUTTON_CLASS;
                    
                    if (field.inputType.checkbox){
                        field.defaultValue = (field.defaultValue == 'true' || field.defaultValue == true);
                    }
                        
                    field.show = true;

                    if (field.isRequired == true || layoutFields[field.apiName]){

                        if (!!defaultSection){
                            let rowIndex = defaultSection.rows.length;
                            let colNbr = counter % defaultSection.columnCount;
                            defaultSection.columns[colNbr].fields.push(getFieldParams(field));
                            if (colNbr == 0){}
                                // defaultSection.rows[rowIndex] = [];

                            // defaultSection.rows[rowIndex].push(getFieldParams(field));
                            counter++;
                        }

                        toggleHighlight(field);
                    }
        
                    return field;
                });

                layout = !!defaultSection ? [ defaultSection ] : layout;

                return { ...state, template: action.payload.template, layout: layout, allFields: allFields };
////////////////    
            case ADD_FIELD_TO_LAYOUT: 
                addr = action.payload.address;

                if (addr[FROM_FIELD_NAME] == 'filler'){
                    selectedField = {
                        apiName: 'filler' + addr[NEW_INDEX],
                        isFiller: true,
                        description: 'Placeholder'
                    };
                } else {
                    temp = state.allFields.map(field => { 
                        if (field.apiName == addr[FROM_FIELD_NAME]){
                            selectedField = getFieldParams(field);
                            toggleHighlight(field);
                        }
                        return field;
                    });
                }

                let tempLayout = [ ...state.layout ];
                targetFields = tempLayout[addr[TO_SECTION_INDEX]]
                    .columns[addr[TO_COLUMN_INDEX]]
                    .fields;

                tempLayout[addr[TO_SECTION_INDEX]].columns[addr[TO_COLUMN_INDEX]].fields = [ 
                    ...targetFields.slice(0, addr[NEW_INDEX]), 
                    selectedField, 
                    ...targetFields.slice(addr[NEW_INDEX]) 
                ];

                let obj = { ...state, layout: tempLayout };

                if (temp)
                    obj.allFields = temp;
                
                return obj;
////////////////
            case MOVE_FIELD_ON_LAYOUT: 
                addr = action.payload.address;
                layout = [ ...state.layout ];

                sourceFields = layout[addr[FROM_SECTION_INDEX]].columns[addr[FROM_COLUMN_INDEX]].fields;    
                selectedField = sourceFields[addr[FROM_FIELD_INDEX]];

                let newIndex = addr[NEW_INDEX];
                let isSameColumn = `${addr[FROM_SECTION_INDEX]}${addr[FROM_COLUMN_INDEX]}` == `${addr[TO_SECTION_INDEX]}${addr[TO_COLUMN_INDEX]}`; 
                if (isSameColumn){
                    targetFields = sourceFields.filter(field => field.apiName != addr[FROM_FIELD_NAME]);
                    newIndex = addr[TO_FIELD_INDEX] > addr[FROM_FIELD_INDEX] ? Number(newIndex) - 1 : newIndex;
                } else {
                    targetFields = layout[addr[TO_SECTION_INDEX]].columns[addr[TO_COLUMN_INDEX]].fields;
                }

                layout[addr[TO_SECTION_INDEX]].columns[addr[TO_COLUMN_INDEX]].fields = [ ...targetFields.slice(0, newIndex), selectedField, ...targetFields.slice(newIndex)];
                
                if (!isSameColumn)
                    layout[addr[FROM_SECTION_INDEX]].columns[addr[FROM_COLUMN_INDEX]].fields = sourceFields.filter(field => field.apiName != addr[FROM_FIELD_NAME]);
        
                return { ...state, layout: layout };
////////////////
            case REMOVE_FIELD_FROM_LAYOUT: 
                addr = action.payload.address;
                layout = [ ...state.layout ];
                
                targetFields = layout[addr[FROM_SECTION_INDEX]]
                    .columns[addr[FROM_COLUMN_INDEX]]
                    .fields
                    .filter((field) => field.apiName != addr[FROM_FIELD_NAME]);

                layout[addr[FROM_SECTION_INDEX]]
                    .columns[addr[FROM_COLUMN_INDEX]]
                    .fields = targetFields;
                temp = state.allFields.map((field) => { 
                    if (field.apiName == addr[FROM_FIELD_NAME])
                        toggleHighlight(field);

                    return field;
                });

                return { ...state, layout: layout, allFields: temp };
////////////////
            case ADD_NEW_SECTION: 
                return {
                    ...state,
                    layout: [ 
                        ...state.layout, 
                        { 
                            name: `New Section ${state.layout.length}`, 
                            index: state.layout.length, 
                            columnCount: 2, 
                            columns: [ { index: 0, fields: [] }, { index: 1, fields: [] } ] 
                        } 
                    ]
                };
////////////////
            case REMOVE_SECTION: 
                let idx = action.payload.address[FROM_SECTION_INDEX];
                let fields = {};
                layout = [];
                
                state.layout[idx].columns.forEach(column => {
                    column.fields.forEach(field => {
                        if (field.isRequired)
                            throw new Error('Remove the required field(s) from this section in order to remove it.');

                        fields[field.apiName] = true;
                    })
                });

                state.layout.forEach(section => {
                    if (section.index != idx){
                        layout.push(section);
                        layout[layout.length - 1].index = layout.length - 1;
                    }
                });

                temp = state.allFields.map(field => {
                    if (fields[field.apiName])
                        toggleHighlight(field);

                    return field;
                })

                return { ...state, layout: layout, allFields: temp };

////////////////
            case MOVE_SECTION: 
                layout = state.layout;
                addr = action.payload.address;
                return { ...state };
////////////////
            case TOGGLE_FIELD_SELECTION: 
                temp = state.allFields.map(field => { 
                    return field.apiName == action.payload.fieldApiName ? toggleHighlight(field) : field;
                });

                return {  ...state, allFields: temp };
////////////////
            case SET_FIELD_VALUE: 
                addr = action.payload.address;
                layout = [ ...state.layout ];

                layout[addr[FROM_SECTION_INDEX]]
                    .columns[addr[FROM_COLUMN_INDEX]]
                    .fields[addr[FROM_FIELD_INDEX]]
                    .currentValue = action.payload.value;

                return { ...state, layout: layout }
////////////////
            case UPDATE_TEMPLATE: 
                return { ...state, template: { ...action.payload.template } }
////////////////
            case EDIT_SECTION_PROPERTIES: 
                let section = action.payload.section;
                layout = [ ...state.layout ];
                layout[section.index] = section;
                return { ...state, layout: layout  }
////////////////
            case EDIT_FIELD_PROPERTIES: 
                addr = action.payload.address;
                layout = [ ...state.layout ];
                let field = layout[addr[FROM_SECTION_INDEX]]
                    .columns[addr[FROM_COLUMN_INDEX]]
                    .fields[addr[FROM_FIELD_INDEX]];

                let vals = action.payload.fieldData?.values;
                let query = action.payload.fieldData?.query;

                temp = {
                    ...field,
                    ...action.payload.fieldData
                }

                temp.query = query ? { ...action.payload.fieldData?.query } : {};
                temp.values = vals ? [ ...vals ] : []

                layout[addr[FROM_SECTION_INDEX]]
                    .columns[addr[FROM_COLUMN_INDEX]]
                    .fields[addr[FROM_FIELD_INDEX]] = temp;

                return { ...state, layout: layout  }
////////////////      
            case FILTER_FIELDS: 
                let criteria = action.payload.criteria;
                temp = [ ...state.allFields ];
                
                temp.forEach(field => {
                    if ((field.label + '_' + field.apiName + '_' + field.dataType).toLowerCase().includes(criteria.toLowerCase()) || !!!criteria){
                        field.show = true;
                    } else {
                        field.show = false;
                    }
                    });

                return {  ...state, allFields: temp };
            
            default: return state;
        }
    } catch(error){
        console.log('Reducer error : ' + JSON.stringify(error?.message));
    }
}

export default reducer;