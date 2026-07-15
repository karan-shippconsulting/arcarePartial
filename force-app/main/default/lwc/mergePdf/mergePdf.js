import { LightningElement, api,wire } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import pdflib from "@salesforce/resourceUrl/PdfLib";
import { loadScript } from "lightning/platformResourceLoader";
import getData from '@salesforce/apex/SignPdfController.getData';
import getRecordsId from '@salesforce/apex/SignPdfController.getRecordsId';
import attachPdfOnRecord from '@salesforce/apex/SignPdfController.attachPdfOnRecord';


export default class CreatePDF extends NavigationMixin(LightningElement) {
@api recordId;
docData = []
error
ids ='' 

@wire(getRecordsId, {
    recordId: '$recordId'
}) wiredContacts({ error, data }) {
    if (data) {
        this.ids = data
        console.log('data Id '+this.ids)
    }
} 

async renderedCallback() {
    loadScript(this, pdflib).then(() => {
    });

    console.log('recode ud  ' + this.recordId)
    if (this.recordId) {
        await getData({ recordId: this.recordId })
            .then((result) => {
                this.docData = JSON.parse(JSON.stringify(result));
                console.log('Size of File are ' + this.docData.length);
                this.error = undefined;
//                   this.createPdf()
            })
            .catch((error) => {
                console.log('error while calling ' +JSON.stringify( error))
            }
            )
    }
}

async createPdf() {
    const pdfDoc = await PDFLib.PDFDocument.create();
    console.log('pdfDoc is ', JSON.stringify(pdfDoc))
    if (this.docData.length < 1)
        return


    var tempBytes = Uint8Array.from(atob(this.docData[0]), (c) => c.charCodeAt(0));
    console.log('tempBytes', tempBytes)
    const [firstPage] = await pdfDoc.embedPdf(tempBytes);
    const americanFlagDims = firstPage.scale(0.99);
    var page = pdfDoc.addPage();
    console.log('page is ', page)

    page.drawPage(firstPage, {
        ...americanFlagDims,
        x: page.getWidth() - americanFlagDims.width,
        y: page.getHeight() - americanFlagDims.height - 10,
    });


    if (this.docData.length > 1) {
        for (let i = 1; i < this.docData.length; i++) {
            tempBytes = Uint8Array.from(atob(this.docData[i]), (c) => c.charCodeAt(0));
            console.log('tempBtes>> ', tempBytes)
            page = pdfDoc.addPage();
            const usConstitutionPdf = await PDFLib.PDFDocument.load(tempBytes);
            console.log('After ', usConstitutionPdf, usConstitutionPdf.getPages())
            const preamble = await pdfDoc.embedPage(usConstitutionPdf.getPages()[0]);
            console.log(' Inside page is ', page)

            const preambleDims = preamble.scale(0.95);

            page.drawPage(preamble, {
                ...preambleDims,
                x: page.getWidth() - americanFlagDims.width,
                y: page.getHeight() - americanFlagDims.height - 10,
            });
        }

    }
    const pdfBytes = await pdfDoc.save();
    var blob = new Blob([pdfBytes], { type: "application/pdf" });
    const base64Data = await this.blobToBase64(blob);
    attachPdfOnRecord(
        {
            base64Data : base64Data,
            recordId : this.recordId
        }
    )
    .then((result)=>{
        console.log('success');
        location.reload();
    }).catch((error)=>{
        console.log('error--'+JSON.stringify(error));
    });        
}

blobToBase64(blob) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onloadend = () => {
            const base64 = reader.result.split(',')[1];
            resolve(base64);
        };
        reader.onerror = reject;
        reader.readAsDataURL(blob);
    });
}
}