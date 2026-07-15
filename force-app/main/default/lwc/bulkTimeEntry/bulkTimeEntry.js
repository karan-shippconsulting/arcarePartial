import { LightningElement, wire, track } from 'lwc';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import Name from '@salesforce/schema/User.Name';
import TIMECATPICLIST from "@salesforce/schema/Time_Entry__c.Time_Entry_Category__c";
import HOURSPICLIST from "@salesforce/schema/Time_Entry__c.Hours__c";
import MINSPICLIST from "@salesforce/schema/Time_Entry__c.Minutes__c";
import getClients from '@salesforce/apex/BulkTimeEntryUtils.getClients';
import getServiceEntollment from '@salesforce/apex/BulkTimeEntryUtils.getServiceEntollment';
import getBillingCode from '@salesforce/apex/BulkTimeEntryUtils.getBillingCode';
import getUnitPrice from '@salesforce/apex/BulkTimeEntryUtils.getUnitPrice';
import getCharges from '@salesforce/apex/BulkTimeEntryUtils.getCharges';
import { getRecord, createRecord, updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import styles from '@salesforce/resourceUrl/resetDateHint';
import Id from '@salesforce/user/Id';



export default class bulkTimeEntry extends LightningElement {

    @track filterProps = {
        "clientName": "",
        "starteDate": "",
        "endDate": "",
        "billable": 'All',
        "category": 'ALL',
        "createdBy": ""
    }


    timeCategoryOptions;
    hoursOptions;
    isRendered = false;
    minsOptions;
    selectedTimeCategory;
    clientList;
    billingCodes = [];
    serviceEnrollmentList = [];
    disableStart = false;
    disableStop = true;
    unitPrice = 0;
    displayHours = 0;
    @track chargesList = [];
    originalData = [];
    @track formattedTime = '00:00:00'; // Timer formatted as HH:MM:SS
    timerId;
    startTime;
    startTime;
    endTime;
    @track isEnableApproval;
    @track isEnableApprovalButton;

    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;
    periodSearch = 'THIS_WEEK';
    billableDefault = 'All';

    billableOptions = [{ label: 'All', value: 'All' }, { label: 'Show Billables', value: 'false' }, { label: 'Show Non-Billables', value: 'true' }];

    periodOptions = [
        { label: 'This Week', value: 'THIS_WEEK' },
        { label: 'This Month', value: 'THIS_MONTH' },
        { label: 'Today', value: 'TODAY' },
        { label: 'Last Month', value: 'LAST_MONTH' },
    ];

    categoryTypeOptions = [
        { label: 'All Categories', value: 'ALL' },
        { label: 'Client Related', value: 'HOURLY SERVICE;DIRECT EXPENSE;FEES' },
        { label: 'Administrative', value: 'ADMINISTRATIVE TIME' },
    ]

    handlePeriodChange(event) {
        this.periodSearch = event.target.value;
        this.getChargesList(() => {
            this.chargesList = JSON.parse(JSON.stringify(this.chargeFiltering()))
        });

    }


    startTimer(event) {
        this.startTime = new Date();
        this.disableStart = true;
        this.disableStop = false;
        this.timerId = setInterval(() => {
            this.updateTime();
        }, 1000);
    }

    updateTime() {
        const now = new Date();
        const elapsed = now - this.startTime;

        const hours = Math.floor((elapsed % 86400000) / 3600000);
        const minutes = Math.floor((elapsed % 3600000) / 60000);
        const seconds = Math.floor((elapsed % 60000) / 1000);

        this.formattedTime =
            this.pad(hours) + ':' +
            this.pad(minutes) + ':' +
            this.pad(seconds);
    }

    pad(number) {
        return number.toString().padStart(2, '0');
    }

    stopTimer(event) {
        this.endTime = new Date();
        this.disableStop = true;
        this.disableStart = false;
        clearInterval(this.timerId);
        this.calculateHoursAndMinutes();
    }

    calculateHoursAndMinutes() {
        if (!this.endTime)
            return;
        let diff = (this.endTime.getTime() - this.startTime.getTime()) / 1000;
        let mins = Math.abs(diff / 60);
        let hours = Math.abs(mins / 60);
        hours = hours >= 0 && hours <= 8 ? Math.floor(hours) : null;
        mins = hours != null ? mins - hours * 60 : mins;
        hours = this.hoursOptions.find(option => hours <= option.value)?.value;
        mins = this.minsOptions.find(option => mins <= option.value)?.value;
        this.refs.hours.value = hours;
        this.refs.minutes.value = mins;
        this.displayHours = (Number(hours * 60) + Number(mins)) / 60 || 0;
        console.log('hours: ', hours);
        console.log('mins: ', mins);
    }

    renderedCallback() {
        if (!this.isRendered) {
            console.log('Inside Rendered Callback');
            loadStyle(this, styles).then(() => console.log('Files loaded.')).catch(error => console.log("Error " + error.body.message));
            let modal = document.querySelectorAll(".slds-modal__container");
            if (modal[0]) modal[0].style.minWidth = "60rem";
            this.isRendered = true
        }
    }

    get today() {
        return this.selectedCharge?.Entry_Date__c ? new Date(this.selectedCharge.Entry_Date__c).toISOString() : new Date().toISOString();
    }

    filterByClient(event) {
        let searchBy = event.target.value;
        this.filterProps.clientName = searchBy;

        if ((searchBy && searchBy.length > 1) || this.filterProps.createdBy || this.filterProps.clientName || this.filterProps.starteDate || this.filterProps.endDate) {
            this.chargesList = JSON.parse(JSON.stringify(this.chargeFiltering())); //[...this.originalData?.filter(charge => charge.clientName.toLowerCase().includes(searchBy.toLowerCase()))];
        } else {
            this.chargesList = [...this.originalData];
        }
    }

    filterByCreated(event) {
        let searchBy = event.target.value;
        this.filterProps.createdBy = searchBy;

        if ((searchBy && searchBy.length > 1) || this.filterProps.createdBy || this.filterProps.clientName || this.filterProps.starteDate || this.filterProps.endDate) {
            this.chargesList = JSON.parse(JSON.stringify(this.chargeFiltering())); //[...this.originalData?.filter(charge => charge.clientName.toLowerCase().includes(searchBy.toLowerCase()))];
        } else {
            this.chargesList = [...this.originalData];
        }
    }

    chargeFiltering() {

        return [...this.originalData].filter(charge => {

            let isClientNameFind = true;
            let isStartDate = true;
            let isEndDate = true;
            let isBillable = true;
            let isCategory = true;
            let isCreatedUser = true;

            for (let key in this.filterProps) {
                if (key == "clientName" && this.filterProps[key]) {
                    isClientNameFind = charge.clientName.toLowerCase().includes(this.filterProps[key].toLowerCase());
                }
                else if (key == "createdBy" && this.filterProps[key]) {
                    isCreatedUser = charge.ownerName.toLowerCase().includes(this.filterProps[key].toLowerCase());
                } else if (key == "starteDate" && this.filterProps[key]) {
                    let d1 = new Date(charge.date);
                    let d2 = new Date(this.filterProps[key]);
                    isStartDate = d1.getTime() > d2.getTime();

                } else if (key == "endDate" && this.filterProps[key]) {
                    let d1 = new Date(charge.date);
                    let d2 = new Date(this.filterProps[key]);
                    isEndDate = d1.getTime() < d2.getTime();

                } else if (key == "billable" && this.filterProps[key]) {
                    isBillable = this.filterProps[key] == 'All' ? true : charge.billable == JSON.parse(this.filterProps[key])
                } else if (key == "category" && this.filterProps[key]) {
                    isCategory = this.filterProps[key] == 'ALL' ? true : this.filterProps[key].split(";").includes(charge.Time_Entry_Category__c);
                }
            }
            return isClientNameFind && isStartDate && isEndDate && isBillable && isCategory && isCreatedUser;
        })
    }

    filterByStartDate(event) {
        this.filterProps.starteDate = event.target.value;

        if (this.filterProps.createdBy || this.filterProps.clientName || this.filterProps.starteDate || this.filterProps.endDate) {
            this.chargesList = JSON.parse(JSON.stringify(this.chargeFiltering())); /*[...this.originalData?.filter(charge => {
                let d1 = new Date(charge.date);
                let d2 = new Date(event.target.value);
                return d1.getTime() > d2.getTime();
            })]; */
        } else {
            this.chargesList = [...this.originalData];
        }
    }

    filterByEndDate(event) {
        this.filterProps.endDate = event.target.value;

        if (this.filterProps.createdBy || this.filterProps.clientName || this.filterProps.starteDate || this.filterProps.endDate) {
            this.chargesList = JSON.parse(JSON.stringify(this.chargeFiltering())); /* [...this.originalData?.filter(charge => {
                let d1 = new Date(charge.date);
                let d2 = new Date(event.target.value);
                return d1.getTime() < d2.getTime();
            })];*/
        } else {
            this.chargesList = [...this.originalData];
        }
    }

    filterByBillable(event) {
        this.filterProps.billable = event.target.value;
        //this.chargesList = [...this.originalData?.filter(charge => event.target.value != 'All' ? '' + charge.billable == event.target.value : '' + charge.billable == 'true' || '' + charge.billable == 'false')];
        this.chargesList = JSON.parse(JSON.stringify(this.chargeFiltering()));
    }

    filterByCategory(event) {
        this.filterProps.category = event.target.value;
        this.chargesList = JSON.parse(JSON.stringify(this.chargeFiltering()));
    }



    hasBillingCodes = false;

    hasServiceEnrollmentList = false;


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


    columnsList = [
        { label: 'Client Name', fieldName: 'clientName', sortable: true },
        { label: 'Service Enrollment', fieldName: 'serviceEnrollmentName' },
        { label: 'Description', fieldName: 'description', },
        { label: 'Date', fieldName: 'date', type: 'date', sortable: true },
        { label: 'Billing Code', fieldName: 'billingCode' },
        { label: 'Quantity / Hours', fieldName: 'qtyHrs', type: 'number' },
        { label: 'Rate', fieldName: 'rate', type: 'currency' },
        { label: 'Non-Billable', fieldName: 'billable', type: 'boolean', sortable: true },
        {
            type: 'action',
            typeAttributes: { rowActions: [{ label: 'Delete', name: 'delete' }] },
        },
    ];

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'delete':
                this.deleteRow(row);
                break;
            default:
        }
    }

    async deleteRow(row) {
        if (row.Status__c == 'INVOICED') {
            const event = new ShowToastEvent({
                title: 'Error!',
                message: '“Invoiced” charges can not be Deleted.',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }
        await deleteRecord(row.Id);

        this.getChargesList();
    }

    get checkValidations() {

        return this.disableStart || //!this.refs?.timeCategory?.value ||
            (!this.isAdmin && !((this.selectedClient != undefined) && this.selectedBillingCode != undefined && (this.selectedService != undefined && this.selectedClient != null && this.selectedService != null) && this.selectedBillingCode != null)) ||
            (this.isAdmin && !(this.selectedBillingCode != undefined && this.selectedBillingCode != null));
    }

    resetFields() {
        this.selectedClient = null;
        this.selectedBillingCode = null;
        this.selectedService = null;
        this.refs.description.value = '';
        this.template.querySelectorAll('c-searchable-combobox').forEach(ele => ele.handleCommit());
        this.template.querySelectorAll('lightning-input').forEach(ele => ele.value = '');
        this.calculateHoursAndMinutes();
        this.periodSearch = 'THIS_WEEK';
        this.formattedTime = '00:00:00';
        this.billableDefault = 'All';
    }

    get checkSaveValidation() {
        return this.allowUpdate || this.disableStart;
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.chargesList];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.chargesList = cloneData;
        this.originalData = [...this.chargesList];
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    handleHourChange(event) {
        this.displayHours = (Number(event.target.value * 60) + Number(this.refs.minutes.value)) / 60 || 0;
    }

    handleMinutesChange(event) {
        this.displayHours = (Number(this.refs.hours.value * 60) + Number(event.target.value)) / 60 || 0;
    }

    @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: TIMECATPICLIST })
    timeCategoryBind({ error, data }) {
        if (data) {
            this.timeCategoryOptions = data.values;
        }
    }

    @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: HOURSPICLIST })
    hoursBind({ error, data }) {
        if (data) {
            this.hoursOptions = data.values;
            console.log(JSON.stringify(this.hoursOptions));
        }
    }

    @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: MINSPICLIST })
    minsBind({ error, data }) {
        if (data) {
            this.minsOptions = data.values;
            console.log(JSON.stringify(this.minsOptions));
        }
    }


    @wire(getRecord, { recordId: Id, fields: ["User.Name", "User.Can_Approve_Time_Entries__c"] })
    userDetails({ error, data }) {
        if (error) {
            console.log(error);
        } else if (data) {
            this.filterProps.ownerName = data.fields.Name.value;
            if (this.refs?.createdByName)
                this.refs.createdByName.value = data.fields.Name.value;
            this.isEnableApproval = data.fields.Can_Approve_Time_Entries__c.value;
        }
    }

    hasClientList = false;

    async connectedCallback() {
        this.clientList = await getClients();
        this.clientList = this.clientList.map(client => ({ label: client.Name, value: client.Id }));
        if (this.refs.createdByName)
            this.refs.createdByName.value = this.filterProps.ownerName;
        this.hasClientList = true;
        this.getChargesList();
    }

    selectedClient;

    async handleClientChange(event, clientId) {
        this.hasServiceEnrollmentList = false;
        this.selectedService = null;
        let clientData = event?.detail;
        //this.selectedClient = null;
        if (clientData || clientId) {
            this.selectedClient = clientData?.value || clientId;
            let tempServiceList = await getServiceEntollment({ clientId: this.selectedClient });
            this.serviceEnrollmentList = [...tempServiceList.map(client => ({ label: client.Name, value: client.Id }))];
            this.hasServiceEnrollmentList = this.serviceEnrollmentList.length > 0;

            /** setting first value if list has only one record */
            this.selectedCharge.Service_Enrollment__c = this.serviceEnrollmentList.length == 1 ? this.serviceEnrollmentList[0].value : "";
            this.handleServiceChange(null, this.selectedCharge.Service_Enrollment__c);

        }
        else {
            this.serviceEnrollmentList = [];
        }
        // if(this.selectedTimeCategory == 'ADMINISTRATIVE TIME'){
        //     this.serviceEnrollmentList = [];
        // }

    }
    selectedBillingCode;
    async handleBillingCodeChange(event, billingCodeId) {

        let billingCode = event?.detail;
        this.selectedBillingCode = null;
        if (billingCode || billingCodeId) {
            this.selectedBillingCode = billingCode?.value || billingCodeId;
            this.unitPrice = await getUnitPrice({ billingCode: this.selectedBillingCode });
            console.log('Unit Price => ' + this.unitPrice);
        }
        else {
            this.unitPrice = 0;
        }
    }

    selectedService;
    handleServiceChange(event, serviceEnId) {
        let servEnrollmentData = event?.detail;
        this.selectedService = null;
        if (servEnrollmentData || serviceEnId) {
            this.selectedService = servEnrollmentData?.value || serviceEnId;
        }
    }

    async updateCharge() {
        const fields = this.genrateInputData();
        fields.Id = this.selectedCharge.Id;
        delete fields.Client__c;

        const recordInput = { fields };

        try {
            /*this.selectedBillingCode = null;
            this.selectedService = null;
            this.selectedClient = null;*/
            this.chargesList = [];
            await updateRecord(recordInput);
            this.selectedCharge = {};
            this.template.querySelector('lightning-datatable').selectedRows = [];
            this.resetFields();
            const event = new ShowToastEvent({
                title: 'Success',
                message: 'Record Updated Successfully.',
                variant: 'success'
            });
            this.dispatchEvent(event);
        }
        catch (err) {
            console.log(JSON.stringify(err));
        }
        this.getChargesList();
    }

    async saveCharge() {

        const fields = this.genrateInputData();
        const recordInput = { apiName: 'Time_Entry__c', fields };
        const requiredFields = { 'Service_Code__c': 'Billing Code' };
        if(!this.isAdmin){
            requiredFields['Service_Enrollment__c'] = 'Service Enrollment';
            requiredFields['Client__c'] = 'Client';
        }
        let isValid = true;
        for (let key of Object.keys(requiredFields)) {
            if (!fields[key]) {
                const event = new ShowToastEvent({
                    title: 'Error!',
                    message: requiredFields[key] + ' is Mising',
                    variant: 'error'
                });
                this.dispatchEvent(event);
                isValid = false;
                break;
            }
        }
        if (!isValid)
            return;
        try {
            this.chargesList = [];
            await createRecord(recordInput);
            //this.handleCancel();
            this.selectedCharge = {};
            this.refs.description.value = 'SAVE DESCRIPTION';
            //   this.template.querySelector('lightning-datatable').selectedRows = [];
            const event = new ShowToastEvent({
                title: 'Success',
                message: 'Record Saved Successfully.',
                variant: 'success'
            });
            this.dispatchEvent(event);
            location.reload();

        }
        catch (err) {
            console.log(JSON.stringify(err));
        }
        //this.template.querySelectorAll('c-searchable-combobox').forEach(ele => ele.handleCommit());

    }

    genrateInputData() {
        const fields = {};
        fields['Time_Entry_Category__c'] = this.selectedTimeCategory;
        fields['Client__c'] = this.selectedClient;
        fields['Service_Enrollment__c'] = this.selectedService;
        fields['Service_Code__c'] = this.selectedBillingCode;
        fields['Hours__c'] = this.refs.hours?.value;
        fields['Entry_Date__c'] = this.refs.chargeDate.value;
        fields['Minutes__c'] = this.refs.minutes?.value;
        fields['Description__c'] = this.refs.description.value;
        fields['Quantity__c'] = this.isTime ? this.displayHours : this.refs.quantity.value;
        fields['Non_billable__c'] = this.refs.billable.checked;
        fields['Unit_Price__c'] = this.isExpense ? this.refs.amount.value || fields['Quantity__c'] * this.unitPrice : this.unitPrice;

        return fields;
    }

    getChargesList(callback) {
        getCharges({ periodSearch: this.periodSearch }).then(charges => {
            this.chargesList = charges.map(charge => {
                return {
                    clientName: ((charge?.Client__r?.FirstName ?? '') + ' ' + (charge?.Client__r?.LastName ?? '')).replaceAll('undefined', '-'),
                    clientFirstName: (charge?.Client__r?.FirstName ?? '').replaceAll('undefined', '-'),
                    clientLastName: (charge?.Client__r?.LastName ?? '').replaceAll('undefined', '-'),
                    serviceEnrollmentName: charge?.Service_Enrollment__r?.Name,
                    description: charge.Description__c,
                    date: charge.Entry_Date__c,
                    billingCode: charge.Service_Code__r?.Name,
                    qtyHrs: charge.Quantity__c,
                    rate: charge.Unit_Price__c,
                    billable: charge.Non_billable__c,
                    ownerName: charge.CreatedBy.Name,
                    ...charge
                };
            });
            this.originalData = [...this.chargesList];
            callback && callback();
        });
    }

    get allowUpdate() {
        return this.selectedCharge.Id;
    }


    selectedCharge = {};

    async handleChargeSelect(event) {
        if (!event?.target?.getSelectedRows()[0])
            return;
        this.billingCodes = [];
        this.serviceEnrollmentList = [];
        this.hasServiceEnrollmentList = false;
        this.hasBillingCodes = false;
        this.selectedCharge = event.target.getSelectedRows()[0];
        this.template.querySelector('lightning-datatable').selectedRows = [];
        //this.template.querySelector('lightning-input[data-id="Select Client"]').value = '';

        if (!this.selectedCharge)
            return;

        await this.handleTimeCatChange(null, this.selectedCharge.Time_Entry_Category__c);
        await this.handleBillingCodeChange(null, this.selectedCharge.Service_Code__c);
        await this.handleClientChange(null, this.selectedCharge.Client__c);

        this.displayHours = (Number(this.selectedCharge.Hours__c * 60) + Number(this.selectedCharge.Minutes__c)) / 60 || 0;

        this.handleServiceChange(null, this.selectedCharge.Service_Enrollment__c);
    }

    async handleTimeCatChange(event, category) {
        this.selectedTimeCategory = event?.target?.value || category;
        if (this.isExpense && this.refs.quantity) {
            this.refs.quantity.value = 1;
        }
        this.hasBillingCodes = false;
        this.selectedBillingCode = null;
        this.selectedService = null;
        this.selectedClient = null;
        // if(this.selectedTimeCategory == 'ADMINISTRATIVE TIME'){
        //     this.hasClientList = false;
        //     this.serviceEnrollmentList = [];
        // }else{
        //     this.hasClientList = true;
        // }
        console.log(this.hasBillingCodes);
        let tempBillingCodes = await getBillingCode({ category: this.selectedTimeCategory });
        this.billingCodes = tempBillingCodes?.map(client => ({ label: client.Name, value: client.Id }));
        this.hasBillingCodes = this.billingCodes.length > 0;
    }

    handleCancel(event) {
        this.chargesList = [];
        this.selectedCharge = {};
        this.selectedBillingCode = null;
        this.selectedService = null;
        this.selectedClient = null;
        this.template.querySelector('lightning-datatable').selectedRows = [];
        this.resetFields();
        this.getChargesList();
    }

    get isExpense() {
        const expense = this.selectedTimeCategory == 'DIRECT EXPENSE' || this.selectedTimeCategory == 'FEES';
        return expense;
    }

    get isTime() {
        const time = this.selectedTimeCategory == 'HOURLY SERVICE' || this.selectedTimeCategory == 'ADMINISTRATIVE TIME';
        return time;
    }

    get isAdmin() {
        return this.selectedTimeCategory == 'ADMINISTRATIVE TIME';
    }

    handleActive(event) {
        const actionName = event.currentTarget.dataset.id;
        console.log('actionName', actionName);
        if (actionName === "approve" && this.isEnableApproval) {
            this.isEnableApprovalButton = true;
            this.columnsList = [
                { label: 'Client Name', fieldName: 'clientName', sortable: true },
                { label: 'Service Enrollment', fieldName: 'serviceEnrollmentName' },
                { label: 'Description', fieldName: 'description', },
                { label: 'Date', fieldName: 'date', type: 'date', sortable: true },
                { label: 'Billing Code', fieldName: 'billingCode' },
                { label: 'Quantity / Hours', fieldName: 'qtyHrs', type: 'number' },
                { label: 'Rate', fieldName: 'rate', type: 'currency' },
                { label: 'Non-Billable', fieldName: 'billable', type: 'boolean', sortable: true },
                { label: 'Approved', fieldName: 'Approved__c', type: 'boolean', sortable: true },
                {
                    type: 'action',
                    typeAttributes: { rowActions: [{ label: 'Delete', name: 'delete' }] },
                },
            ];
        } else {
            this.isEnableApprovalButton = false;
            this.columnsList = [
                { label: 'Client Name', fieldName: 'clientName', sortable: true },
                { label: 'Service Enrollment', fieldName: 'serviceEnrollmentName' },
                { label: 'Description', fieldName: 'description', },
                { label: 'Date', fieldName: 'date', type: 'date', sortable: true },
                { label: 'Billing Code', fieldName: 'billingCode' },
                { label: 'Quantity / Hours', fieldName: 'qtyHrs', type: 'number' },
                { label: 'Rate', fieldName: 'rate', type: 'currency' },
                { label: 'Non-Billable', fieldName: 'billable', type: 'boolean', sortable: true },
                { label: 'Approved', fieldName: 'Approved__c', type: 'boolean', sortable: true },
                {
                    type: 'action',
                    typeAttributes: { rowActions: [{ label: 'Delete', name: 'delete' }] },
                },
            ];
        }
    }

    async approveCharge() {
        this.isEnableApprovalButton = false;
        const selectedCharge = this.template.querySelectorAll('lightning-datatable')[1].getSelectedRows();
        console.log('selected cahrge', selectedCharge);

        if (selectedCharge.length == 0) {
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'No records to Approve.',
                variant: 'Error'
            });
            this.dispatchEvent(event);
            return;
        }

        const updateRecords = selectedCharge.map(item => {
            let fields = {};
            fields.Approved__c = true;
            fields.Id = item.Id;

            let recordInput = { fields };
            return updateRecord(recordInput);
        })

        try {
            this.chargesList = [];
            await Promise.all(updateRecords);
            this.selectedCharge = {};
            this.template.querySelectorAll('lightning-datatable')[1].selectedRows = [];
            const event = new ShowToastEvent({
                title: 'Success',
                message: 'Record Updated Successfully.',
                variant: 'success'
            });
            this.dispatchEvent(event);
            this.isEnableApprovalButton = true;
        }
        catch (err) {
            console.log(JSON.stringify(err));
        }
        this.getChargesList();
    }

}