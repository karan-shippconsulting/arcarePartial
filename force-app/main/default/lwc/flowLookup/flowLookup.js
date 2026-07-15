import { LightningElement, api, track, wire } from 'lwc';
import searchRecords from '@salesforce/apex/FlowLookupController.searchRecords';

export default class FlowLookup extends LightningElement {
    // Inputs
    @api objectApiName;
    @api fieldApiName;
    @api operator = 'Contains';
    @api searchValue;
    @api displayFieldApiName = 'Name';
    @api label = 'Select Record';

    // Outputs
    @api value;               // Selected record Id
    @api displayNameOutput;   // Selected display field value

    @track options = [];

    @wire(searchRecords, {
        objectApiName: '$objectApiName',
        fieldApiName: '$fieldApiName',
        operator: '$operator',
        searchValue: '$searchValue',
        displayFieldApiName: '$displayFieldApiName'
    })
    wiredRecords({ error, data }) {
        if (data) {
            this.options = data.map(rec => ({
                label: rec.Label,
                value: rec.Id
            }));

            // If current value is no longer valid, clear both outputs
            if (this.value && !this.options.some(o => o.value === this.value)) {
                this.value = undefined;
                this.displayNameOutput = undefined;
            }
        } else if (error) {
            this.options = [];
            // eslint-disable-next-line no-console
            console.error('Lookup error: ' + JSON.stringify(error));
        }
    }

    handleChange(event) {
        this.value = event.detail.value;

        // Find the selected record's label to output as well
        const selectedOption = this.options.find(o => o.value === this.value);
        this.displayNameOutput = selectedOption ? selectedOption.label : undefined;
    }

    // Flow validation hook
    @api required = false;
    @api validate() {
        if (this.required && !this.value) {
            return { isValid: false, errorMessage: 'Please select a record.' };
        }
        return { isValid: true };
    }
}