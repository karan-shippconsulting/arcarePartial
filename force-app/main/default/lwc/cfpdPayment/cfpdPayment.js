import { LightningElement, api, track } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import BATCH_PAYMENT from '@salesforce/schema/Batch_Payment__c';
import getOpportunities from '@salesforce/apex/ArcarePaymentController.getOpportunities';
import updateOpportunities from '@salesforce/apex/ArcarePaymentController.updateOpportunities';
import getPeriods from '@salesforce/apex/ArcarePaymentController.getPeriods';
import getServiceType from '@salesforce/apex/ArcarePaymentController.getServiceType';
import getBatchPayment from '@salesforce/apex/ArcarePaymentController.getBatchPayment';
import getTrustPortfolio from '@salesforce/apex/ArcarePaymentController.getTrustPortfolio';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class CfpdPayment extends NavigationMixin(LightningElement) {
    @api recordId;
    @track listOfOpp = [];
    @track seletedOppIds = []
    totalInvoicesSelected = 0;
    totalAmountSelected = 0;
    paymentAmount = 0;
    varianceAmount = 0;
    @track selectedOpp = []
    status = 'Open';
    amountFilter
    unselectedOnly = false;
    selectedFilter = 'Selected';
    filterOptions = [
        { label: 'All', value: 'All' },
        { label: 'Selected Items', value: 'Selected' },
        { label: 'Unselected Items', value: 'Unselected' }
    ];

    periodOptions = [];
    serviceTypeOptions = [];
    trustPortfolioOptions = [];
    serviceType;
    trustPortfolio;
    period;
    isTableLoaded = false;
    isFormLoaded = false;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;
    currentPage = 0;
    perPageLimit = 20;
    seletedOppIdsSet = new Set();
    preSeletedOppIds = []
    setOfDeseletedOpp = new Set();
    recordTitle
    isNew = true;
    columns = [
        { label: 'Invoice Name', fieldName: 'Name', sortable: true },
        { label: 'Service Enrollment', fieldName: 'ServiceEnrollment', sortable: true },
        { label: 'Date', fieldName: 'Bill_Date__c', sortable: true },
        { label: 'Amount', fieldName: 'Amount', type: 'currency', sortable: true },
        { label: 'Period', fieldName: 'PeriodName', sortable: true },
    ];

    get isBatchSynced() {
        return this.status === 'Synced';
    }

    get isApproveBatchEnabled() {
        return this.varianceAmount === 0 && this.paymentAmount != 0
    }

    get isLoaded() {
        return this.isTableLoaded && this.isFormLoaded
    }

    get isPreviousBtnEnabled() {
        return this.currentPage >= 1;
    }

    get isNextBtnEnabled() {
        return this.listOfOpp.length >= this.perPageLimit;
    }

    get displayOpportunities() {
        return (this.serviceType && this.period);
    }

    connectedCallback() {
        this.isNew = !this.recordId
        this.recordTitle = this.isNew ? "Create New Batch Payment" : "Edit Batch Payment"

        this.getOpportunitiesByFilters(true);
        if(this.isNew) {
            this.selectedFilter = 'All';
        } else {
            this.selectedFilter = 'Selected';
        }
        getPeriods().then(res => {
            for (let key in res) {
                this.periodOptions.push({label:res[key], value:key});
            }
            /*this.periodOptions = res.map(period => {
                return { label: period, value: period };
            })*/
            this.periodOptions = [{ label: 'None', value: null }, ...this.periodOptions]
        }).catch(err => this.showNotification("Something went wrong.", "", "error"))

        getServiceType().then(res => {
            this.serviceTypeOptions = res.map(serviceType => {
                return { label: serviceType, value: serviceType };
            })
            this.serviceTypeOptions = [{ label: 'None', value: null }, ...this.serviceTypeOptions]
        }).catch(err => this.showNotification("Something went wrong.", "", "error"))

        getTrustPortfolio().then(res => {
            for (let key in res) {
                this.trustPortfolioOptions.push({label:res[key], value:key});
            }
            //this.trustPortfolioOptions = res.map(trustPortfolio => {
              //  return { label: trustPortfolio.Name, value: trustPortfolio.Id };
            //})
            this.trustPortfolioOptions = [{ label: 'None', value: null }, ...this.trustPortfolioOptions]
        }).catch(err => this.showNotification("Something went wrong.", "", "error"))

        if(this.recordId) {
            getBatchPayment({recordId : this.recordId}).then(res => {
                this.trustPortfolio = res.Trust_Portfolio__c;
                this.period = res.Period__c;
                this.serviceType = res.Service_Type__c;
            }).catch(err => this.showNotification("Something went wrong.", "", "error"))
        }
    }

    getOpportunitiesByFilters() {
        this.isTableLoaded = false;
        let offset = this.currentPage * this.perPageLimit;
        let payload = {
            batchId: this.recordId,
            //unselectedOnly: this.unselectedOnly,
            selectedFilter: this.selectedFilter,
            period: this.period,
            serviceType: this.serviceType,
            trustPortfolio: this.trustPortfolio,
            offset
        }
        if (this.amountFilter) {
            payload.filterAmount = this.amountFilter
        }
        getOpportunities(payload).then(res => {
            this.listOfOpp = res.map(opp => {
                return { ...opp, PeriodName: opp.Period__r?.Name, ServiceEnrollment: opp.Service_Enrollment__r?.Name }
            })
            for (let opp of res) {
                if (opp.Payment_Batch__c && !this.setOfDeseletedOpp.has(opp.Id)) {
                    this.seletedOppIdsSet.add(opp.Id)
                }
            }
            this.preSeletedOppIds = [...this.seletedOppIdsSet]
        }).finally(() => {
            this.isTableLoaded = true
        })

    }

    get isDisabled() {
        console.log('isDisabled --' + this.seletedOppIdsSet.size);
        return this.seletedOppIdsSet.size > 0;
    }

    handleOnChange(event) {
        let eventName = event.target.name
        this[eventName] = event.target.value;
        this.varianceAmount = this.paymentAmount - this.totalAmountSelected;
    }
    handleOnLoad(event) {
        this.isFormLoaded = true;
        if (this.recordId) {
            var records = event.detail.records;
            var fields = records[this.recordId].fields
            this.paymentAmount = fields.Payment_Amount__c.value || 0;
            this.varianceAmount = fields.Variance_Amount__c.value || 0;
            this.totalInvoicesSelected = fields.Total_Invoices_Selected__c.value || 0;
            this.totalAmountSelected = fields.Total_Amount_Selected__c.value || 0;
            //this.status = fields.Status__c.value
        }
    }
    getSelectedBatch(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedOpp[this.currentPage] = [...selectedRows];
        let action = event.detail.config.action;
        let seletedId = event.detail.config.value;
        if (action === 'rowDeselect') {
            this.seletedOppIdsSet.delete(seletedId)
            let deseletedOpp = this.listOfOpp.find(opp => opp.Id === seletedId)
            this.totalAmountSelected -= (deseletedOpp?.Amount) ? deseletedOpp.Amount : 0;
            this.totalInvoicesSelected--;
            this.setOfDeseletedOpp.add(seletedId)

        } else if (action === 'deselectAllRows') {
            this.seletedOppIdsSet.forEach(seletedOppId => {
                let deseletedOpp = this.listOfOpp.find(opp => opp.Id === seletedOppId)
                this.totalAmountSelected -= (deseletedOpp?.Amount) ? deseletedOpp.Amount : 0;
                if (deseletedOpp) {
                    this.setOfDeseletedOpp.add(deseletedOpp.Id);
                    this.totalInvoicesSelected--;
                    this.seletedOppIdsSet.delete(deseletedOpp.Id);

                }
            })
        } else if (action === 'rowSelect') {
            let seletedOpp = this.listOfOpp.find(opp => opp.Id === seletedId)
            this.totalAmountSelected += (seletedOpp?.Amount) ? seletedOpp.Amount : 0;
            this.totalInvoicesSelected++;
            this.seletedOppIdsSet.add(seletedId);
            this.setOfDeseletedOpp.delete(seletedId)

        }
        else if (action === 'selectAllRows') {
            this.listOfOpp.forEach(seletedOpp => {
                if (!this.seletedOppIdsSet.has(seletedOpp.Id)) {
                    this.totalAmountSelected += (seletedOpp?.Amount) ? seletedOpp.Amount : 0;
                    this.totalInvoicesSelected++;
                    this.seletedOppIdsSet.add(seletedOpp.Id);
                    this.setOfDeseletedOpp.delete(seletedOpp.Id);
                }

            })
        }
        this.varianceAmount = this.paymentAmount - this.totalAmountSelected;
    }
    handleSuccess(event) {
        this.recordId = event.detail.id;
        let allSeletedOpp = [...this.seletedOppIdsSet].map(id => {
            return { Id: id, Payment_Batch__c: this.recordId }
        })
        this.setOfDeseletedOpp.forEach(preSeletedId => {
            let deselectedOpp = [...this.seletedOppIdsSet].find(id => preSeletedId == id)
            if (!deselectedOpp) {
                allSeletedOpp.push({ Id: preSeletedId, Payment_Batch__c: null })
            }
        })
        updateOpportunities({ opportunities: allSeletedOpp }).then(res => {
            if (this.isNew)
                this.showNotification("Success!", "Batch Payment Created.", "success")
            else
                this.showNotification("Success!", "Batch Payment Updated.", "success")
        })
            .catch(err => this.showNotification("Failed!", "Something went wrong.", "error"))
            .finally(() => {
                this.isFormLoaded = true
            })
    }

    handleSave() {
        this.isFormLoaded = false;
        console.log('this.trustPortfolio -- ' + this.trustPortfolio);
        console.log('this.period -- ' + this.period);
        console.log('this.serviceType -- ' + this.serviceType);
        const submitBtn = this.template.querySelector('.hidden-submit-button');
        if (submitBtn) {
            submitBtn.click();
        } else {
            console.error('Submit button not found');
        }
    }

    handleSubmit(event) {
        event.preventDefault();  // stop the form's default submit

        const fields = event.detail.fields;
        console.log('fields: ' + fields);
        // Add your default values or override existing ones
        fields.Trust_Portfolio__c = this.trustPortfolio;
        fields.Period__c = this.period;
        fields.Service_Type__c = this.serviceType;
        //fields.Service_Enrollment__c = this.serviceType;

        // Now submit the form with modified fields
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSaveAndReturn() {
        this.isFormLoaded = false;
        this.template.querySelector('lightning-record-edit-form').submit();
        this.handleListViewNavigation();
    }

    handleApproveBatch() {
        this.status = 'Approved';
        this.showNotification("Batch Approved!", "", "success");
        this.isFormLoaded = false;
        this.template.querySelector('lightning-record-edit-form').submit();
    }
    /*handleUnselectedItems() {
        this.unselectedOnly = !this.unselectedOnly
        this.currentPage = 0;
        this.getOpportunitiesByFilters()

    }*/

    handleFilterChange(event) {
        this.selectedFilter = event.detail.value;
        this.currentPage = 0;
        this.getOpportunitiesByFilters();
    }

    handleAmountFilterChange(event) {
        if ((event.key === "Enter")) {
            this.amountFilter = event.target.value;
            this.currentPage = 0;
            this.getOpportunitiesByFilters()
        }
    }
    handlePeriodChange(event) {
        this.period = event.detail.value;
        this.currentPage = 0;
        this.getOpportunitiesByFilters()
    }
    handleServiceTypeChange(event) {
        this.serviceType = event.detail.value;
        this.currentPage = 0;
        this.getOpportunitiesByFilters()
    }
    handleTrustPortfolioChange(event) {
        this.trustPortfolio = event.detail.value;
        this.currentPage = 0;
        this.getOpportunitiesByFilters()
    }
    handlePrivous() {
        this.currentPage--;
        this.getOpportunitiesByFilters()

    }
    handleNext() {
        this.currentPage++;
        this.getOpportunitiesByFilters()
    }
    setPreSeletedOpp() {
        this.seletedOppIds = this.selectedOpp[this.currentPage]?.map(opp => {
            return opp.Id
        })
    }
    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.listOfOpp];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.listOfOpp = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                return primer(x[field]);
            }
            : function (x) {
                return x[field];
            };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }
    handleListViewNavigation() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Batch_Payment__c',
                actionName: 'view'
            }
        });
    }
    showNotification(titleText, messageText, variant) {
        const evt = new ShowToastEvent({
            title: titleText,
            message: messageText,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}