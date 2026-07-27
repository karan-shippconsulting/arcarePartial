import { LightningElement, api, wire, track } from 'lwc';
import getAllFieldsByObject from '@salesforce/apex/SchemaUtil.getAllFieldsByObject';
import getAllEmailTemps from '@salesforce/apex/SchemaUtil.getAllEmailTemps';
import getAllEmailTempsCustom from '@salesforce/apex/SchemaUtil.getAllEmailTempsCustom';
import generateStringBody from '@salesforce/apex/SchemaUtil.generateStringBody';
import upsertEmailTemp from '@salesforce/apex/SchemaUtil.upsertEmailTemp';
import checkEditPermission from '@salesforce/apex/SchemaUtil.checkEditPermission';
import queryData from '@salesforce/apex/SchemaUtil.queryData';
import checkIsImageTextArea from '@salesforce/apex/SchemaUtil.checkIsImageTextArea';
import getUpdatableFieldsByObject from '@salesforce/apex/SchemaUtil.getUpdatableFieldsByObject';
import generatePDF from '@salesforce/apex/SchemaUtil.generatePDF';
import generatePDFOnRecord from '@salesforce/apex/SchemaUtil.generatePDFOnRecord';
import getPdfOptions from '@salesforce/apex/SchemaUtil.getPdfOptions';
import generatePgetAllOrgWideEmailAddressDF from '@salesforce/apex/SchemaUtil.getAllOrgWideEmailAddress';
import sendEmail from '@salesforce/apex/SchemaUtil.sendEmail';
import getContactLookupValues from '@salesforce/apex/SchemaUtil.getContactLookupValues';
import getAttachments from '@salesforce/apex/SchemaUtil.getAttachments';
import updateFinalBody from '@salesforce/apex/SchemaUtil.updateFinalBody';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import deleteAttachment from '@salesforce/apex/SchemaUtil.deleteAttachment';
import FOLDER_FIELD from "@salesforce/schema/Custom_Email_Template__c.Folder__c";
import getCustomEmailById from '@salesforce/apex/SchemaUtil.getCustomEmailById';
import { loadStyle } from "lightning/platformResourceLoader";
import modal from "@salesforce/resourceUrl/quickActionModalWidthIncrease";

export default class DynamicEmailGenerator extends LightningElement {
    @api objectApiName;
    @api recordId;
    contactList = [];
    isLoading = false;
    recordTypeId = '';
    pdfOptions = [];

    isShowModal = false;

    fieldMapByObject = {};
    fieldTypeMap = {};

    showData = false;
    fieldApiName;
    sperateBody = false;
    folder = '';
    pdfOption = 'default';
    formatString='MM/DD/YYYY';

    emailSubject = '';

    _sObject = {};
    defaultEmail = '';

    get defaultEmailValue(){
        let defaultValue = this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).defaultOrg;
        if(!defaultValue)
            return '0';
        
        let toRet = this.orgWideList.find(item => item.address == defaultValue)?.value;
        return toRet ?? '0';
    }

    defaultEmailHandler(){
        console.log('Inside Default Email: ');
        if(!this.selectedTemp)
            return '';

        let refField = this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).recpField;

        if(!refField)
            return '';

        /*if(this._sObject ){
            //this.refs.toLists.value = this._sObject[refField] + (this.refs.toLists.value ? ';' : '') + this.refs.toLists.value;
            this.defaultEmail = this._sObject[refField] + (this.defaultEmail ? ';' : '') + this.defaultEmail;
        }
        else{*/
            queryData({fieldList:[refField],objectApiName:this.objectApiName,recordId:this.recordId}).then(result => {
                this._sObject = result[0];
                let sobjectValue;
                if(refField.includes('__r.')){
                    let arr = refField.split('.');
                    sobjectValue = this._sObject[arr[0]][arr[1]];
                } else {
                    sobjectValue = this._sObject[refField];
                }
                //this.refs.toLists.value = sobjectValue + (this.refs.toLists.value ? ';' : '') + this.refs.toLists.value;
                this.defaultEmail = sobjectValue;
                
            });
        //}

        //return '';
    }

    emailTemps;
    emailTempsCustom;
    emailBody;
    attachmentBody;
    matches = [];
    selectedObj;
    pdfFileName = '';

    createActivity = false;

    connectedCallback() {
        loadStyle(this, modal);
    }
    emailOnly = false;
    handleSperateToggle(event) {
        if(this.emailOnly){
            event.preventDefault();
            this.refs.sperateBodyRef.value = false;
            return;
        }
        this.sperateBody = event.target.checked;
        this.handleClick(false);
    }
    handleEmailOnlyToggle(event){
        this.emailOnly = event.target.checked;
    }

    handlecreateActivity(event) {
        this.createActivity = event.target.checked;
    }

    dateFormatOptions = [
        { label: 'MM/DD/YYYY', value: 'MM/DD/YYYY' },
        { label: 'DD-MM-YYYY', value: 'DD-MM-YYYY' },
        { label: 'YYYY/MM/DD', value: 'YYYY/MM/DD' },
        { label: 'DD MMM, YYYY', value: 'DD MMM, YYYY' },
        { label: 'MMMM DD, YYYY', value: 'MMMM DD, YYYY' }
        //{ label: 'MMMM D, YYYY', value: 'MMMM D, YYYY' }
    ];

    currencyFormatOptions = [
        { label: '$#,##0', value: '0' },
        { label: '$#,##0.0', value: '1' },
        { label: '$#,##0.00', value: '2' },
        { label: '$#,##0.000', value: '3' },
        { label: '$#,##0.0000', value: '4' },
        { label: '$#,##0.00000', value: '5' }
    ];

    decimalOptions = [
        { label: '#,##0', value: '0' },
        { label: '#,##0.0', value: '1' },
        { label: '#,##0.00', value: '2' },
        { label: '#,##0.000', value: '3' },
        { label: '#,##0.0000', value: '4' },
        { label: '#,##0.00000', value: '5' }
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

    currencyFormatStringLabel = '$#,##0';
    currencyFormatStringValue = '0';
    decimalFormatStringLabel = '#,##0';
    decimalFormatStringValue = '0';
    booleanFormatValue = 'Yes/No';

    width = 100;
    height = 100;

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
        //this.decimalFormatString = event.target.value;
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

    @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: FOLDER_FIELD })
    folderPickListMeta;

    @wire(getAllFieldsByObject, { objectApiName: '$objectApiName' })
    wiredData({ error, data }) {
        console.log('objectApiName: ', this.objectApiName);
        if (data) {
            this.isLoading = true;
            this.processData(data);
            getUpdatableFieldsByObject({ objectApiName: this.objectApiName })
                .then(result => {
                    this.fieldByType = result;
                    this.isLoading = false;
                });
        } else if (error) {
            console.error('Error: wiredData1', error);
        }
    }

    @wire(getAllEmailTemps)
    wiredData2({ error, data }) {
        if (data) {
            this.emailTemps = data.map(item => {
                return { label: item.Name + ' - ' + item.TemplateType, value: item.Id, subject: item.Subject };
            });
        } else if (error) {
            console.error('Error: WiredData2', error);
        }
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

    get folderOptions() {
        let newVal = [{ label: 'All', value: '' }];
        return [...newVal, ...this.folderPickListMeta?.data?.values];
    }

    handleFolderChange(event) {
        this.folder = event.target.value;
        this.emailBody = null;
        this.attachmentBody = null;
        this.emailSubject = null;
        this.selectedTemp = null;
        this._sObject = null;
    }

    emailTempsCustomTemp;
    @wire(getAllEmailTempsCustom, { folder: '$folder', objectApiName: '$objectApiName' })
    wiredData3({ error, data }) {
        if (data) {
            this.emailTempsCustomTemp = data;
            this.emailTempsCustom = data.map(item => {
                return {
                    label: item.Name, value: item.Id, body: item.Body__c, subject: item.Subject__c, Default_Field_Name_1__c: item.Default_Field_Name_1__c, Default_Field_Name_2__c: item.Default_Field_Name_2__c, Default_Field_Name_3__c: item.Default_Field_Name_3__c,
                    Default_Field_Value_1__c: item.Default_Field_Value_1__c, Default_Field_Value_2__c: item.Default_Field_Value_2__c, Default_Field_Value_3__c: item.Default_Field_Value_3__c, 
                    Pdf_Template__c : item.Pdf_Template__c,recpField:item.Recipient_Address_Field__c,defaultOrg:item.Organization_Wide_Email__c, Default_Date_Format__c : item.Default_Date_Format__c, Default_Currency_Format__c : item.Default_Currency_Format__c,
                    Default_Decimal_Format__c : item.Default_Decimal_Format__c, Default_Boolean_Format__c : item.Default_Boolean_Format__c,
                    pdfFileName: item.PDF_File_Name__c || ''
                };
            });
            // this.emailTempsCustom.unshift({label:'Create New',value:'new'});
        } else if (error) {
            console.error('Error: WiredData3', error);
        }
    }

    fieldByType;

    formatDateUI(date, isToday) {
        let formatString = this.formatString;
        let tpFormatDate;
        let splittedT = [];

        // Normalize date input
        if (isToday) {
            tpFormatDate = new Date().toISOString().split('T')[0];
        } else if (typeof date === 'string' && date.includes('T')) {
            splittedT = date.split('T');
            tpFormatDate = splittedT[0];
        } else if (typeof date === 'string') {
            tpFormatDate = date;
        } else if (date instanceof Date) {
            tpFormatDate = date.toISOString().split('T')[0];
        } else {
            return '';
        }

        const [year, month, day] = tpFormatDate.split('-');
        let trimDay = day;
        let dayString = day.toString();
        if(dayString.indexOf("0") == 0) {
            trimDay = dayString.substring(1, dayString.length);
        }
        let trimMonth = month;
        let monthString = month.toString();
        if(monthString.indexOf("0") == 0) {
            trimMonth = monthString.substring(1, monthString.length);
        }

        const fullMonthNames = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        ];
        const shortMonthNames = fullMonthNames.map(m => m.substring(0, 3));
        const monthIndex = parseInt(month, 10) - 1;

        let formattedDate = '';

        switch (formatString) {
            case 'MM/DD/YYYY':
                formattedDate = `${trimMonth}/${trimDay}/${year}`;
                break;
            case 'DD-MM-YYYY':
                formattedDate = `${trimDay}-${trimMonth}-${year}`;
                break;
            case 'YYYY/MM/DD':
                formattedDate = `${year}/${trimMonth}/${trimDay}`;
                break;
            case 'DD MMM, YYYY':
                formattedDate = `${trimDay} ${shortMonthNames[monthIndex]}, ${year}`;
                break;
            case 'MMMM DD, YYYY':
                formattedDate = `${fullMonthNames[monthIndex]} ${trimDay}, ${year}`;
                break;
            case 'MMMM D, YYYY':
                formattedDate = `${fullMonthNames[monthIndex]} ${trimDay}, ${year}`;
                break;
            default:
                formattedDate = `${month}/${day}/${year}`;
        }

        return formattedDate;
    }

    @wire(generatePgetAllOrgWideEmailAddressDF)
    wiredData4({ error, data }) {
        if (data) {
            this.orgWideList = data.map(item => {
                return { label: item.DisplayName, value: item.Id, address: item.Address };
            });
            this.orgWideList.push({ label: 'Current User', value: '0', address: '' });
        } else if (error) {
            console.error('Error: WiredData4', error);
        }
    }

    get emailTempOptions() {
        return this.emailType == 'custom' ? this.emailTempsCustom : this.emailTemps;
    }

    processData(data) {
        this.fieldTypeMap = data.types;
        Object.entries(data.fields).forEach(entry => {
            let objName = entry[0].split('->');
            let objNameStr = objName.length == 1 ? this.objectApiName : objName[0];
            let fieldList = this.fieldMapByObject[objNameStr] || [];
            fieldList.push(entry);
            this.fieldMapByObject[objNameStr] = fieldList;
            this.showData = true;

        });

    }

    handlePdfOptionChange(event) {
        this.pdfOption = event.target.value;
    }

    field1;
    field2;
    field3;

    value1;
    value2;
    value3;
    loadRecordEditForm = false;

    handleFieldChange(event) {
        this.loadRecordEditForm = false;
        this[event.target.dataset.id] = event.target.value;
        this.loadRecordEditForm = true;
        if (event.target.dataset.id == 'field1') {
            this.value1 = '';
        } else if (event.target.dataset.id == 'field2') {
            this.value2 = '';
        } else if (event.target.dataset.id == 'field3') {
            this.value3 = '';
        }
    }

    handleDateFormatChange(event){
        this.formatString = event.target.value;
        if(this.fieldApiName) { 
            let previousSelectedField = this.fieldApiName.substring(1, this.fieldApiName.indexOf('}'));
            this.handleDataFormatting(previousSelectedField);
        }
    }

    get currentObjectFields() {
        return this.fieldByType?.map(item => {
            return { label: item.label, value: item.name };
        });
    }

    handleChange(event) {
        this.selectedObj = event.target.value;
        this.fieldApiName = '';
    }

    async handleDataFormatting(value) {
        let fieldTypeMapKey;
        if(this.genericTaggers.includes(value)) {
            this.fieldApiName = `{${value}}` + ':' + this.formatString + '}';
        }
        if(value.includes('CurrentUser')) {
            fieldTypeMapKey = 'CreatedBy' + value.substring(value.indexOf('.'), value.length);
        } else {
            fieldTypeMapKey = value;
        }
        if(!this.genericTaggers.includes(value)) {
            if(this.fieldTypeMap[fieldTypeMapKey] == 'DATETIME' || this.fieldTypeMap[fieldTypeMapKey] == 'DATE') {
                this.fieldApiName = `{${value}}` + ':' + this.formatString + '}';
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


    get picklist1() {
        return [{ label: 'Current User', value: 'Current User' }, ...Object.keys(this.fieldMapByObject).sort().map(obj => {
            return { label: obj, value: obj };
        })];
    }

    get picklist2() {
        if (!this.selectedObj)
            return null;
        return this.fieldMapByObject[this.selectedObj == 'Current User' ? 'Owner' : this.selectedObj]?.sort().map(item => {
            return { label: (item[0].split('->')[1] || item[0]), value: this.selectedObj == 'Current User' ? item[1].replace('Owner', 'CurrentUser') : item[1] };
        });
    }

    get emailTempType() {
        return [
            { label: 'Standard', value: 'standard' },
            { label: 'Custom', value: 'custom' }
        ];
    }

    createNewTemplate = false;

    get showFolder() {
        return this.isCustom && this.folderPickListMeta.data;
    }

    get isCustom() {
        return this.emailType == 'custom';
    }

    get showSave() {
        return this.allowSave && this.isCustom;
    }

    @track
    emailType = 'custom';
    handleEmailType(event) {
        this.emailType = event.target.value;
        this.emailBody = null;
        this.emailSubject = null;
        this.attachmentBody = null;
        this.selectedTemp = null;
        this._sObject = null;
        this.folder = null;
    }


    allowSave = false;
    async handleChange3(event) {
        this.matches = [];
        this.selectedTemp = event.target.value;
        this.allowSave = this.emailType == 'custom' ? await checkEditPermission({ recordId: this.selectedTemp }) : null;
        let customTemplates = await getCustomEmailById({ Id: this.selectedTemp });
        const hasEmailBody = this.emailType == 'custom' && !!customTemplates.Email_Body__c;
        if (hasEmailBody) {
            this.emailBody = customTemplates.Email_Body__c;
            this.attachmentBody = customTemplates.Body__c;
            this.sperateBody = true;
        } else {
            this.emailBody = this.emailType == 'custom' ? customTemplates.Body__c : await generateStringBody({ recordId: this.recordId, tempId: this.selectedTemp });
            this.attachmentBody = this.emailBody;
        }
        this.emailSubject = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).subject : this.emailTemps.find(emailTemp => emailTemp.value == this.selectedTemp).subject;
        this.emailType == 'custom' && this.checkFields(this.emailBody, false);
        this.emailType == 'custom' && hasEmailBody && this.checkFields(this.attachmentBody, false);
        this.emailType == 'custom' && this.checkFields(this.emailSubject, true);

        this.field1 = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Default_Field_Name_1__c : null;
        this.field2 = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Default_Field_Name_2__c : null;
        this.field3 = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Default_Field_Name_3__c : null;

        this.value1 = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Default_Field_Value_1__c : null;
        this.value2 = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Default_Field_Value_2__c : null;
        this.value3 = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Default_Field_Value_3__c : null;
        this.pdfOption = this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Pdf_Template__c;
        this.pdfFileName = this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp)?.pdfFileName || '';

        let convertDate = (field, value) => {
            return (this.fieldByType.find(aa => aa.name == field)?.type == 'DATE' || this.fieldByType.find(aa => aa.name == field)?.type == 'DATETIME') && !value ? new Date().toISOString() : value;
        };

        this.value1 = convertDate(this.field1, this.value1);
        this.value2 = convertDate(this.field2, this.value2);
        this.value3 = convertDate(this.field3, this.value3);
       
       setTimeout(() => {
             this.formatString = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Default_Date_Format__c : null;
            this.decimalFormatStringLabel = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Default_Decimal_Format__c : null;
            const selectedOption = this.decimalOptions.find(
                option => option.label === this.decimalFormatStringLabel
            );
            this.decimalFormatStringValue = selectedOption ? selectedOption.value : '';

            this.currencyFormatStringLabel = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Default_Currency_Format__c : null;
            const selectedOption1 = this.currencyFormatOptions.find(
                option => option.label === this.currencyFormatStringLabel
            );
            this.currencyFormatStringValue = selectedOption1 ? selectedOption1.value : '';
            this.booleanFormatValue = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Default_Boolean_Format__c : null;
        }, 2000);

        if (this.contactList.length == 0) {
            let results = await getContactLookupValues({ recordId: this.recordId, sObjectName: this.objectApiName });
            if (results?.length > 0) {
                this.contactList = [...results.map(result => {
                    return { label: result.Name, value: result.Email };
                })];
            }
        }

        if (this.field1 || this.field2 || this.field3)
            this.loadRecordEditForm = true;

    }

    appendTo(event) {
        this.refs.toLists.value = event.target.value + (this.refs.toLists.value ? ';' : '') + this.refs.toLists.value;
    }

    appendCC(event) {
        this.refs.ccLists.value = event.target.value + (this.refs.ccLists.value ? ';' : '') + this.refs.ccLists.value;
    }

    async handleUpdateTemplate() {
        await this.upsertEmailTemplate();
        this.isLoading = false;
        const event = new ShowToastEvent({
            title: 'Success',
            message: 'Email Template Updated',
            variant: 'success'
        });
        this.dispatchEvent(event);
        this.handleClick();

    }

    async handleSaveTemplate() {
        await this.upsertEmailTemplate();
        this.isLoading = false;
        const event = new ShowToastEvent({
            title: 'Success',
            message: 'Email Template Created',
            variant: 'success'
        });
        this.dispatchEvent(event);
        this.handleClick();
    }

    async upsertEmailTemplate() {
        this.isLoading = true;
        return await upsertEmailTemp({ tempId: this.createNewTemplate ? null : this.selectedTemp, emailBody: this.refs.emailBodyText.value, subject: this.refs.subject.value, objectName: this.objectApiName, pdfTemplate: this.pdfOption });
    }

    checkFields(text, callHandleClick) {
        this.isLoading = true;

        const regex = /{([^}]*)}/g;

        let match;
        while ((match = regex.exec(text)) !== null) {
            if (!this.matches.includes(match[1].toLowerCase())) {
                
                if(match[1].includes(':')) {
                    const test = match[1].substring(0, match[1].indexOf(":"));
                    this.matches.push(test.toLowerCase());
                    
                } else {
                    if(!this.genericTaggers.includes(match[1])) {
                        this.matches.push(match[1].toLowerCase());
                    }
                }
            }
        }
        this.isLoading = false;

        if (callHandleClick)
            this.handleClick(true);
    }

    replaceGenericTaggersValue(body) {
        if (!body) return body ?? '';
        let keyForToday = 'TODAY()';
        const regex3ForToday = /\{TODAY\(\)\}:[^}]*\}/g;
        let matches = [...body.matchAll(regex3ForToday)];
        for (const match of matches) {
            let testMatch = match.toString();
            const format = testMatch.substring(testMatch.indexOf(':') + 1, testMatch.length-1);
            this.formatString = format;
            
            let tempFormatedValue = this.formatDateUI(new Date(), true);
            body = body.replace(match, tempFormatedValue);
        }
        return body;
    }

    replaceTagWithRespectiveValue(key, match, value, isKeyCasingRequired) {
        const fieldKey = match[1];
        const format = match[2];
        let imageValue;
        let requiredKey = isKeyCasingRequired ? key.toLowerCase() : key;
        if(this.fieldTypeMap[requiredKey] == 'DATETIME' || this.fieldTypeMap[requiredKey] == 'DATE') {
            this.formatString = format;
        } else if(this.fieldTypeMap[requiredKey] == 'DOUBLE') {
            const selectedOption = this.decimalOptions.find(
                option => option.label === format
            );
            this.decimalFormatStringValue = selectedOption ? selectedOption.value : '';
        } else if(this.fieldTypeMap[requiredKey] == 'CURRENCY') {
            const selectedOption = this.currencyFormatOptions.find(
                    option => option.label === format
                );
            this.currencyFormatStringValue = selectedOption ? selectedOption.value : '';
        } else if(this.fieldTypeMap[requiredKey] == 'TEXTAREA') {
            let width = format.substring(format.indexOf('w=')+2, format.indexOf(';'));
            let height = format.substring(format.indexOf('h=')+2, format.length);
            imageValue = this.extractImageWithGivenDimensions(value, width, height);
            return imageValue;
        } else if(this.fieldTypeMap[requiredKey] == 'BOOLEAN') {
            let booleanFormatParts = format.split('/');
            return value ? booleanFormatParts[0] : booleanFormatParts[1];
        }
        let tempFormatedValue = this.formatedValue(key, '' + value);
        return tempFormatedValue;
    }

    extractImageWithGivenDimensions(richTextValue, newWidth, newHeight) {
        // 'imageDiv' created only for backend purpose, no use on UI
        const imageDiv = document.createElement('div');
        imageDiv.innerHTML = richTextValue;

        const img = imageDiv.querySelector('img');
        if (img) {
            img.setAttribute('width', newWidth);
            img.setAttribute('height', newHeight);
        }
        return imageDiv.innerHTML;
    }

    formatAddress({ street, city, state, postalCode, country }) {
        const formattedStreet = (street || '').replace(/\r?\n/g, '<br/>');
        const cityLine = [city, state, postalCode].filter(Boolean).join(', ');
        return [formattedStreet, cityLine, country].filter(Boolean).join('<br/>');
    }

    async handleClick(callFromCheckField) {
        if (!(callFromCheckField === true)) {
            this.checkFields(this.refs?.emailBodyText?.value || this.emailBody, false);
            this.sperateBody && this.checkFields(this.refs.attachmentBodyText?.value || this.attachmentBody, false);
            this.checkFields(this.refs.subject.value, false);
        }
        if (this.matches.length == 0) {
            setTimeout(() => {
                const body11 = (this.refs?.emailBodyText?.value || this.emailBody);
                this.refs.finalEmail.value = this.replaceGenericTaggersValue(body11);               

                if (this.sperateBody) {
                    const finalAttachmentBody = this.refs.finalAttachment.value = (this.refs.attachmentBodyText?.value || this.attachmentBody);
                    this.refs.finalAttachment.value = this.replaceGenericTaggersValue(finalAttachmentBody);     
                }          
            }, 200);
            return;
        }
        try {
            this.isLoading = true;
            let sObjectList = await queryData({ fieldList: this.matches, objectApiName: this.objectApiName, recordId: this.recordId });
            let sObject = sObjectList[0];
            
            this.recordTypeId = sObject.RecordTypeId;
            let body = this.refs.emailBodyText?.value || '';
            let attachmentBOdy = this.refs.attachmentBodyText?.value || this.attachmentBody || '';
            body = this.replaceGenericTaggersValue(body);
            attachmentBOdy = this.replaceGenericTaggersValue(attachmentBOdy);


            for (const key in sObject) {
                if (key.endsWith('__r') || key.endsWith('__pr') || (typeof sObject[key] == 'object' && this.fieldTypeMap[key.toLowerCase()] != 'ADDRESS')) {
                    let sObject2 = sObject[key];
                    for (const key2 in sObject2) {
                        if (Object.hasOwnProperty.call(sObject, key)) {
                            let newKey = key + '.' + key2.toLowerCase();
                            if(this.fieldTypeMap[newKey] == 'DATETIME' || this.fieldTypeMap[newKey] == 'DATE' 
                                || this.fieldTypeMap[newKey] == 'CURRENCY' || this.fieldTypeMap[newKey] == 'DOUBLE'
                                || (this.fieldTypeMap[newKey] == 'TEXTAREA' && sObject2[key2]?.includes('img'))
                                || this.fieldTypeMap[newKey] == 'BOOLEAN') {
                                const normalizedKey = newKey.replace(/_/g, '_?').toLowerCase();
                                const regexPattern = `\\{(${normalizedKey})\\}:([^}]+)\\}`;
                                const regex3 = new RegExp(regexPattern, 'gi');

                                let matches = [...body.matchAll(regex3), ...attachmentBOdy.matchAll(new RegExp(regexPattern, 'gi'))];
                                let processedTags = new Set();
                                for (const match of matches) {
                                    if (processedTags.has(match[0])) continue;
                                    processedTags.add(match[0]);
                                    let tempFormatedValue = this.replaceTagWithRespectiveValue(newKey, match, sObject2[key2], false);
                                    body = body.replaceAll(match[0], tempFormatedValue);
                                    attachmentBOdy = attachmentBOdy.replaceAll(match[0], tempFormatedValue);
                                    this.refs.subject.value = this.refs.subject.value.replaceAll(match[0], '' + (sObject2[key2] ?? ''));
                                }
                            } else{
                                let newKey = key + '.' + key2.toLowerCase();
                                const regex2 = new RegExp(`{${newKey.replace(/_/g, '_?').toLowerCase()}}`, 'gi');
                                let tempValue;
                                if(this.fieldTypeMap[newKey] == 'ADDRESS') {
                                    const address = {
                                        street: sObject2[key2].street,
                                        city: sObject2[key2].city,
                                        state: sObject2[key2].state,
                                        postalCode: sObject2[key2].postalCode,
                                        country: sObject2[key2].country
                                    };
                                    tempValue = this.formatAddress(address);
                                } else {
                                    tempValue = this.formatedValue(newKey, '' + (sObject2[key2] ?? ''));
                                }
                                if(tempValue.includes('\n')) {
                                    tempValue = (tempValue || '').replace(/\r?\n/g, '<br/>');
                                }
                                body = body.replaceAll(regex2, tempValue);
                                attachmentBOdy = attachmentBOdy?.replaceAll(regex2, tempValue);
                                this.refs.subject.value = this.refs.subject.value.replace(regex2, '' + (sObject2[key2] ?? ''));
                            }
                        }
                    }
                }
                else {
                    if (Object.hasOwnProperty.call(sObject, key)) {
                        if(this.fieldTypeMap[key.toLowerCase()] == 'DATETIME' || this.fieldTypeMap[key.toLowerCase()] == 'DATE' 
                         || this.fieldTypeMap[key.toLowerCase()] == 'CURRENCY' || this.fieldTypeMap[key.toLowerCase()] == 'DOUBLE'
                         || (this.fieldTypeMap[key.toLowerCase()] == 'TEXTAREA' && sObject[key]?.includes('img'))
                         || this.fieldTypeMap[key.toLowerCase()] == 'BOOLEAN') {
                            const normalizedKey = key.replace(/_/g, '_?').toLowerCase();
                           
                            const regexPattern = `\\{(${normalizedKey})\\}:([^}]+)\\}`;
                            const regex3 = new RegExp(regexPattern, 'gi');

                            let matches = [...body.matchAll(regex3), ...attachmentBOdy.matchAll(new RegExp(regexPattern, 'gi'))];
                            let processedTags = new Set();
                            for (const match of matches) {
                                if (processedTags.has(match[0])) continue;
                                processedTags.add(match[0]);
                                let tempFormatedValue = this.replaceTagWithRespectiveValue(key, match, sObject[key], true);
                                body = body.replaceAll(match[0], tempFormatedValue);
                                attachmentBOdy = attachmentBOdy.replaceAll(match[0], tempFormatedValue);
                                this.refs.subject.value = this.refs.subject.value.replaceAll(match[0], '' + (sObject[key] ?? ''));
                            }
                        } else {
                            const regex = new RegExp(`{${key.replace(/_/g, '_?').toLowerCase()}}`, 'gi');
                            let tempValue;
                            if(this.fieldTypeMap[key.toLowerCase()] == 'ADDRESS') {
                                const address = {
                                    street: sObject[key].street,
                                    city: sObject[key].city,
                                    state: sObject[key].state,
                                    postalCode: sObject[key].postalCode,
                                    country: sObject[key].country
                                };
                                tempValue = this.formatAddress(address);
                            } else {
                                tempValue = this.formatedValue(key, '' + (sObject[key] ?? ''));
                            }
                            if(tempValue.includes('\n')) {
                                tempValue = (tempValue || '').replace(/\r?\n/g, '<br/>');
                            }
                            body = body.replaceAll(regex, tempValue);
                            attachmentBOdy = attachmentBOdy?.replaceAll(regex, tempValue);
                            this.refs.subject.value = this.refs.subject.value.replace(regex, '' + (sObject[key] ?? ''));
                        }
                        
                    }
                }
            }
            if (sObjectList.length == 2) {
                for (const key in sObjectList[1]) {
                    if (key.endsWith('__r') || key.endsWith('__pr') || typeof sObjectList[1][key] == 'object') {
                        let sObject2 = sObjectList[1][key];
                        for (const key2 in sObject2) {
                            if (Object.hasOwnProperty.call(sObjectList[1], key)) {
                                let newKey = key + '.' + key2.toLowerCase();
                                const regex2 = new RegExp(`{${newKey.replace(/_/g, '_?').toLowerCase()}}`, 'gi');
                                body = body.replaceAll(regex2, this.formatedValue(newKey, '' + (sObject2[key2] ?? '')));
                                attachmentBOdy = attachmentBOdy?.replaceAll(regex2, this.formatedValue(newKey, '' + (sObject2[key2] ?? '')));
                                this.refs.subject.value = this.refs.subject.value.replace(regex2, '' + (sObject2[key2] ?? ''));
                            }
                        }
                    }
                    else {
                        if (Object.hasOwnProperty.call(sObjectList[1], key)) {
                            let newKey = 'CurrentUser.' + key;
                            let fieldTypeMapKey = 'CreatedBy.' + key.toLowerCase();
                            if(this.fieldTypeMap[fieldTypeMapKey] == 'DATETIME' || this.fieldTypeMap[fieldTypeMapKey] == 'DATE' 
                            || this.fieldTypeMap[fieldTypeMapKey] == 'CURRENCY' || this.fieldTypeMap[fieldTypeMapKey] == 'DOUBLE'
                            || (this.fieldTypeMap[fieldTypeMapKey] == 'TEXTAREA' && sObjectList[1][key]?.includes('img'))
                            || this.fieldTypeMap[fieldTypeMapKey] == 'BOOLEAN') {
                                const normalizedKey = newKey.replace(/_/g, '_?').toLowerCase();
                            
                                const regexPattern = `\\{(${normalizedKey})\\}:([^}]+)\\}`;
                                const regex3 = new RegExp(regexPattern, 'gi');

                                let matches = [...body.matchAll(regex3), ...attachmentBOdy.matchAll(new RegExp(regexPattern, 'gi'))];
                                let processedTags = new Set();
                                for (const match of matches) {
                                    if (processedTags.has(match[0])) continue;
                                    processedTags.add(match[0]);
                                    let imageValue;
                                    let booleanFormatParts;
                                    const fieldKey = match[1];
                                    const format = match[2];
                                    if(this.fieldTypeMap[fieldTypeMapKey] == 'DATETIME' || this.fieldTypeMap[fieldTypeMapKey] == 'DATE') {
                                        this.formatString = format;
                                    } else if(this.fieldTypeMap[fieldTypeMapKey] == 'DOUBLE') {
                                        const selectedOption = this.decimalOptions.find(
                                            option => option.label === format
                                        );
                                        this.decimalFormatStringValue = selectedOption ? selectedOption.value : '';
                                    } else if(this.fieldTypeMap[fieldTypeMapKey] == 'CURRENCY') {
                                        const selectedOption = this.currencyFormatOptions.find(
                                            option => option.label === format
                                        );
                                        this.currencyFormatStringValue = selectedOption ? selectedOption.value : '';
                                    }  else if(this.fieldTypeMap[fieldTypeMapKey] == 'TEXTAREA') {
                                        let width = format.substring(format.indexOf('w=')+2, format.indexOf(';'));
                                        let height = format.substring(format.indexOf('h=')+2, format.length);
                                        imageValue = this.extractImageWithGivenDimensions(sObjectList[1][key], width, height);
                                    }   else if(this.fieldTypeMap[fieldTypeMapKey] == 'BOOLEAN') {
                                        booleanFormatParts = format.split('/');
                                    }
                                    let tempFormatedValue;
                                    if(imageValue) {
                                        tempFormatedValue = imageValue;
                                    } else if(booleanFormatParts) {
                                        tempFormatedValue = sObjectList[1][key] ? booleanFormatParts[0] : booleanFormatParts[1];
                                    } else {
                                        tempFormatedValue = this.formatedValue('Owner.' + key.toLowerCase(), '' + (sObjectList[1][key] ?? ''));
                                    }

                                    body = body.replaceAll(match[0], tempFormatedValue);
                                    attachmentBOdy = attachmentBOdy.replaceAll(match[0], tempFormatedValue);
                                    this.refs.subject.value = this.refs.subject.value.replaceAll(match[0], '' + (sObjectList[1][key] ?? ''));
                                }
                            } else {
                                let newKey = 'CurrentUser.' + key;
                                const regex = new RegExp(`{${newKey.replace(/_/g, '_?').toLowerCase()}}`, 'gi');
                                body = body.replaceAll(regex, this.formatedValue('Owner.' + key.toLowerCase(), '' + (sObjectList[1][key] ?? '')));
                                attachmentBOdy = attachmentBOdy?.replaceAll(regex, this.formatedValue('Owner.' + key.toLowerCase(), '' + (sObjectList[1][key] ?? '')));
                                this.refs.subject.value = this.refs.subject.value.replace(regex, '' + (sObjectList[1][key] ?? ''));
                            }
                            
                        }
                    }
                }
            }

            this.isLoading = false;
            const regex = new RegExp('{([^}]*)}(:[^}]*)?}?', 'gi');
            body = body.replaceAll(regex, '');
            this.refs.subject.value = this.refs.subject.value.replaceAll(regex, '');
            this.refs.finalEmail.value = body; // + imageValue;
            if (this.sperateBody)
                this.refs.finalAttachment.value = attachmentBOdy;
        }
        catch (err) {
            this.refs.finalEmail.value = this.refs.emailBodyText?.value;
            if (this.sperateBody)
                this.refs.finalAttachment.value = this.refs.attachmentBodyText?.value;
            const event = new ShowToastEvent({
                title: 'Error',
                message: err.body?.message || err.message,
                variant: 'error'
            });
            this.dispatchEvent(event);
        }
        finally {
            this.isLoading = false;
            this.matches = [];
        }

    }

    formatedValue(key, value) {
        let lowKey = key.toLowerCase();
        if (key.includes('__r') || key.includes('Owner.'))
            lowKey = key;
        if (!this.fieldTypeMap[lowKey])
            return value;

        const currencyFormatter = new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: Number(this.currencyFormatStringValue),
            maximumFractionDigits: Number(this.currencyFormatStringValue)
        });
        const decimalFormatter = new Intl.NumberFormat('en-US', {
            style: 'decimal',
            minimumFractionDigits: Number(this.decimalFormatStringValue),
            maximumFractionDigits: Number(this.decimalFormatStringValue)
        });
        let dataType = this.fieldTypeMap[lowKey];

        console.log('dataType' + dataType);
        switch (dataType) {
            case 'DATE':
                return this.formatDateUI(value, false);
            case 'DOUBLE':
                return decimalFormatter.format(value);
            case 'CURRENCY':
                return '$' + currencyFormatter.format(value);
            case 'DATETIME':
                return this.formatDateUI(value, false);
            default:
                return value;
        }
    }

    async generatePDF() {
        this.isLoading = true;
        await updateFinalBody({ htmlString: this.refs.finalAttachment?.value.replaceAll('<br>', '<br/>').replaceAll('<p>', '<div>').replaceAll('</p>', '</div>') || this.refs.finalEmail.value.replaceAll('<br>', '<br/>').replaceAll('<p>', '<div>').replaceAll('</p>', '</div>'), recordId: this.selectedTemp });
        let blobData = await generatePDF({ recordId: this.selectedTemp, vfPageId: this.pdfOption });
        this.isLoading = false;

        let binaryString = atob(blobData);
        let uint8Array = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
            uint8Array[i] = binaryString.charCodeAt(i);
        }
        let blob = new Blob([uint8Array], { type: "application/pdf" });
        let url = URL.createObjectURL(blob);
        window.open(url, '_blank');
        URL.revokeObjectURL(url);
    }

    async generatePDFOnRecord(){
        this.isLoading = true;
        await updateFinalBody({ htmlString: this.refs.finalAttachment?.value.replaceAll('<br>', '<br/>').replaceAll('<p>', '<div>').replaceAll('</p>', '</div>') || this.refs.finalEmail.value.replaceAll('<br>', '<br/>').replaceAll('<p>', '<div>').replaceAll('</p>', '</div>'), recordId: this.selectedTemp });

        await generatePDFOnRecord({ recordId: this.selectedTemp, vfPageId: this.pdfOption,currentRecord:this.recordId });
        // let binaryString = atob(blobData);
        // let uint8Array = new Uint8Array(binaryString.length);
        // for (let i = 0; i < binaryString.length; i++) {
        //     uint8Array[i] = binaryString.charCodeAt(i);
        // }
        // let blob = new Blob([uint8Array], { type: "application/pdf" });
        // let url = URL.createObjectURL(blob);
        // window.open(url, '_blank');
        // URL.revokeObjectURL(url);

        let blobData = await generatePDF({ recordId: this.selectedTemp, vfPageId: this.pdfOption });
        // For downloading
        // var a = document.createElement("a");
        // a.setAttribute("download", 'Test');
        // a.setAttribute("href", `data:application/pdf;base64,${blobData}`);
        // document.body.appendChild(a);
        // a.click();
        // document.body.removeChild(a);

        let binaryString = atob(blobData);
        let uint8Array = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
            uint8Array[i] = binaryString.charCodeAt(i);
        }
        let blob = new Blob([uint8Array], { type: "application/pdf" });
        let url = URL.createObjectURL(blob);
        window.open(url, '_blank');

        this.template.querySelector('lightning-record-edit-form')?.submit();
        const event = new ShowToastEvent({
            title: 'Success',
            message: 'File Saved!!',
            variant: 'success'
        });
        this.dispatchEvent(event);
        this.isLoading = false;

    }


    async previewPDF() {
        this.isLoading = true;
        await updateFinalBody({ htmlString: this.refs.finalAttachment?.value.replaceAll('<br>', '<br/>').replaceAll('<p>', '<div>').replaceAll('</p>', '</div>') || this.refs.finalEmail.value.replaceAll('<br>', '<br/>').replaceAll('<p>', '<div>').replaceAll('</p>', '</div>'), recordId: this.selectedTemp });
        let blobData = await generatePDF({ recordId: this.selectedTemp, vfPageId: this.pdfOption });
        this.isLoading = false;
        var a = document.createElement("a");
        a.setAttribute("download", (this.pdfFileName || 'email') + '.pdf');
        a.setAttribute("href", `data:application/pdf;base64,${blobData}`);
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);

        let binaryString = atob(blobData);
        let uint8Array = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
            uint8Array[i] = binaryString.charCodeAt(i);
        }
        let blob = new Blob([uint8Array], { type: "application/pdf" });
        let url = URL.createObjectURL(blob);
        window.open(url, '_blank');
    }

    async sendMail() {
        if (this.refs.toLists.value.trim().split(';').length == 0) {
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Provide To Email Address List',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }

        if (this.refs.subject.value.trim().length == 0) {
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Provide Subject',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }

        if (this.refs.finalEmail.value.trim().length == 0) {
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Provide Email Body',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }
        this.isLoading = true;

        let hasError = false;
        !this.emailOnly && await updateFinalBody({ htmlString: this.refs.finalAttachment?.value.replaceAll('<br>', '<br/>').replaceAll('<p>', '<div>').replaceAll('</p>', '</div>') || this.refs.finalEmail.value.replaceAll('<br>', '<br/>').replaceAll('<p>', '<div>').replaceAll('</p>', '</div>'), recordId: this.selectedTemp });
        sendEmail({
            toList: this.refs.toLists.value.trim().split(';'),
            ccList: this.refs.ccLists.value.trim().length > 1 ? this.refs.ccLists.value.split(';') : null,
            subject: this.refs.subject.value,
            emailBody: this.refs.finalEmail.value.replaceAll('<br>', '<br/>').replaceAll('<p>', '<div>').replaceAll('</p>', '</div>'),
            orgWideId: this.refs.orgWideId.value,
            attachAsPdf: !this.emailOnly,
            recordId: this.selectedTemp,
            vfPageId: this.pdfOption,
            contendDocIds: this.selectedAttachments,
            createActivity: this.createActivity,
            recordId2: this.recordId,
            isBulk: false
        }).then(result => {
            hasError = !result;
            if (!hasError) {
                /* let apiName1, apiName2, apiName3;
                 let value1, value2, value3;
                 apiName1 = this.refs.field1.value;
                 apiName2 = this.refs.field2.value;
                 apiName3 = this.refs.field3.value;
 
                 value1 = this.refs.field1V.value;
                 value2 = this.refs.field2V.value;
                 value3 = this.refs.field3V.value;
 
                 let fieldObject = {};
                 if (apiName1 && value1) {
                     fieldObject[apiName1] = value1.replaceAll('TODAY()', this.formatDate(new Date())).replaceAll('NOW()', this.formatDate(new Date()));
                 }
                 if (apiName2 && value2) {
                     fieldObject[apiName2] = value2.replaceAll('TODAY()', this.formatDate(new Date())).replaceAll('NOW()', this.formatDate(new Date()));
                 }
                 if (apiName3 && value3) {
                     fieldObject[apiName3] = value3.replaceAll('TODAY()', this.formatDate(new Date())).replaceAll('NOW()', this.formatDate(new Date()));
                 }
 
                 fieldObject['Id'] = this.recordId;
 
                 Object.keys(fieldObject).length > 1 && updateCurrentObject({ fieldObject: fieldObject, objectName: this.objectApiName }).catch(err => {
                     console.log(err);
                     let errorMsg = '';
                     Object.keys(err.body.fieldErrors).forEach(key => {
                         errorMsg += err.body.fieldErrors[key][0].message;
                     });
                     const event = new ShowToastEvent({
                         title: 'Error While Updating Record',
                         message: errorMsg,
                         variant:  'error'
                     });
                     this.dispatchEvent(event);
                 }); */
                this.template.querySelector('lightning-record-edit-form')?.submit();

            }
        }).catch(err => {
            hasError = true;
            console.log(err);
        }).finally(() => {
            this.isLoading = false;
            const event = new ShowToastEvent({
                title: hasError ? 'Error' : 'Success!',
                message: hasError ? 'Error While Sending Email' : 'Email Sent!',
                variant: hasError ? 'error' : 'success'
            });
            this.isShowModal = false;
            this.dispatchEvent(event);
        });
    }

    handleFormError(err) {
        const event = new ShowToastEvent({
            title: 'Error While Updating Record',
            message: err.detail.message,
            variant: 'error'
        });
        this.dispatchEvent(event);
    }

    @track attachments = [];
    columns = [
        { label: 'File Name', fieldName: 'Title', type: 'text' },
        { label: 'Source', fieldName: 'Source', type: 'text' }
        // { label: 'Size (bytes)', fieldName: 'ContentSize', type: 'number' },
        // { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' },
        // {
        //     type: 'button',
        //     typeAttributes: {
        //         label: 'Delete',
        //         name: 'delete',
        //         title: 'Delete',
        //         variant: 'destructive',
        //         iconName: 'utility:delete'
        //     }
        // }
    ];

    handlePdf() {
        console.log('in handlePdf');
        if (this.refs.subject.value.trim().length == 0) {
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Provide Subject',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }
        try{
            this.fetchAttachments();
            this.isShowModal = true;
            this.defaultEmailHandler();
        } catch(error) {
            console.log('error in handlePdf --' + JSON.stringify(error));
        }
    }
    async fetchAttachments() {
        try{
            this.attachments = [];
            console.log('recordId -- ' + this.recordId);
            let data = await getAttachments({ recordId: this.recordId });
            console.log('data -- ' + data);
            let Localattachments = data.map(record => {
                return {
                    id: record.Id,
                    ContendDocId: record.ContentDocument.Id,
                    Title: record.ContentDocument.Title + '.' + record.ContentDocument.FileType,
                    FileType: record.ContentDocument.FileType,
                    ContentSize: record.ContentDocument.ContentSize,
                    CreatedDate: record.ContentDocument.CreatedDate,
                    Source: 'Object Record',
                    allowDelete: true
                };
            });
            if (!this.isCustom){
                this.attachments = Localattachments;
                return;
            }

            console.log('attachemnts:');
            let data2 = await getAttachments({ recordId: this.selectedTemp });
            /*if (data2.length == 0){
                this.attachments = Localattachments;
                return;
            }*/
            console.log('data2:',data2);
            if(data2.length > 0){
                Localattachments = [...Localattachments, ...data2.map(record => {
                    this.selectedAttachmentsIds.push(record.ContentDocument.Id);
                    this.selectedAttachments.push(record.ContentDocument.Id);
                    return {
                        id: record.Id,
                        ContendDocId: record.ContentDocument.Id,
                        Title: record.ContentDocument.Title + '.' + record.ContentDocument.FileType,
                        FileType: record.ContentDocument.FileType,
                        ContentSize: record.ContentDocument.ContentSize,
                        CreatedDate: record.ContentDocument.CreatedDate,
                        Source: 'Email Template',
                        allowDelete: false
                    };
                })];
            }
            

            console.log('Localattachments:',Localattachments);
            /*let data3 = await getDocListAttachments({recordId:this.recordId});
            console.log('data3:',JSON.stringify(data3));
            if(data3.length > 0){
                Localattachments = [...Localattachments, ...data3.map(record => {
                return {
                    id: record.Id,
                    ContendDocId: record.ContentDocument.Id,
                    Title: record.ContentDocument.Title + '.' + record.ContentDocument.FileType,
                    FileType: record.ContentDocument.FileType,
                    ContentSize: record.ContentDocument.ContentSize,
                    CreatedDate: record.ContentDocument.CreatedDate,
                    Source: 'Document Check List',
                    allowDelete: false
                    };
                })];
            }
            console.log('Localattachments:',JSON.stringify(Localattachments));*/

            console.log(this.selectedAttachmentsIds);
            console.log(Localattachments);
            this.attachments = Localattachments;
            console.log('this.attachments:',this.attachments);

        } catch(error) {
            console.log('error in fetchAttachments --' + JSON.stringify(error));
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'delete') {
            row.allowDelete && this.deleteFile(row.id);
            if (!row.allowDelete) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Unable to Delete Standard Attachment. Contact your Salesforce Admin to Delete Standard Attachment.',
                        variant: 'error'
                    })
                );

            }
        }
    }

    deleteFile(contentDocumentId) {
        deleteAttachment({ contentDocumentId: contentDocumentId })
            .then(() => {
                // Show success message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'File deleted successfully',
                        variant: 'success'
                    })
                );
                // Refresh the attachment list
                return this.fetchAttachments();
            })
            .catch(error => {
                // Show error message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error deleting file',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }

    selectedAttachments = [];

    handleRowSelection(event) {
        this.selectedAttachments = event.detail.selectedRows.map(row => row.ContendDocId);
    }

    @track
    selectedAttachmentsIds = [];
    handleUploadFinished(event) {
        try{
            console.log('in handleUploadFinished');
            this.selectedAttachmentsIds = event.detail.files.map(file => file.documentId);
            console.log('this.selectedAttachmentsIds:', JSON.stringify(this.selectedAttachmentsIds[0]));
            this.selectedAttachments.push(this.selectedAttachmentsIds[0]);
            this.fetchAttachments();
        } catch(error) {
            console.log(JSON.stringify(error));
        }
    }
    hideModalBox() {
        this.isShowModal = false;
    }
}