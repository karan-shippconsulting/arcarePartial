import { LightningElement, api } from 'lwc';
export default class SearchableCombobox extends LightningElement {

    _picklistOrdered;
    @api 
    get picklistOrdered(){
        return this._picklistOrdered
    }

    set picklistOrdered(value){
        this._picklistOrdered = value;
        this.searchResults = value;
    }

    @api
    disabled=false;

    @api
    required = false;

    @api
    label;
    searchResults;

    selectedSearchResult;

    _selectedData;

    @api
    get selectedDataId(){
        return this._selectedData;
    }

    set selectedDataId(value){
        this._selectedData = value;
        this.selectedSearchResult = this.picklistOrdered?.find(
            (picklistOption) => picklistOption.value === this._selectedData
        );
        this.selectedValue = this.selectedSearchResult ? this.selectedSearchResult.label : null;
    }
    
    @api
    selectedValue = '';
    search(event) {
        const input = event.detail.value.toLowerCase();
        const result = this.picklistOrdered.filter((picklistOption) =>
            picklistOption.label.toLowerCase().includes(input)
        );
        this.searchResults = result;
        if(!input){
            this.selectedValue = input;
        }
        //this.picklistOrdered = result;
    }
    resultClick = false;
    async selectSearchResult(event) {
        const selectedValue = event.currentTarget.dataset.value;
        this.selectedSearchResult = this.picklistOrdered.find(
            (picklistOption) => picklistOption.value === selectedValue
        );
        this.selectedValue = this.selectedSearchResult.label;
        //this.template.querySelector('lightning-input').value = this.selectedSearchResult.label;
        this.dispatchEvent(new CustomEvent('select',{detail:this.selectedSearchResult}));
        setTimeout(() => {
            this.hidePicllistOptions();
        },0);
        //event.stopPropagation();
    }

    @api
    handleCommit(){
        this.selectedSearchResult = {};
        this.dispatchEvent(new CustomEvent('select',{detail:null}));
    }


    showPicklistOptions() {
        this.resultClick = true;
        if (!this.searchResults) {
            this.searchResults = this.picklistOrdered;
        }
    }
    async hidePicllistOptions(event){
        event?.preventDefault();
        this.resultClick = false;
    }
}