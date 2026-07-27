import { LightningElement, api, wire } from 'lwc';
import getAllFieldsByObject from '@salesforce/apex/SchemaUtil.getAllFieldsByObject';
import getCustomEmailById from '@salesforce/apex/SchemaUtil.getCustomEmailById';
import getAllObjects from '@salesforce/apex/SchemaUtil.getAllObjects';
import upsertEmailTemp from '@salesforce/apex/SchemaUtil.upsertEmailTemp';
import checkIsImageTextArea from '@salesforce/apex/SchemaUtil.checkIsImageTextArea';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUpdatableFieldsByObject from '@salesforce/apex/SchemaUtil.getUpdatableFieldsByObject';
import getFieldType from '@salesforce/apex/SchemaUtil.getFieldType';
import { RefreshEvent } from 'lightning/refresh';
import getPdfOptions from '@salesforce/apex/SchemaUtil.getPdfOptions';


export default class GenerateMergeFields extends LightningElement {
    @api recordId;

    showData = false;
    fieldMapByObject = {};
    fieldTypeMap = {};
    fieldApiName;
    selectedObj;
    objectList = [];
    fieldByType;
    pdfOptions = [];
    pdfOption;
    pdfFileName = '';
    objectApiName;
    dateFormatString;
    emailBodySeparate;

    width = 100;
    height = 100;

    dateFormatOptions = [
        { label: 'MM/DD/YYYY', value: 'MM/DD/YYYY' },
        { label: 'DD-MM-YYYY', value: 'DD-MM-YYYY' },
        { label: 'YYYY/MM/DD', value: 'YYYY/MM/DD' },
        { label: 'DD MMM, YYYY', value: 'DD MMM, YYYY' },
        { label: 'MMMM DD, YYYY', value: 'MMMM DD, YYYY' }
        //{ label: 'MMMM D, YYYY', value: 'MMMM D, YYYY' }
    ];

    currencyFormatOptions = [
        { label: '$#,##0', value: '$#,##0' },
        { label: '$#,##0.0', value: '$#,##0.0' },
        { label: '$#,##0.00', value: '$#,##0.00' },
        { label: '$#,##0.000', value: '$#,##0.000' },
        { label: '$#,##0.0000', value: '$#,##0.0000' },
        { label: '$#,##0.00000', value: '$#,##0.00000' }
    ];

    decimalOptions = [
        { label: '#,##0', value: '#,##0' },
        { label: '#,##0.0', value: '#,##0.0' },
        { label: '#,##0.00', value: '#,##0.00' },
        { label: '#,##0.000', value: '#,##0.000' },
        { label: '#,##0.0000', value: '#,##0.0000' },
        { label: '#,##0.00000', value: '#,##0.00000' }
    ];

    generalTaggerOptions = [
        { label: '-None-', value: '-None-' },
        { label: 'TODAY()', value: 'TODAY()' }
    ];

    booleanFormatOptions = [
        { label: 'Yes/No', value: 'Yes/No' },
        { label: 'Y/N', value: 'Y/N' },
        { label: 'True/False', value: 'True/False' }
    ];

    genericTaggers = ['TODAY()'];

    currencyFormatStringLabel = '';
    currencyFormatStringValue = '';
    decimalFormatStringLabel = '';
    decimalFormatStringValue = '';
    booleanFormatValue = '';

    handleDateFormatChange(event){
        this.dateFormatString = event.target.value;
        if(this.fieldApiName) {
            let previousSelectedField = this.fieldApiName.substring(1, this.fieldApiName.indexOf('}'));
            this.handleDataFormatting(previousSelectedField);
        }
    }

    handleCurrencyFormatChange(event){
        this.currencyFormatStringValue = event.target.value;
        // Get the label using the selected value
        const selectedOption = this.currencyFormatOptions.find(
            option => option.value === this.currencyFormatStringValue
        );
        this.currencyFormatStringLabel = selectedOption ? selectedOption.label : '';

        if(this.fieldApiName) {
            let previousSelectedField = this.fieldApiName.substring(1, this.fieldApiName.indexOf('}'));
            this.handleDataFormatting(previousSelectedField);
        }
    }

    handleDecimalFormatChange(event){
        this.decimalFormatStringValue = event.target.value;

        // Get the label using the selected value
        const selectedOption = this.decimalOptions.find(
            option => option.value === this.decimalFormatStringValue
        );
        this.decimalFormatStringLabel = selectedOption ? selectedOption.label : '';

        if(this.fieldApiName) {
            let previousSelectedField = this.fieldApiName.substring(1, this.fieldApiName.indexOf('}'));
            this.handleDataFormatting(previousSelectedField);
        }
    }

    handleBooleanFormatChange(event){
        this.booleanFormatValue = event.target.value;
        if(this.fieldApiName) { 
            let previousSelectedField = this.fieldApiName.substring(1, this.fieldApiName.indexOf('}'));
            this.handleDataFormatting(previousSelectedField);
        } 
    }

    async connectedCallback() {
        try {
            this.objectList = await getAllObjects();

            if (this.recordId) {
                const data = await getCustomEmailById({ Id: this.recordId });
                this.refs.emailBodyText.value = data.Body__c;
                this.refs.emailBodySeparate.value = data.Email_Body__c || '';
                this.refs.subject.value = data.Subject__c;
                this.objectApiName = data.Parent_Object__c;
                this.fieldName1 = data.Default_Field_Name_1__c;
                this.fieldName2 = data.Default_Field_Name_2__c;
                this.fieldName3 = data.Default_Field_Name_3__c;
                this.pdfOption = data.Pdf_Template__c;
                this.pdfFileName = data.PDF_File_Name__c || '';
                this.decimalFormatStringValue = data.Default_Decimal_Format__c;
                this.currencyFormatStringValue = data.Default_Currency_Format__c;
                this.dateFormatString = data.Default_Date_Format__c;
                this.booleanFormatValue = data.Default_Boolean_Format__c;

                this.fieldType1 = this.fieldName1 ? await getFieldType({ objectName: this.objectApiName, fieldName: this.fieldName1 }) : null;
                this.fieldType2 = this.fieldName2 ? await getFieldType({ objectName: this.objectApiName, fieldName: this.fieldName2 }) : null;
                this.fieldType3 = this.fieldName3 ? await getFieldType({ objectName: this.objectApiName, fieldName: this.fieldName3 }) : null;

                this.getMetaData();
            }
        } catch (err) {
            console.log(err);
        }
    }


    get currentObjectFields() {
        return this.fieldByType?.map(item => {
            return { label: item.label, value: item.name };
        });
    }

    fieldName1;
    fieldName2;
    fieldName3;

    fieldType1;
    fieldType2;
    fieldType3;

    async handleFieldChange1(event) {
        this.fieldName1 = event.target.value;
        this.fieldType1 = await getFieldType({ objectName: this.objectApiName, fieldName: event.target.value });

    }
    async handleFieldChange2(event) {
        this.fieldName2 = event.target.value;
        this.fieldType2 = await getFieldType({ objectName: this.objectApiName, fieldName: event.target.value });
    }
    async handleFieldChange3(event) {
        this.fieldName3 = event.target.value;
        this.fieldType3 = await getFieldType({ objectName: this.objectApiName, fieldName: event.target.value });
    }

    @wire(getPdfOptions, { objectApiName: '$objectApiName' })
    wireData5({ error, data }) {
        if (!error) {
            this.pdfOptions = data?.map(item => ({ label: item.Name, value: item.Id }));
            if (!this.pdfOptions)
                this.pdfOptions = [];
            this.pdfOptions.unshift({ label: 'Default', value: 'default' });
        }
        else {
            console.error('Error: WiredData5', error);
        }
    }

    async getMetaData(event) {
        this.selectedObj = null;
        this.showData = false;
        console.log(JSON.stringify(event?.detail));
        this.objectApiName = event?.detail?.value || this.objectApiName;
        if (!this.objectApiName || this.objectApiName.trim().length == 0)
            return;
        this.fieldMapByObject = {};
        let data = await getAllFieldsByObject({ objectApiName: this.objectApiName });
        getUpdatableFieldsByObject({ objectApiName: this.objectApiName })
            .then(result => {
                this.fieldByType = result;
                this.showData = true;
            });
        this.fieldTypeMap = data.types;
        Object.entries(data.fields).forEach(entry => {
            let objName = entry[0].split('->');
            let objNameStr = objName.length == 1 ? this.objectApiName : objName[0];
            let fieldList = this.fieldMapByObject[objNameStr] || new Set();
            fieldList.add(entry);
            this.fieldMapByObject[objNameStr] = fieldList;
        });
    }

    get picklist1() {
        return Object.keys(this.fieldMapByObject).sort().map(obj => {
            return { label: obj, value: obj };
        });
    }

    get picklist2() {
        if (!this.selectedObj)
            return null;
        return [...this.fieldMapByObject[this.selectedObj]]?.sort().map(item => {
            return { label: (item[0].split('->')[1] || item[0]), value: item[1] };
        });
    }

    handleChange(event) {
        this.selectedObj = event.target.value;
        this.fieldApiName = '';
    }

    async handleDataFormatting(value) {
        let fieldTypeMapKey;
        if(this.genericTaggers.includes(value)) {
            this.fieldApiName = `{${value}}` + ':' + this.dateFormatString + '}';
        }
        if(value.includes('CurrentUser')) {
            fieldTypeMapKey = 'CreatedBy' + value.substring(value.indexOf('.'), value.length);
        } else {
            fieldTypeMapKey = value;
        }
        if(!this.genericTaggers.includes(value)) {
            if(this.fieldTypeMap[fieldTypeMapKey] == 'DATETIME' || this.fieldTypeMap[fieldTypeMapKey] == 'DATE') {
                this.fieldApiName = `{${value}}` + ':' + this.dateFormatString + '}';
            } else if(this.fieldTypeMap[fieldTypeMapKey] == 'CURRENCY') {
                this.fieldApiName = `{${value}}` + ':' + this.currencyFormatStringLabel + '}';
            } else if(this.fieldTypeMap[fieldTypeMapKey] == 'DOUBLE') {
                this.fieldApiName = `{${value}}` + ':' + this.decimalFormatStringLabel + '}';
            }  else if(this.fieldTypeMap[fieldTypeMapKey] == 'TEXTAREA') {
                await checkIsImageTextArea(
                    {fieldApiName: value, 
                    recordId: this.recordId, 
                    objectApiName: this.objectApiName }
                ).then((data) => {
                    if(data) {
                        this.fieldApiName = `{${value}}` + ':w=' + this.width + ';h=' + this.height + '}';
                    }
                }).catch((error) => {
                    console.log(JSON.stringify(error));
                });
            } else if(this.fieldTypeMap[fieldTypeMapKey] == 'BOOLEAN') {
                this.fieldApiName = `{${value}}` + ':' + this.booleanFormatValue + '}';
            }
        }
        
        const unsecuredCopyToClipboard = (text) => { 
            const textArea = document.createElement("textarea"); 
            textArea.value = text; 
            document.body.appendChild(textArea); 
            textArea.focus(); 
            textArea.select(); 
            try { 
                document.execCommand('copy') 
            } 
            catch (err) { 
                console.error('Unable to copy to clipboard', err) 
            } 
            document.body.removeChild(textArea) 
        };
        /**
         * Copies the text passed as param to the system clipboard
         * Check if using HTTPS and  navigator.clipboard is available
         * Then uses standard clipboard API, otherwise uses fallback
        */
        if (window.isSecureContext && navigator.clipboard) {
            navigator.clipboard.writeText(this.fieldApiName);
        } else {
            unsecuredCopyToClipboard(this.fieldApiName);
        }
        //navigator.clipboard.writeText(this.fieldApiName);
    }

    handleChange2(event) {
        this.fieldApiName = `{${event.target.value}}`;
        this.handleDataFormatting(event.target.value);
    }

    handleChange4(event) {
        if(event.target.value.includes('-None-')) {
            return;
        }
        this.fieldApiName = `{${event.target.value}}`;
        this.handleDataFormatting(event.target.value);
    }

    saveRecord() {
        upsertEmailTemp({
            tempId: this.recordId,
            emailBody: this.refs.emailBodyText.value,
            separateEmailBody: this.refs.emailBodySeparate.value,
            subject: this.refs.subject.value,
            objectName: this.objectApiName,
            pdfTemplate : this.pdfOption,
            Default_Field1: this.fieldName1,
            Default_Field2: this.fieldName2,
            Default_Field3: this.fieldName3,
            Default_FieldValue1: this.refs.fieldValue1?.value,
            Default_FieldValue2: this.refs.fieldValue2?.value,
            Default_FieldValue3: this.refs.fieldValue3?.value,
            Default_DateFormat: this.dateFormatString,
            Default_CurrencyFormat: this.currencyFormatStringValue,
            Default_DecimalFormat: this.decimalFormatStringValue,
            Default_BooleanFormat: this.booleanFormatValue,
            pdfFileName: this.refs.pdfFileName.value
        })
            .then(() => {
                const event = new ShowToastEvent({
                    title: 'Success',
                    message: 'Email Template Updated',
                    variant: 'success'
                });
                this.dispatchEvent(event);
                this.dispatchEvent(new RefreshEvent());

            }).catch((error)=>{
                console.log('error at 364---' + JSON.stringify(error));
            });
    }

    handlePdfOptionChange(event) {
        this.pdfOption = event.target.value;
    }

}