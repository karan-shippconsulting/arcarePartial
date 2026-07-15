import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
export default class RedirectButton extends LightningElement {
    @api recordId; // The recordId is passed from the page context
    url;
    @api objectApiName;

    // Dynamically constructing the field names after fetching object metadata
    get dynamicFieldName() {
        if (this.objectApiName) {
            return [`${this.objectApiName}.review_url__c`];
        }
        return []; // return an empty string if object is not yet loaded
    }

    // Wire the getRecord method to retrieve the record data dynamically based on the object
    @wire(getRecord, { recordId: '$recordId', fields: '$dynamicFieldName' })
    record;

    

    handleRedirect() {
        // Check if the URL field is populated in the record
        if (this.record.data) {
            this.url = this.record.data.fields.review_url__c.value;
            if (this.url) {
                window.open(this.url, '_blank'); // Redirect to the URL
            } else {
                alert('URL field is empty!');
            }
        }
    }
}