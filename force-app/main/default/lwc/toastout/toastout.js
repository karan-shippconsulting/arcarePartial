import {LightningElement, api, track} from 'lwc';

export default class Toastout extends LightningElement {

    @track
    message;
    @track
    title;
    @track
    type;

    @api
    show(message, type) {
        this.title = type;
        this.message = message;
        this.type = type || 'error';

        const toast = this.template.querySelector('.toast');
        toast.classList.toggle('toast_show');
        toast.classList.toggle('toast_hide');

        this.timer = setTimeout(() => {{
            toast.classList.toggle('toast_show');
            toast.classList.toggle('toast_hide');
        }}, 6000);
    }

    get notifyClasses() {
        return `slds-notify slds-notify_toast slds-theme_${this.type}`;
    }
    get iconName() {
        return `utility:${this.type}`;
    }
}