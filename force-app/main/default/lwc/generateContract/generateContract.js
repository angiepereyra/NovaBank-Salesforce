import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import generateContractApex from '@salesforce/apex/ContractGeneratorController.generateContract';
 
export default class GenerateContract extends NavigationMixin(LightningElement) {
    @api recordId;          // Opportunity Id injected by the Quick Action
    isLoading = false;
    generatedDocId;
    errorMessage;
 
    async handleGenerate() {
        this.isLoading = true;
        this.errorMessage = null;
        try {
            this.generatedDocId = await generateContractApex({ oppId: this.recordId });
 
            this.dispatchEvent(new ShowToastEvent({
                title:   'Contract generated',
                message: 'The contract PDF has been attached to the opportunity.',
                variant: 'success'
            }));
        } catch (e) {
            this.errorMessage = e.body?.message ?? 'Unknown error during generation';
            this.dispatchEvent(new ShowToastEvent({
                title:   'Generation error',
                message: this.errorMessage,
                variant: 'error'
            }));
        } finally {
            this.isLoading = false;
        }
    }
 
    handleViewDocument() {
        if (!this.generatedDocId) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.generatedDocId,
                objectApiName: 'ContentDocument',
                actionName: 'view'
            }
        });
        this.handleClose();
    }
 
    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
 
    get hasGenerated() { return !!this.generatedDocId; }
    get hasError()     { return !!this.errorMessage; }
    get showInitial()  { return !this.hasGenerated && !this.hasError && !this.isLoading; }
}