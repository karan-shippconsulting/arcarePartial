import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getBenefits from '@salesforce/apex/BenefitsController.getBenefits';
import saveBenefit from '@salesforce/apex/BenefitsController.saveBenefit';

import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import BENEFIT_OBJECT from '@salesforce/schema/Benefit__c';
import BENEFIT_TYPE_FIELD from '@salesforce/schema/Benefit__c.Benefit_Type__c';
import BENEFIT_STATUS_FIELD from '@salesforce/schema/Benefit__c.Benefit_Status__c';

export default class BenefitsFlowTable extends LightningElement {

    // Flow Inputs
    @api contactId;
    @api filterLogic;

    // Sample row inputs
    @api benefitTypeSample;
    @api benefitStatusSample;
    @api benefitAmountMonthSample;
    @api sampleBackgroundColor;
    @api displaySampleRow;

    @track benefits = [];
    @track modifiedRows = new Set();

    // Picklists
    @track benefitTypeOptions = [];
    @track benefitStatusOptions = [];
    recordTypeId;

    /* -------------------------
       Picklist Wiring
       ------------------------- */

    @wire(getObjectInfo, { objectApiName: BENEFIT_OBJECT })
    benefitObjectInfo({ data, error }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            this.handleError('Error loading Benefit metadata', error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: BENEFIT_TYPE_FIELD
    })
    benefitTypePicklist({ data, error }) {
        if (data) {
            this.benefitTypeOptions = data.values.map(v => ({
                label: v.label,
                value: v.value
            }));
        } else if (error) {
            this.handleError('Error loading Benefit Type values', error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: BENEFIT_STATUS_FIELD
    })
    benefitStatusPicklist({ data, error }) {
        if (data) {
            this.benefitStatusOptions = data.values.map(v => ({
                label: v.label,
                value: v.value
            }));
        } else if (error) {
            this.handleError('Error loading Benefit Status values', error);
        }
    }

    /* -------------------------
       Lifecycle
       ------------------------- */

    connectedCallback() {
        if (!this.contactId) {
            this.showToast('Error', 'No Contact Id passed into component', 'error');
            return;
        }
        this.loadData();
    }

    generateRowId(prefix) {
        return prefix + '_' + Math.random().toString(36).substring(2, 9);
    }

    loadData() {
        return getBenefits({
            contactId: this.contactId,
            ts: Date.now(),
            filterLogic: this.filterLogic
        })
            .then(result => {
                let data = (result || []).map(r => ({ ...r }));

                // New row
                data.push({
                    Id: this.generateRowId('new'),
                    Benefit_Type__c: '',
                    Benefit_Status__c: '',
                    Benefit_Amount_Month__c: '',
                    isNew: true
                });

                // Sample row
                if (this.displaySampleRow) {
                    data.unshift({
                        Id: this.generateRowId('sample'),
                        Benefit_Type__c: this.benefitTypeSample,
                        Benefit_Status__c: this.benefitStatusSample,
                        Benefit_Amount_Month__c: this.benefitAmountMonthSample,
                        isSample: true
                    });
                }

                this.benefits = data;
                this.setRowSaveState();
            })
            .catch(err => this.handleError('Error loading benefits', err));
    }

    /* -------------------------
       Input Handling
       ------------------------- */

    handleInputChange(event) {
        const rowId = event.target.dataset.id;
        const field = event.target.name;
        const value = event.detail?.value ?? event.target.value;

        this.benefits = this.benefits.map(r => {
            const row = { ...r };
            if (row.Id === rowId) {
                row[field] = value;
                if (!row.isSample) {
                    this.modifiedRows.add(rowId);
                }
            }
            return row;
        });

        this.setRowSaveState();
    }

    /* -------------------------
       Save
       ------------------------- */

    handleSave(event) {
        const rowId = event.target.dataset.id;
        const row = this.benefits.find(r => r.Id === rowId);
        if (!row || row.isSample) return;

        const benToSave = {
            Id: row.isNew ? null : row.Id,
            Beneficiary__c: this.contactId,
            Benefit_Type__c: row.Benefit_Type__c,
            Benefit_Status__c: row.Benefit_Status__c,
            Benefit_Amount_Month__c: row.Benefit_Amount_Month__c
                ? parseFloat(row.Benefit_Amount_Month__c)
                : null
        };

        if (row.isNew) {
            const missing = [];
            if (!row.Benefit_Type__c) missing.push('Benefit Type');
            if (!row.Benefit_Status__c) missing.push('Benefit Status');
          //  if (!row.Benefit_Amount_Month__c) missing.push('Benefit Amount');

            if (missing.length) {
                this.showToast('Validation Error', 'Missing: ' + missing.join(', '), 'error');
                return;
            }
        }

        saveBenefit({ ben: benToSave })
            .then(() => {
                this.showToast('Success', row.isNew ? 'Benefit Added' : 'Benefit Updated', 'success');
                this.modifiedRows.clear();
                return this.loadData();
            })
            .catch(err => this.handleError('Error saving benefit', err));
    }

    /* -------------------------
       Row State
       ------------------------- */

    setRowSaveState() {
        this.benefits = this.benefits.map(r => {
            const row = { ...r };
            if (row.isSample) {
                row.saveDisabled = true;
                row.rowStyle = `background-color:${this.sampleBackgroundColor || '#f0f0f0'};`;
            } else if (row.isNew) {
                row.saveDisabled = false;
                row.rowStyle = '';
            } else {
                row.saveDisabled = !this.modifiedRows.has(row.Id);
                row.rowStyle = '';
            }
            return row;
        });
    }

    /* -------------------------
       Utils
       ------------------------- */

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleError(title, err) {
        const msg = err?.body?.message || err?.message || err || 'Unknown error';
        // eslint-disable-next-line no-console
        console.error(title, msg, err);
        this.showToast(title, msg, 'error');
    }
}