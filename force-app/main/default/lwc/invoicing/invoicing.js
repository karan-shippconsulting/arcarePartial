import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import checkPermission from '@salesforce/apex/InvoicingBatchUtil.checkAccess';
import getPeriodValues from '@salesforce/apex/InvoicingBatchUtil.getPeriodValues';
import runBatch from '@salesforce/apex/InvoicingBatchUtil.runBatch';
export default class Invoicing extends NavigationMixin(LightningElement) {
    hasAccess = false;
    isLoading = true;

    selectedPeriod;

    picklistOptions = [];

    async connectedCallback() {
        getPeriodValues().then(results => {
            this.picklistOptions = results?.map(result => ({ label: result.Name, value: result.Id })) || [];
            console.log(JSON.stringify(this.picklistOptions));
        });
        this.hasAccess = await checkPermission();
        this.isLoading = false;
    }

    handlePeriodChange(event){
        this.selectedPeriod = event.target.value;
    }

    async handleRun(event) {
        if(this.selectedPeriod){
            this.isLoading = true;
            await runBatch({periodId:this.selectedPeriod});
            this.isLoading = false;
            this.handleCancel(event);
        }
    }

    handleCancel(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Contact',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            },
        });
    }
}