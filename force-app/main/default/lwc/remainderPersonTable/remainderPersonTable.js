import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

import getRemainderPeople
    from '@salesforce/apex/remainderPersonTableController.getRemainderPeople';
import saveRemainderPerson
    from '@salesforce/apex/remainderPersonTableController.saveRemainderPerson';

import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import REMAINDER_PERSON_OBJECT from '@salesforce/schema/Remainder_Person__c';
import STATUS_FIELD from '@salesforce/schema/Remainder_Person__c.Status__c';

export default class RemainderPersonTable extends LightningElement {

    /* ======================
       Inputs
       ====================== */
    @api closingId;     // Parent Closing__c Id
    @api filterLogic;

    /* ======================
       Flow Output
       ====================== */
    @api remainderPersonContactId; // OUTPUT: selected row's Remainder_Person_Contact__c

    /* ======================
       State
       ====================== */
    @track rows = [];
    @track modifiedRows = new Set();

    // Single-select row Id (no default)
    selectedRowId = null;

    /* ======================
       Picklist
       ====================== */
    @track statusOptions = [];
    recordTypeId;

    /* ======================
       Picklist Wiring
       ====================== */

    @wire(getObjectInfo, { objectApiName: REMAINDER_PERSON_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            this.handleError('Error loading Remainder Person metadata', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: STATUS_FIELD })
    statusPicklist({ data, error }) {
        if (data) {
            this.statusOptions = (data.values || []).map(v => ({ label: v.label, value: v.value }));
        } else if (error) {
            this.handleError('Error loading Status picklist', error);
        }
    }

    /* ======================
       Lifecycle
       ====================== */

    connectedCallback() {
        if (!this.closingId) {
            this.showToast('Error', 'No Closing Id provided', 'error');
            return;
        }

        // No selection by default
        this.selectedRowId = null;
        this.setRemainderPersonContactId(null);

        this.loadData();
    }

    /* ======================
       Data
       ====================== */

    loadData() {
        return getRemainderPeople({
            closingId: this.closingId,
            ts: Date.now(),
            filterLogic: this.filterLogic
        })
            .then(result => {
                const data = (result || []).map(r => ({ ...r }));

                // Preserve selection ONLY if user already selected and record still exists
                if (this.selectedRowId) {
                    const stillThere = data.find(x => x.Id === this.selectedRowId);
                    if (stillThere) {
                        this.setRemainderPersonContactId(stillThere.Remainder_Person_Contact__c || null);
                    } else {
                        this.selectedRowId = null;
                        this.setRemainderPersonContactId(null);
                    }
                } else {
                    // No default selection
                    this.setRemainderPersonContactId(null);
                }

                this.rows = data.map(r => ({
                    ...r,
                    isSelected: this.selectedRowId ? (r.Id === this.selectedRowId) : false
                }));

                this.setRowSaveState();
            })
            .catch(err => this.handleError('Error loading remainder people', err));
    }

    /* ======================
       Selection
       ====================== */

    handleSelectRow(event) {
        const rowId = event.target.dataset.id;
        this.selectedRowId = rowId;

        const selected = this.rows.find(r => r.Id === rowId);
        this.setRemainderPersonContactId(selected?.Remainder_Person_Contact__c || null);

        // Update UI selection flags
        this.rows = this.rows.map(r => ({
            ...r,
            isSelected: r.Id === this.selectedRowId
        }));
    }

    /* ======================
       Inline edits
       ====================== */

    handleInputChange(event) {
        const rowId = event.target.dataset.id;
        const field = event.target.name;
        const value = event.detail?.value ?? event.target.value;

        this.rows = this.rows.map(r => {
            const row = { ...r };
            if (row.Id === rowId) {
                row[field] = value;
                this.modifiedRows.add(rowId);
            }
            return row;
        });

        this.setRowSaveState();
    }

    handleSave(event) {
        const rowId = event.target.dataset.id;
        const row = this.rows.find(r => r.Id === rowId);
        if (!row) return;

        const rpToSave = {
            Id: row.Id,
            Closing__c: this.closingId,
            Percent_of_Remaining_Funds__c: row.Percent_of_Remaining_Funds__c
                ? parseFloat(row.Percent_of_Remaining_Funds__c)
                : null,
            Status__c: row.Status__c
        };

        saveRemainderPerson({ rp: rpToSave })
            .then(() => {
                this.showToast('Success', 'Remainder Person Updated', 'success');
                this.modifiedRows.clear();
                return this.loadData();
            })
            .catch(err => this.handleError('Error saving remainder person', err));
    }

    /* ======================
       Helpers
       ====================== */

    setRemainderPersonContactId(newValue) {
        this.remainderPersonContactId = newValue;

        // 🔥 Tell Flow immediately that an output attribute changed
        this.dispatchEvent(
            new FlowAttributeChangeEvent('remainderPersonContactId', this.remainderPersonContactId)
        );
    }

    setRowSaveState() {
        this.rows = this.rows.map(r => ({
            ...r,
            saveDisabled: !this.modifiedRows.has(r.Id),
            rowStyle: ''
        }));
    }

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