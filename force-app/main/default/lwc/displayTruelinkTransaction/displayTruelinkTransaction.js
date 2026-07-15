import { LightningElement, api, track, wire } from 'lwc';
import getBeneficiaryCard from '@salesforce/apex/TrueLinkTransactionController.getBeneficiaryCard';
import getTransactions from '@salesforce/apex/TrueLinkTransactionController.getTransactions';
import { CurrentPageReference } from 'lightning/navigation';

const COLS = [
    {
        label: 'Date',
        fieldName: 'dateDisplay',
        sortable: true,
        type: 'text' // display "MMM dd"; we sort on 'timestamp' internally
    },
    { label: 'Merchant', fieldName: 'merchantName', sortable: true, type: 'text' },
    { label: 'Location', fieldName: 'location', sortable: false, type: 'text' },
    { label: 'Amount', fieldName: 'amount', sortable: true, type: 'currency', typeAttributes: { currencyCode: { fieldName: 'currency' } } },
    { label: 'Status', fieldName: 'status', sortable: true, type: 'text' },
    { label: 'Settled', fieldName: 'settled', sortable: true, type: 'boolean' }
];

const FILTERS = [
    { label: 'This Month', value: 'THIS_MONTH' },
    { label: 'Last Month', value: 'LAST_MONTH' },
    { label: 'Last 3 Months', value: 'LAST_3_MONTHS' },
    { label: 'Last 12 Months', value: 'LAST_12_MONTHS' }
];

export default class DisplayTruelinkTransactions extends LightningElement {
    @api recordId;

    @track card;
    @track rows = [];      // List<Map<String,Object>>
    @track columns = COLS;

    @track filterValue = 'THIS_MONTH';
    filterOptions = FILTERS;

    @track sortedBy;
    @track sortedDirection = 'desc';

    @track pending = 0;
    @track effective = 0;
    isLoading = false;

    get beneficiaryName() { return this.card?.Beneficiary__r?.Name || '';}
    get cardName() { return this.card?.Name || ''; }
    get cardStatus() { return this.card?.Status__c || ''; }
    get formattedBalance() { return this.formatCurrency(this.card?.Balance__c); }
    get formattedPending() { return this.formatCurrency(this.pending); }
    get formattedEffective() { return this.formatCurrency(this.effective); }

    
    @wire(CurrentPageReference)
    capturePageReference(pageRef) {
        if (!this.recordId && pageRef?.state?.recordId) {
            this.recordId = pageRef.state.recordId;
        }
    }

    connectedCallback() {
        console.log('this.recordId -- ' + this.recordId);
        this.loadCard();
        this.loadTransactions();
    }

    async loadCard() {
        try {
            this.card = await getBeneficiaryCard({ beneficiaryCardId: this.recordId });
        } catch (e) {
            this.showError(e?.body?.message || e?.message || 'Error loading card details');
        }
    }

    async loadTransactions() {
        this.isLoading = true;
        try {
            const res = await getTransactions({ beneficiaryCardId: this.recordId, filterKey: this.filterValue });
            console.log('res --- ' + JSON.stringify(res));
            // Plain maps; ensure currency fallback
            this.rows = (res?.transactions || []).map(t => ({
                ...t,
                currency: t.currency || 'USD'
            }));
            this.pending   = res?.currentPending || 0;
            this.effective = res?.effectiveBalance || 0;

            
        if (!this.sortedBy) {
           this.sortedBy = 'dateDisplay';
           this.sortedDirection = 'desc';
           this.sortData('timestamp', 'desc');
        }
        this.isLoading = false;
        } catch (e) {
            this.showError(e?.body?.message || e?.message || 'Error loading transactions');
            this.isLoading = false;
        }
    }

    handleFilterChange(evt) {
        this.filterValue = evt.detail.value;
        this.loadTransactions(); // new API callout per requirement
    }

    
    handleSort(evt) {
        const { fieldName, sortDirection } = evt.detail;

        // UI expects the clicked column name here
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;

        // But for Date, sort on full timestamp under the hood
        const sortField = fieldName === 'dateDisplay' ? 'timestamp' : fieldName;
        this.sortData(sortField, sortDirection);
    }

    
    sortData(field, direction) {
        const isAsc = direction === 'asc';
        const data = [...this.rows];

        data.sort((a, b) => {
            // Map to actual comparable values
            const valA = field === 'timestamp' ? (a.timestamp ? new Date(a.timestamp).getTime() : null) : a[field];
            const valB = field === 'timestamp' ? (b.timestamp ? new Date(b.timestamp).getTime() : null) : b[field];

            // Handle nulls first
            if (valA == null && valB == null) return 0;
            if (valA == null) return isAsc ? -1 : 1;
            if (valB == null) return isAsc ? 1 : -1;

            // Numeric compare for dates/numbers
            const bothNumeric = typeof valA === 'number' && typeof valB === 'number';
            if (bothNumeric) {
            return isAsc ? valA - valB : valB - valA;
            }

            // String compare fallback
            const aStr = '' + valA;
            const bStr = '' + valB;
            return isAsc ? aStr.localeCompare(bStr) : bStr.localeCompare(aStr);
        });

        this.rows = data;
    }


    formatCurrency(val) {
        const num = Number(val || 0);
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(num);
    }

    showError(msg) { console.error(msg); }
}