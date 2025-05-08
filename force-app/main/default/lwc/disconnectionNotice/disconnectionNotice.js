import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {
    subscribe,
    unsubscribe,
    onError,
    setDebugFlag,
    isEmpEnabled,
} from 'lightning/empApi';

export default class DisconnectionNotice extends LightningElement {
    subscription = {};
    status;
    identifier;
    channelName = '/event/Asset_Disconnection__e';
    // messageCallback;


    connectedCallback() {
        console.log("Connected callback called....");
        this.handleSubscribe();
    }

    renderedCallback() {

    }


    handleSubscribe() {

        console.log("Handle subscribe called...");


        //Implement your subscribing solution here 
        // Check if empApi is enabled
        isEmpEnabled()
            .then((response) => {
                console.log('isEmpEnabled response: ', response);
                // Response is true if empApi is enabled
                if (response) {
                    this.registerErrorListener();
                    this.subscribeToChannel();
                }
            })
            .catch((error) => {
                console.log('isEmpEnabled error: ', JSON.stringify(error));
            });
    }

    subscribeToChannel() {

        console.log("Subscribe to channel called...");
        // Callback invoked whenever a new event message is received
        const messageCallback = function (response) {
            console.log('New message received: ', JSON.stringify(response));

            console.log('Channel Name: ', response.channel);

            console.log('Data received: ', JSON.stringify(response.data));
            console.log('Data received: ', JSON.stringify(response.data.payload));
            console.log('Data received: ', JSON.stringify(response.data.payload.Asset_Identifier__c));
            
            const payload = response.data.payload;
            this.status = payload.Disconnected__c;
            this.identifier = payload.Asset_Identifier__c;
            console.log('Status: ', this.status);
            console.log('Identifier: ', this.identifier);

            if (this.status) {
                this.showSuccessToast(this.identifier);
            } else {
                this.showErrorToast();
            }
            // Response contains the payload of the new message received
        };
        try {

            // Invoke subscribe method of empApi. Pass reference to messageCallback
            subscribe(this.channelName, -1, messageCallback).then((response) => {
                // Response contains the subscription information on subscribe call
                console.log(
                    'Subscription request sent to: ',
                    JSON.stringify(response.channel)
                );
                this.subscription = response;
                console.log('Subscription response: ', JSON.stringify(response));

                // this.toggleSubscribeButton(true);
            });
        } catch (error) {
            console.log('Error in subscribeToChannel: ', JSON.stringify(error));

        }

    }

    handleMessageCallback(payload) {

        console.log("Handle message callback called...");

        console.log('New message received: ', JSON.stringify(payload));
        this.status = payload.Disconnected__c;
        this.identifier = payload.Asset_Identifier__c;
        console.log('Status: ', this.status);
        console.log('Identifier: ', this.identifier);

        if (this.status) {
            this.showSuccessToast(this.identifier);
        } else {
            this.showErrorToast();
        }
    }

    disconnectedCallback() {
        console.log("Disconnected callback called...");
        // Implement your unsubscribing solution here

        try {

            // Invoke unsubscribe method of empApi
            unsubscribe(this.subscription, (response) => {
                console.log('unsubscribe() response: ', JSON.stringify(response));
                // Response is true for successful unsubscribe
            });
        } catch (error) {
            console.log('Error unsubscribing: ', JSON.stringify(error));

        }
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError((error) => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
            // this.showErrorToast();
        });
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