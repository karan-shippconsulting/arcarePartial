import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPDFTempList from '@salesforce/apex/DynamicMassPrintController.getPDFTempList';
import sendBulkEmail from '@salesforce/apex/DynamicMassPrintController.sendBulkEmail';
import updateBulkPrint from '@salesforce/apex/DynamicMassPrintController.updateBulkPrint';
import fetchRecords from '@salesforce/apex/DynamicMassPrintController.fetchRecords';
import { NavigationMixin } from 'lightning/navigation';

export default class DynamicEmailMass extends NavigationMixin(LightningElement) {
    @api recordIds = [];
    @api objectApiName;
    selectedTemp;
    matches = [];
    showIframe = false;
    isEmail = false;
    isPDF = false;
    iframeURL = '';
    templateListOriginal=[];
    isToast = false;
    isLoaded = false;

    typeOptions = [
                    {label:'Email',value:'Email'},
                    {label:'Print',value:'Print'}
                ];

    templateList = [];
    get printRecords() {
        return JSON.stringify(this.recordIds);
    }

    handleTypeChange(event){
        this.templateList = this.templateListOriginal.filter(temp => temp.Type__c == event.target.value);
        this.isEmail = event.target.value == 'Email';
        this.isPDF = !this.isEmail;
    }

    connectedCallback() {
        if (!this.recordIds || this.recordIds == '' ||this.recordIds.length == 0) {
            const event = new ShowToastEvent({
                title: 'Error!!',
                message: 'No Records Selected.',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }

        if (!this.objectApiName) {
            const event = new ShowToastEvent({
                title: 'Error!!',
                message: 'Object Api Name is Missing in VF Page.',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }

        this.recordIds = this.recordIds.replace(/'/g, '"').replace(/\[(.*?)\]/, '["$1"]');
        this.recordIds = JSON.parse(this.recordIds.replace(/, /g, '", "'));

        getPDFTempList({ objectName: this.objectApiName })
            .then(pdfList => {
                this.templateListOriginal = pdfList;
            });
    }

    get templateListOptions(){
        return this.templateList.map(item => {
                    return { label: item.Name, value: item.Id };
                });
    }

    get hasPDFData() {
        return this.templateListOriginal.length > 0;
    }

    handleTemplateChange(event) {
        this.selectedTemp = this.templateList.find(temp => temp.Id == event.detail.value);
        if(this.isEmail)
            this.refs.emailBodyText.value = this.selectedTemp.Email_Body__c;
    }

    get fromEmail(){
        return this.selectedTemp?.Organization_WIde_Email__c;
    }

    get emailSubject(){
        return this.selectedTemp?.Email_Subject__c;

    }

    async handleEmail(){
        this.isToast = true;
        this.isLoaded = true;
        this.matches = [];
        this.checkFields(this.selectedTemp.Email_Body__c);
        //let foundRecords = await fetchRecords({recordList:this.recordIds,queryFields:this.matches,objectApiName:this.objectApiName});
        //console.log(foundRecords);
        
        try {
            let isSuccess = await sendBulkEmail({recordList:this.recordIds,templateId:this.selectedTemp.Id,objectApiName:this.objectApiName});
            //this.template.querySelector('c-toastout').show('Operation Successful!', 'success');
            await this.scrollToTop();
            let msg = 'Operation Successful! All emails were sent.';
            this.template.querySelector('c-toastout').show(msg, 'success');  
            //setInterval(this.handleCancel(), 3000);
        }
        catch(err) {
            await this.scrollToTop();
            //this.isToast = true;
            let msg = 'Operation failed. ' + err.body.message;
            this.template.querySelector('c-toastout').show(msg, 'error');  
        }
         this.isLoaded = false;
    }

    async scrollToTop(){
        const scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);
    }

    handlePDF(){
        let formUrl;
        if(this.selectedTemp.Preview_Parameters_To_Send__c){
            formUrl = this.selectedTemp.Visual_Force_Page_Name__c + '?' + this.selectedTemp.Preview_Parameters_To_Send__c + '&bulkIds=';
        } else{
            formUrl = this.selectedTemp.Visual_Force_Page_Name__c+'?bulkIds=';
        }
        formUrl += this.recordIds.join(','); 
        this.iframeURL = formUrl;
        window.open(this.iframeURL);
        this.showIframe = true;
    }

    async handlePDFAndUpdate(){
        this.handlePDF();
         this.isToast = true;
         try {
            await updateBulkPrint({recordList:this.recordIds,templateId:this.selectedTemp.Id,objectApiName:this.objectApiName});
            await this.scrollToTop();
            let msg = 'Operation Successful! Fields Updated.';
            this.template.querySelector('c-toastout').show(msg, 'success');  
        }
        catch(err) {
            await this.scrollToTop();
            let msg = 'Operation failed. ' + err.body.message;
            this.template.querySelector('c-toastout').show(msg, 'error');  
        }
    }

     checkFields(text) {
        //this.isLoading = true;

        const regex = /{([^}]*)}/g;

        let match;
        while ((match = regex.exec(text)) !== null) {
            if (!this.matches.includes(match[1].toLowerCase()))
                this.matches.push(match[1].toLowerCase());
        }
        //this.isLoading = false;
    }

    handleCancel(){
        history.back();
        //window.open('/lightning/o/Opportunity/list?filterName=__Recent',"_self");
    }

}