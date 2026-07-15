import { LightningElement, api, track } from 'lwc';
import queryCreatedRecords from '@salesforce/apex/DocsumoFlowRecordQueryController.queryCreatedRecords';

export default class DocsumoRecordTable extends LightningElement {
    @api objRecordIds;

    @track records = [];
    @track columns = [];
    error;

    connectedCallback() {
        // Ensure we have recordIds before making the query
        if (this.objRecordIds && this.objRecordIds.length > 0) {
            this.fetchRecords();
        }
    }

    fetchRecords() {
        queryCreatedRecords({ recIds: this.objRecordIds })
            .then((result) => {
                // Get records and field names from the result
                let fieldNames = result.fields;

                this.records = result.records.map((record) => {
                    let recordLink = "/" + record.Id;
                    let recordName = record.Name;
                    return {
                        ...record, 
                        recordLink: recordLink,
                        recordName: recordName
                    }
                });
                // Dynamically create columns based on field names
                this.columns = fieldNames.map((field, index) => {
                    if (field === 'Name') {
                        // Create a clickable link for the Id field
                        return {
                            label: "Name",
                            fieldName: "recordLink",
                            type: 'url',
                            typeAttributes: {
                                label: { fieldName: "recordName" },
                                target: '_blank'
                            }
                        };
                    } else if (index === fieldNames.length - 1) {
                        // URL field, create a clickable link
                        return {
                            label: field,
                            fieldName: field,
                            type: 'url',
                            typeAttributes: {
                                label: { fieldName: field },
                                target: '_blank'
                            }
                        };
                    } else {
                        // Other fields, show them as text
                        return {
                            label: field,
                            fieldName: field
                        };
                    }
                });                
            })
            .catch((error) => {
                this.error = error;
                this.records = [];
            });            
    }
}