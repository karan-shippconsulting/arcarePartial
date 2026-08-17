import { LightningElement, api } from 'lwc';
import updateAccountBalance from '@salesforce/apex/TrueLinkApiHandler.updateAccountBalance';
import updateDeposit from '@salesforce/apex/TrueLinkApiHandler.updateDeposit';
import updateDisbursement from '@salesforce/apex/TrueLinkApiHandler.updateDisbursement';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class UpdateBalance extends NavigationMixin(LightningElement) {
    isExecuting = false;

    _recordId;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(recordId) {
        if (recordId !== this._recordId) {
            this._recordId = recordId;
        }
    }
    @api async invoke() {
        if (this.isExecuting)
            return;

        this.isExecuting = true;
        try {
            updateAccountBalance({ trustId: this.recordId });
            updateDeposit({ trustId: this.recordId });
            updateDisbursement({ trustId: this.recordId });
            const event = new ShowToastEvent({
                title: 'Success',
                message: 'Balance Updated!',
                variant: 'success'
            });
            this.dispatchEvent(event);
            await this.sleep(500);
            // this[NavigationMixin.Navigate]({
            //     type: 'standard__recordPage',
            //     attributes: {
            //         recordId: this.recordId,
            //         objectApiName: 'Account',
            //         actionName: 'view'
            //     }
            // });
            location.reload();
         
        }
        catch (err) {
            console.log(err);
            const event = new ShowToastEvent({
                title: 'Error!',
                message: err.body.message,
                variant: 'error'
            });
            this.dispatchEvent(event);
        }
        finally {
            this.isExecuting = false;

        }
    }
    sleep(ms) {
        return new Promise((resolve) => setTimeout(resolve, ms));
    }
}