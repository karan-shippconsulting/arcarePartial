import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class RedirectAfterFlow extends NavigationMixin(
  LightningElement
) {
  @api recordId; // This property will receive the Record ID from the flow
  @api documentType;

  handleClick() {
    // Define the page reference for the record page
    let objectName = "DS_" + this.documentType + "__c";
    window.location.href = `/lightning/r/${objectName}/${this.recordId}/view`;
  }
}