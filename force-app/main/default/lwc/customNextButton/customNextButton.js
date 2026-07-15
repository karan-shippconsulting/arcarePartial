import { api, LightningElement } from "lwc";
import { FlowNavigationNextEvent } from "lightning/flowSupport";

export default class CustomNextButton extends LightningElement {
  @api label;
  @api documentType;
  @api contentDocumentIds = [];

  @api
  get isDisabled() {
    return (
      !this.documentType ||
      this.documentType === "" ||
      this.documentType === undefined ||
      this.contentDocumentIds.length === 0
    );
  }
  set isDisabled(value) {}

  isDisabled = false;

  handleNext() {
    if (!this.isDisabled) {
      const navigateNextEvent = new FlowNavigationNextEvent();
      this.dispatchEvent(navigateNextEvent);
    }
  }
}