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
import generatePDF from '@salesforce/apex/SchemaUtil.generatePDFBulk';
import generatePDFOnRecord from '@salesforce/apex/SchemaUtil.generatePDFOnRecordBulk';
import getPdfOptionsBulk from '@salesforce/apex/SchemaUtil.getPdfOptionsBulk';
import generatePgetAllOrgWideEmailAddressDF from '@salesforce/apex/SchemaUtil.getAllOrgWideEmailAddress';
import sendEmail from '@salesforce/apex/SchemaUtil.sendEmail';
import getContactLookupValues from '@salesforce/apex/SchemaUtil.getContactLookupValues';
import getAttachmentsBulk from '@salesforce/apex/SchemaUtil.getAttachmentsBulk';
import getAttachments from '@salesforce/apex/SchemaUtil.getAttachments';
import deleteBulkCustomTemplateRecords from '@salesforce/apex/SchemaUtil.deleteBulkCustomTemplateRecords';
import massUpdateFinalBodyOnBulkCustomTemplateRecords from '@salesforce/apex/SchemaUtil.massUpdateFinalBodyOnBulkCustomTemplateRecords';
import massUpdateFinalBody from '@salesforce/apex/SchemaUtil.massUpdateFinalBody';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import deleteAttachment from '@salesforce/apex/SchemaUtil.deleteAttachment';
import FOLDER_FIELD from "@salesforce/schema/Custom_Email_Template__c.Folder__c";
import getCustomEmailById from '@salesforce/apex/SchemaUtil.getCustomEmailById';
import getObjectNameFromId from '@salesforce/apex/SchemaUtil.getObjectNameFromId';

export default class BulkEmailTemplate extends LightningElement {
    @api recordIds = '';
    objectApiName;
    contactList = [];
    isLoading = true;
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

    emailSubject = '';

    emailTemps;
    emailTempsCustom;
    emailBody;
    attachmentBody;
    matches = [];
    selectedObj;

    formatString='MM/DD/YYYY';

    createActivity = false;
    generatePdfClicked = false;


    @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: FOLDER_FIELD })
    folderPickListMeta;

    // get selectedRecords() {
    //     console.log('this.recordIds at 64 - ' + this.recordIds);
    //     return this.recordIds.length < 15 ? [] : this.recordIds?.split(',') ?? [];
    // }

    get selectedRecords() {
        if (!this.recordIds) return [];

        let ids = this.recordIds;

        if (ids.startsWith("[") && ids.endsWith("]")) {
            ids = ids.slice(1, -1);  // remove [ and ]
        }

        return ids
            .split(',')
            .map(id => id.trim())
            .filter(id => id.length > 0);
    }

    get picklist1() {
        return [{ label: 'Current User', value: 'Current User' }, ...Object.keys(this.fieldMapByObject).sort().map(obj => {
            return { label: obj, value: obj };
        })];
    }

    @wire(getAllFieldsByObject, { objectApiName: '$objectApiName' })
    wiredData({ error, data }) {
        if (data) {
            this.isLoading = true;
            this.processData(data);
            getUpdatableFieldsByObject({ objectApiName: this.objectApiName })
                .then(result => {
                    this.fieldByType = result;
                    if (this.selectedRecords.length > 0)
                        this.isLoading = false;
                });
        } else if (error) {
            console.error('Error: wiredData1', error);
        }
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

    @wire(getPdfOptionsBulk, { objectApiName: '$objectApiName' })
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
    }

    dateFormatOptions = [
        { label: 'MM/DD/YYYY', value: 'MM/DD/YYYY' },
        { label: 'DD-MM-YYYY', value: 'DD-MM-YYYY' },
        { label: 'YYYY/MM/DD', value: 'YYYY/MM/DD' },
        { label: 'DD MMM, YYYY', value: 'DD MMM, YYYY' },
        { label: 'MMMM DD, YYYY', value: 'MMMM DD, YYYY' },
        { label: 'MMMM D, YYYY', value: 'MMMM D, YYYY' }
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

    handleDateFormatChange(event){
        this.formatString = event.target.value;
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

    emailTempsCustomTemp;
    @wire(getAllEmailTempsCustom, { folder: '$folder', objectApiName: '$objectApiName' })
    wiredData3({ error, data }) {
        if (data) {
            this.emailTempsCustomTemp = data;
            this.emailTempsCustom = data.map(item => {
                return {
                    label: item.Name, value: item.Id, body: item.Body__c, subject: item.Subject__c, Default_Field_Name_1__c: item.Default_Field_Name_1__c, Default_Field_Name_2__c: item.Default_Field_Name_2__c, Default_Field_Name_3__c: item.Default_Field_Name_3__c,
                    Default_Field_Value_1__c: item.Default_Field_Value_1__c, Default_Field_Value_2__c: item.Default_Field_Value_2__c, Default_Field_Value_3__c: item.Default_Field_Value_3__c,
                    Pdf_Template__c: item.Pdf_Template__c, Default_Date_Format__c : item.Default_Date_Format__c, Default_Currency_Format__c : item.Default_Currency_Format__c,
                    Default_Decimal_Format__c : item.Default_Decimal_Format__c, Default_Boolean_Format__c : item.Default_Boolean_Format__c
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
        const fullMonthNames = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        ];
        const shortMonthNames = fullMonthNames.map(m => m.substring(0, 3));
        const monthIndex = parseInt(month, 10) - 1;

        let formattedDate = '';

        switch (formatString) {
            case 'MM/DD/YYYY':
                formattedDate = `${month}/${day}/${year}`;
                break;
            case 'DD-MM-YYYY':
                formattedDate = `${day}-${month}-${year}`;
                break;
            case 'YYYY/MM/DD':
                formattedDate = `${year}/${month}/${day}`;
                break;
            case 'DD MMM, YYYY':
                formattedDate = `${day} ${shortMonthNames[monthIndex]}, ${year}`;
                break;
            case 'MMMM DD, YYYY':
                formattedDate = `${fullMonthNames[monthIndex]} ${day}, ${year}`;
                break;
            case 'MMMM D, YYYY':
                let trimDay = day;
                let dayString = day.toString();
                if(dayString.indexOf("0") == 0) {
                    trimDay = dayString.substring(1, dayString.length);
                }
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
        
        const textToCopy = this.fieldApiName;

        if (!textToCopy) {
            console.error("No text to copy!");
            return;
        }

        if (navigator.clipboard && window.isSecureContext) {
            // Modern, secure way
            navigator.clipboard.writeText(textToCopy)
                .then(() => {
                    console.log('Copied to clipboard successfully!');
                })
                .catch(err => {
                    console.error('Clipboard copy failed!', err);
                     let textArea = document.createElement("textarea");
            textArea.value = textToCopy;
            document.body.appendChild(textArea);
            textArea.focus();
            textArea.select();

            try {
                let successful = document.execCommand('copy');
                if (successful) {
                    console.log('Fallback copy successful!');
                } else {
                    console.error('Fallback copy failed!');
                }
            } catch (err) {
                console.error('Fallback copy failed!', err);
            }

            document.body.removeChild(textArea);
                });
        } else {
            // Fallback for unsupported browsers
            let textArea = document.createElement("textarea");
            textArea.value = textToCopy;
            document.body.appendChild(textArea);
            textArea.focus();
            textArea.select();

            try {
                let successful = document.execCommand('copy');
                if (successful) {
                    console.log('Fallback copy successful!');
                } else {
                    console.error('Fallback copy failed!');
                }
            } catch (err) {
                console.error('Fallback copy failed!', err);
            }

            document.body.removeChild(textArea);
        }
    }

    handleChange2(event) {
        console.log(event.target.value);
        this.fieldApiName = `{${event.target.value}}`;
        this.handleDataFormatting(event.target.value);
        // const unsecuredCopyToClipboard = (text) => { const textArea = document.createElement("textarea"); textArea.value = text; document.body.appendChild(textArea); textArea.focus(); textArea.select(); try { document.execCommand('copy') } catch (err) { console.error('Unable to copy to clipboard', err) } document.body.removeChild(textArea) };
        // /**
        //  * Copies the text passed as param to the system clipboard
        //  * Check if using HTTPS and  navigator.clipboard is available
        //  * Then uses standard clipboard API, otherwise uses fallback
        // */
        // if (window.isSecureContext && navigator.clipboard) {
        //     navigator.clipboard.writeText(this.fieldApiName);
        // } else {
        //     unsecuredCopyToClipboard(this.fieldApiName);
        // }
        //navigator.clipboard.writeText(this.fieldApiName);
        /*const textToCopy = this.fieldApiName;

        if (!textToCopy) {
            console.error("No text to copy!");
            return;
        }

        if (navigator.clipboard && window.isSecureContext) {
            // Modern, secure way
            navigator.clipboard.writeText(textToCopy)
                .then(() => {
                    console.log('Copied to clipboard successfully!');
                })
                .catch(err => {
                    console.error('Clipboard copy failed!', err);
                     let textArea = document.createElement("textarea");
            textArea.value = textToCopy;
            document.body.appendChild(textArea);
            textArea.focus();
            textArea.select();

            try {
                let successful = document.execCommand('copy');
                if (successful) {
                    console.log('Fallback copy successful!');
                } else {
                    console.error('Fallback copy failed!');
                }
            } catch (err) {
                console.error('Fallback copy failed!', err);
            }

            document.body.removeChild(textArea);
                });
        } else {
            // Fallback for unsupported browsers
            let textArea = document.createElement("textarea");
            textArea.value = textToCopy;
            document.body.appendChild(textArea);
            textArea.focus();
            textArea.select();

            try {
                let successful = document.execCommand('copy');
                if (successful) {
                    console.log('Fallback copy successful!');
                } else {
                    console.error('Fallback copy failed!');
                }
            } catch (err) {
                console.error('Fallback copy failed!', err);
            }

            document.body.removeChild(textArea);
        }*/
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
        this.folder = null;
    }


    allowSave = false;
    async handleChange3(event) {
        try{
            this.isLoading = true;
            this.matches = [];
            this.selectedTemp = event.target.value;
            await deleteBulkCustomTemplateRecords({ customEmailTempId: this.selectedTemp });
            console.log('this.selectedTemp', this.selectedTemp);
            this.allowSave = this.emailType == 'custom' ? await checkEditPermission({ recordId: this.selectedTemp }) : null;
            let customTemplates = await getCustomEmailById({ Id: this.selectedTemp });
            console.log(' customTemplates ', JSON.stringify(customTemplates));
            this.emailBody = this.emailType == 'custom' ? customTemplates.Body__c : await generateStringBody({ recordId: this.recordId, tempId: this.selectedTemp });
            console.log(' emailBody ', this.emailBody);
            this.emailSubject = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).subject : this.emailTemps.find(emailTemp => emailTemp.value == this.selectedTemp).subject;
            this.attachmentBody = this.emailBody;
            this.emailType == 'custom' && this.checkFields(this.emailBody, true);
            this.emailType == 'custom' && this.checkFields(this.emailSubject, true);

            this.field1 = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Default_Field_Name_1__c : null;
            this.field2 = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Default_Field_Name_2__c : null;
            this.field3 = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Default_Field_Name_3__c : null;

            this.value1 = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Default_Field_Value_1__c : null;
            this.value2 = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Default_Field_Value_2__c : null;
            this.value3 = this.emailType == 'custom' ? this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Default_Field_Value_3__c : null;
            this.pdfOption = this.emailTempsCustom.find(emailTemp => emailTemp.value == this.selectedTemp).Pdf_Template__c;

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
            this.isLoading = false;

        }catch(error){
            console.log('line no. 584 --'+JSON.stringify(error));
        }
        
    }

    appendTo(event) {
        this.refs.toLists.value = event.target.value + (this.refs.toLists.value ? ';' : '') + this.refs.toLists.value;
    }

    appendCC(event) {
        this.refs.ccLists.value = event.target.value + (this.refs.ccLists.value ? ';' : '') + this.refs.ccLists.value;
    }

    emailBodyChange(){
        this.emailBody = this.refs.emailBodyText.value;
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
    }

    async upsertEmailTemplate() {
        this.isLoading = true;
        return await upsertEmailTemp({ tempId: this.createNewTemplate ? null : this.selectedTemp, emailBody: this.refs.emailBodyText.value, subject: this.refs.subject.value, objectName: this.objectApiName, pdfTemplate: this.pdfOption });
    }

    checkFields(text, callHandleClick) {
        //this.isLoading = true;

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
        console.log('this.matches ---' + this.matches);
        //this.isLoading = false;
    }

    handleSperateToggle(event) {
        this.sperateBody = event.target.checked;
        //this.handleClick(false);
    }

    replaceGenericTaggersValue(body) {
        let keyForToday = 'TODAY()';
        const regex3ForToday = /\{TODAY\(\)\}:[^}]*\}/g;
        console.log('body at 718 -- ' + body);
        let matches = [...body.matchAll(regex3ForToday)];
        console.log('matches at 719 -- ' + matches);
        for (const match of matches) {
            let testMatch = match.toString();
            const format = testMatch.substring(testMatch.indexOf(':') + 1, testMatch.length-1);
            console.log('format at 724 -- ' + format);
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

    formatAddress({ street, city, state, postalCode, country }) {
        const formattedStreet = (street || '').replace(/\r?\n/g, '<br/>');
        const cityLine = [city, state, postalCode].filter(Boolean).join(', ');
        return [formattedStreet, cityLine, country].filter(Boolean).join('<br/>');
    }

    async generateFinalBodyMap(isEmail) {
        const finalBodyMap = {};
        try{
            console.log('this.selectedRecords:', JSON.stringify(this.selectedRecords));
             await Promise.all(
                this.selectedRecords.map(async (recordId) => {
                    const body = await this.generateAttachmentBody(recordId, isEmail);
                    finalBodyMap[recordId] = body;
                })
            );
        }catch(error) {
            console.log('error in generateFinalBodyMap -- ' + error);
        }
       
        return finalBodyMap;
    }

    async generateAttachmentBody(recordId, isEmail) {
        this.validateFields();

        let finalAttachmentBody;
        
        if (this.matches.length == 0) {
            setTimeout(() => {
                let bodyText = this.sperateBody ? this.attachmentBody : this.emailBody;
                bodyText = this.replaceGenericTaggersValue(bodyText);
                return bodyText;         
            }, 200);
        }

        try {
            //this.isLoading = true;
            let sObjectList = await queryData({
                fieldList: this.matches,
                objectApiName: this.objectApiName,
                recordId: recordId
            });
            console.log('sObjectList -- ' + sObjectList);
            if (!sObjectList || sObjectList.length === 0) {
                throw new Error("No data found");
            }
            let sObject = sObjectList[0];
            this.recordTypeId = sObjectList[0].RecordTypeId;


            let body = this.refs.emailBodyText.value;
            let attachmentBOdy = this.refs.attachmentBodyText?.value || this.attachmentBody;
            //let attachmentBOdy = this.sperateBody ? this.refs.attachmentBodyText?.value || this.attachmentBody : null;
            body = this.replaceGenericTaggersValue(body);
            console.log('body at 1052 -- ' + body);
            console.log('attachmentBOdy at 1053 -- ' + attachmentBOdy);
            attachmentBOdy = this.replaceGenericTaggersValue(attachmentBOdy);
            console.log('attachmentBOdy at 1053 -- ' + attachmentBOdy);
            console.log('body at 1049 -- ' + body);
            for (const key in sObject) {
                console.log('key at 1077 --' + key);
                if (key.endsWith('__r') || key.endsWith('__pr') || (typeof sObject[key] == 'object' && this.fieldTypeMap[key.toLowerCase()] != 'ADDRESS')) {
                    let sObject2 = sObject[key];
                    for (const key2 in sObject2) {
                        if (Object.hasOwnProperty.call(sObject, key)) {
                            let newKey = key + '.' + key2.toLowerCase();
                            console.log('newKey at 1083 --' + newKey);
                            if(this.fieldTypeMap[newKey] == 'DATETIME' || this.fieldTypeMap[newKey] == 'DATE' 
                                || this.fieldTypeMap[newKey] == 'CURRENCY' || this.fieldTypeMap[newKey] == 'DOUBLE'
                                || this.fieldTypeMap[newKey] == 'BOOLEAN') {
                                // || (this.fieldTypeMap[newKey] == 'TEXTAREA' && sObject2[key2].includes('img'))
                                const normalizedKey = newKey.replace(/_/g, '_?').toLowerCase();
                                const regexPattern = `\\{(${normalizedKey})\\}:([^}]+)\\}`;
                                const regex3 = new RegExp(regexPattern, 'gi');

                                let matches = [...body.matchAll(regex3)];
                                for (const match of matches) {
                                    let tempFormatedValue = this.replaceTagWithRespectiveValue(newKey, match, sObject2[key2], false);
                                    body = body.replace(match[0], tempFormatedValue);
                                    attachmentBOdy = attachmentBOdy.replace(match[0], tempFormatedValue);
                                    this.refs.subject.value = this.refs.subject.value.replace(match[0], '' + sObject2[key2]);
                                }
                            } else{
                                console.log('at line no. 1100');
                                let newKey = key + '.' + key2.toLowerCase();
                                console.log('newKey at 1106 --' + newKey);
                                const regex2 = new RegExp(`{${newKey.replace(/_/g, '_?').toLowerCase()}}`, 'gi');
                                let tempValue;
                                console.log('this.fieldTypeMap[newKey] -- ' + this.fieldTypeMap[newKey]);
                                //console.log('this.fieldTypeMap[key2] -- ' + this.fieldTypeMap[key2]);
                                if(this.fieldTypeMap[newKey] == 'ADDRESS') {
                                    console.log()
                                    const address = {
                                        street: sObject2[key2].street,
                                        city: sObject2[key2].city,
                                        state: sObject2[key2].state,
                                        postalCode: sObject2[key2].postalCode,
                                        country: sObject2[key2].country
                                    };
                                    tempValue = this.formatAddress(address);
                                } else {
                                    console.log('at 1120');
                                    tempValue = this.formatedValue(newKey, '' + sObject2[key2]);
                                    console.log('at 1122');
                                }
                                if(tempValue.includes('\n')) {
                                    tempValue = (tempValue || '').replace(/\r?\n/g, '<br/>');
                                }
                                console.log('body at 1127-- ' + body);
                                body = body.replaceAll(regex2, tempValue);
                                console.log('body at 1129--- '+body);
                                attachmentBOdy = attachmentBOdy?.replaceAll(regex2, tempValue);
                                this.refs.subject.value = this.refs.subject.value.replace(regex2, '' + sObject2[key2]);
                            }
                        }
                    }
                }
                else {
                    if (Object.hasOwnProperty.call(sObject, key)) {
                        if(this.fieldTypeMap[key.toLowerCase()] == 'DATETIME' || this.fieldTypeMap[key.toLowerCase()] == 'DATE' 
                         || this.fieldTypeMap[key.toLowerCase()] == 'CURRENCY' || this.fieldTypeMap[key.toLowerCase()] == 'DOUBLE'
                         || this.fieldTypeMap[key.toLowerCase()] == 'BOOLEAN') {
                         // || (this.fieldTypeMap[key.toLowerCase()] == 'TEXTAREA' && sObject[key].includes('img'))
                         
                            const normalizedKey = key.replace(/_/g, '_?').toLowerCase();
                           
                            console.log('in itself field block ---' + body);
                            const regexPattern = `\\{(${normalizedKey})\\}:([^}]+)\\}`;
                            const regex3 = new RegExp(regexPattern, 'gi');

                            let matches = [...body.matchAll(regex3)];
                            console.log('matches at 1093 --- ' + matches);
                            for (const match of matches) {
                                let tempFormatedValue = this.replaceTagWithRespectiveValue(key, match, sObject[key], true);
                                body = body.replace(match[0], tempFormatedValue);
                                attachmentBOdy = attachmentBOdy.replace(match[0], tempFormatedValue);
                                this.refs.subject.value = this.refs.subject.value.replace(match[0], '' + sObject[key]);
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
                                tempValue = this.formatedValue(key, '' + sObject[key]);
                            }
                            if(tempValue.includes('\n')) {
                                tempValue = (tempValue || '').replace(/\r?\n/g, '<br/>');
                            }
                            body = body.replaceAll(regex, tempValue);
                            attachmentBOdy = attachmentBOdy?.replaceAll(regex, tempValue);
                            this.refs.subject.value = this.refs.subject.value.replace(regex, '' + sObject[key]);
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
                                body = body.replaceAll(regex2, this.formatedValue(newKey, '' + sObject2[key2]));
                                attachmentBOdy = attachmentBOdy?.replaceAll(regex2, this.formatedValue(newKey, '' + sObject2[key2]));
                                this.refs.subject.value = this.refs.subject.value.replace(regex2, '' + sObject2[key2]);
                            }
                        }
                    }
                    else {
                        if (Object.hasOwnProperty.call(sObjectList[1], key)) {
                            let newKey = 'CurrentUser.' + key;
                            let fieldTypeMapKey = 'CreatedBy.' + key.toLowerCase();
                            if(this.fieldTypeMap[fieldTypeMapKey] == 'DATETIME' || this.fieldTypeMap[fieldTypeMapKey] == 'DATE' 
                            || this.fieldTypeMap[fieldTypeMapKey] == 'CURRENCY' || this.fieldTypeMap[fieldTypeMapKey] == 'DOUBLE'
                            || this.fieldTypeMap[fieldTypeMapKey] == 'BOOLEAN') {
                            // || (this.fieldTypeMap[fieldTypeMapKey] == 'TEXTAREA' && sObjectList[1][key].includes('img'))
                            
                                const normalizedKey = newKey.replace(/_/g, '_?').toLowerCase();
                            
                                const regexPattern = `\\{(${normalizedKey})\\}:([^}]+)\\}`;
                                const regex3 = new RegExp(regexPattern, 'gi');

                                let matches = [...body.matchAll(regex3)];
                                
                                for (const match of matches) {
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
                                        tempFormatedValue = this.formatedValue('Owner.' + key.toLowerCase(), '' + sObjectList[1][key]);
                                    }
                                    
                                    body = body.replace(match[0], tempFormatedValue);
                                    attachmentBOdy = attachmentBOdy.replace(match[0], tempFormatedValue);
                                    this.refs.subject.value = this.refs.subject.value.replace(match[0], '' + sObjectList[1][key]);  
                                }
                            } else {
                                let newKey = 'CurrentUser.' + key;
                                const regex = new RegExp(`{${newKey.replace(/_/g, '_?').toLowerCase()}}`, 'gi');
                                body = body.replaceAll(regex, this.formatedValue('Owner.' + key.toLowerCase(), '' + sObjectList[1][key]));
                                attachmentBOdy = attachmentBOdy?.replaceAll(regex, this.formatedValue('Owner.' + key.toLowerCase(), '' + sObjectList[1][key]));
                                this.refs.subject.value = this.refs.subject.value.replace(regex, '' + sObjectList[1][key]);
                            }
                            
                        }
                    }
                }
            }

            //this.isLoading = false;
            const regex = new RegExp('{([^}]*)}(:[^}]*)?}?', 'gi');
            body = body.replaceAll(regex, '');
            this.refs.subject.value = this.refs.subject.value.replaceAll(regex, '');
            finalAttachmentBody = isEmail ? body.replaceAll(regex, '') : (this.sperateBody && !isEmail ? attachmentBody.replaceAll(regex, '') : body.replaceAll(regex, ''));
        } catch (err) {
            console.error("Error in generateAttachmentBody:", err);
            finalAttachmentBody = isEmail ? this.refs.emailBodyText.value : (this.sperateBody && !isEmail ? this.refs.attachmentBodyText?.value : this.refs.emailBodyText.value);

            this.dispatchEvent(new ShowToastEvent({
                title: "Error",
                message: err.body?.message || err.message,
                variant: "error"
            }));
        } finally {
            //this.isLoading = false;
            this.matches = [];
        }

        return finalAttachmentBody;
    }

    validateFields() {
        this.checkFields(this.refs?.emailBodyText?.value || this.emailBody, false);
        if (this.sperateBody) {
            this.checkFields(this.refs.attachmentBodyText?.value || this.attachmentBody, false);
        }
        this.checkFields(this.refs.subject.value, false);
    }

    replaceTodayPlaceholder(text) {
        return text?.replaceAll("TODAY()", this.formatDateUI(new Date(), true));
    }

    async generatePDF() {
        try{
            this.generatePdfClicked = true;
            this.isLoading = true;
            await deleteBulkCustomTemplateRecords({ customEmailTempId: this.selectedTemp });
            //await updateFinalBody({ htmlString: this.refs.finalAttachment?.value.replaceAll('<br>', '<br/>').replaceAll('<p>', '<div>').replaceAll('</p>', '</div>') || this.refs.finalEmail.value.replaceAll('<br>', '<br/>').replaceAll('<p>', '<div>').replaceAll('</p>', '</div>'), recordId: this.selectedTemp });
            await massUpdateFinalBody({ customEmailTempId: this.selectedTemp, bodyMap: await this.generateFinalBodyMap(false) });
            const base64Data = await generatePDF({ recordId: this.selectedTemp, vfPageId: this.pdfOption });
            //window.open(fileUrl, '_blank');
            console.log('base64Data -- ' + base64Data);
            const byteCharacters = atob(base64Data);
            const byteNumbers = new Array(byteCharacters.length);
            for (let i = 0; i < byteCharacters.length; i++) {
                byteNumbers[i] = byteCharacters.charCodeAt(i);
            }
            const byteArray = new Uint8Array(byteNumbers);
            const fileBlob = new Blob([byteArray], { type: 'application/pdf' });

            const blobUrl = URL.createObjectURL(fileBlob);
            window.open(blobUrl, '_blank');
            this.isLoading = false;
        }catch(error){
            console.log('error at 1308 --' + JSON.stringify(error));
        }
    }

    async generatePDFOnRecord() {
        try{
            this.isLoading = true;
            //await deleteBulkCustomTemplateRecords({ customEmailTempId: this.selectedTemp });
            let bodyMap = await this.generateFinalBodyMap(false);
            console.log('FinalBodyMap=>' + bodyMap);
            await massUpdateFinalBodyOnBulkCustomTemplateRecords({ customEmailTempId: this.selectedTemp, bodyMap: bodyMap });

            await generatePDFOnRecord({ cerecordId: this.selectedTemp, vfPageId: this.pdfOption, selectedRecords: this.selectedRecords });
            const event = new ShowToastEvent({
                title: 'Success',
                message: 'File Saved!!',
                variant: 'success'
            });
            this.dispatchEvent(event);
            this.isLoading = false;
        }catch(error) {
            console.log('error at 1341 --' + JSON.stringify(error));
        }  
    }

    async goBack() {
        await deleteBulkCustomTemplateRecords({customEmailTempId: this.selectedTemp});
        window.history.back();
    }

    async connectedCallback() {
        console.log('recordIds: ', this.recordIds);
        let idArray = this.recordIds.replace('[', '').replace(']', '').split(',');
        let firstId = idArray[0].trim();
        console.log('firstId: ', firstId);
        console.log('split', JSON.stringify(this.recordIds?.split(';') ?? []));
        this.objectApiName = await getObjectNameFromId({recordId: firstId});
        console.log('objectApiName: ', this.objectApiName);
    }
    async disconnectedCallback() {
        console.log('in disconnectedCallback');
        await deleteBulkCustomTemplateRecords({customEmailTempId: this.selectedTemp});
    }

    async sendMail() {
        //await deleteBulkCustomTemplateRecords({ customEmailTempId: this.selectedTemp });
        if (this.refs.toLists.value == '' || this.refs.toLists.value.trim().split(';').length == 0) {
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Provide To Email Address List',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }
        console.log('this.refs.toLists:', this.refs.toLists);

        if (this.refs.subject.value.trim().length == 0) {
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Provide Subject',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }
        console.log('this.refs.subject:', this.refs.subject);

        if (this.refs.finalEmail2.value.trim().length == 0) {
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Provide Email Body',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }
        this.isLoading = true;
        console.log('this.refs.finalEmail2:', this.refs.finalEmail2);

        let hasError = false;
        let bodyMap = await this.generateFinalBodyMap(true);
        console.log('FinalBodyMap=>' + JSON.stringify(bodyMap));
        await massUpdateFinalBodyOnBulkCustomTemplateRecords({ customEmailTempId: this.selectedTemp, bodyMap: bodyMap });
        sendEmail({
            toList: this.refs.toLists.value.trim().split(';'),
            ccList: this.refs.ccLists.value.trim().length > 1 ? this.refs.ccLists.value.split(';') : null,
            subject: this.refs.subject.value,
            emailBody: this.refs.finalEmail2.value.replaceAll('<br>', '<br/>').replaceAll('<p>', '<div>').replaceAll('</p>', '</div>'),
            orgWideId: this.refs.orgWideId.value,
            attachAsPdf: true,
            recordId: this.selectedTemp,
            vfPageId: this.pdfOption,
            contendDocIds: this.selectedAttachments,
            createActivity: this.createActivity,
            selectedRecords: this.selectedRecords,
            isBulk: false
        }).then(result => {
            hasError = !result;
            if (!hasError) {
                this.template.querySelector('lightning-record-edit-form')?.submit();
            }
        }).catch(err => {
            hasError = true;
            console.log('line no 1438 ---' + err);
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
    ];

    handlePdf() {
        if (this.refs.subject.value.trim().length == 0) {
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Provide Subject',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }
        this.fetchAttachments();
        this.isShowModal = true;
    }
    async fetchAttachments() {
        console.log('in fetchAttachments:', JSON.stringify(this.selectedRecords));
        this.attachments = [];
        let data = await getAttachmentsBulk({ selectedRecords: this.selectedRecords });
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
        if (!this.isCustom)
            return;

        let data2 = await getAttachments({ recordId: this.selectedTemp });
        if (data2.length == 0)
            return;
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

        console.log('line no. 1516 --' + this.selectedAttachmentsIds);
        console.log(JSON.stringify(Localattachments));
        this.attachments = Localattachments;

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
        this.selectedAttachmentsIds = event.detail.files.map(file => file.documentId);
        this.fetchAttachments();
    }
    hideModalBox() {
        this.isShowModal = false;
    }
}