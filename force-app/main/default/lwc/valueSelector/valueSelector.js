import { LightningElement, api } from 'lwc';
import getFieldValues from '@salesforce/apex/SchemaUtil.getFieldValues';
export default class ValueSelector extends LightningElement {
    @api
    selectedFieldType;

    @api
    fieldName;

    @api
    value;

    @api
    objectApiName;

    picklistOptions;

    connectedCallback() {
        if (this.objectApiName && this.fieldName && this.isPicklistField) {
            getFieldValues({ objectName: this.objectApiName, fieldName: this.fieldName }).then(values => {
                this.picklistOptions = values.map(value => ({ label: value, value: value }));
            });
        }
    }

    get isDefault(){
        return !(this.isBooleanField || this.isDateField || this.isNumberField || this.isPicklistField || this.isTextArea || this.isTextField);
    }

    get label(){
        return 'Enter Value for '+ this.fieldName;
    }


    get isTextField() {
        return this.selectedFieldType === 'STRING';
    }

    get isTextArea(){
        return this.selectedFieldType == 'TEXTAREA'
    }

    get isNumberField() {
        return this.selectedFieldType === 'DOUBLE' || this.selectedFieldType === 'INTEGER' || this.selectedFieldType === 'CURRENCY' ||  this.selectedFieldType === 'PERCENT';
    }

    get isDateField() {
        return this.selectedFieldType === 'DATE' || this.selectedFieldType === 'DATETIME';
    }

    get isPicklistField() {
        return this.selectedFieldType === 'PICKLIST';
    }

    get isBooleanField() {
        return this.selectedFieldType === 'BOOLEAN';
    }

    handleFieldValueChange(event){
        this.value = event.target.value;
    }

}