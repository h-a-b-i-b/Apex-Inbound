import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

export default class DisconnectionNotice extends LightningElement {
    subscription = {};
    status;
    identifier;
    channelName = '/event/Asset_Disconnection__e'; // Replace with your actual event name

    connectedCallback() {
        this.handleSubscribe();
        // Optional: handle general platform event errors
        onError(error => {
            console.error('EMP API error: ', error);
        });
    }

    handleSubscribe() {
        const messageCallback = (response) => {
            // Extract payload details
            const payload = response.data.payload;
            this.status = payload.Disconnected__c;
            this.identifier = payload.Asset_Identifier__c;

            if (this.status === true) {
                this.showSuccessToast(this.identifier);
            } else {
                this.showErrorToast();
            }
        };

        // Subscribe to the platform event
        subscribe(this.channelName, -1, messageCallback).then(response => {
            console.log('Successfully subscribed to channel: ', response.channel);
            this.subscription = response;
        });
    }

    disconnectedCallback() {
        // Unsubscribe from the channel when the component is destroyed
        if (this.subscription && this.subscription.subscription) {
            unsubscribe(this.subscription, response => {
                console.log('Unsubscribed from: ', response.channel);
            });
        }
    }

    showSuccessToast(assetId) {
        const event = new ShowToastEvent({
            title: 'Success',
            message: 'Asset Id ' + assetId + ' is now disconnected',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    showErrorToast() {
        const event = new ShowToastEvent({
            title: 'Error',
            message: 'Asset was not disconnected. Try Again.',
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
}