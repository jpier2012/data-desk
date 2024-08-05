import { LightningElement, api } from 'lwc';
import { createStore, combineReducers, createLogger } from 'c/lwcRedux';
import reducer from 'c/ddReducers';

// Set ENABLE_LOGGING true if you wanna use the logger.
// We prefer to use the Custom label because we can directly access in the LWC components.
const ENABLE_LOGGING = false;

export default class DataDeskApp extends LightningElement {
    @api store;
    initialize(){
        document.body.setAttribute('style', 'overflow: hidden;');
        let logger;
        
        // Check for the Logging
        if(ENABLE_LOGGING){
            logger = createLogger({
                duration: true,
                diff: true
            });
        }
        try {
            this.store = createStore(reducer, logger);
        } catch(error){
            console.log(error.message);
        }
    }
}