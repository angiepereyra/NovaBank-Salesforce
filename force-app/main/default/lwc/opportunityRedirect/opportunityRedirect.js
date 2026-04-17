import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import convertLead from '@salesforce/apex/LeadConversionService.convertLead';
export default class OpportunityRedirect extends NavigationMixin(LightningElement) {
    _recordId;
    isLoading = false;
    errorMessage;
    _isProcessing = false;
    // El SETTER se ejecuta justo cuando Salesforce inyecta el ID
    @api set recordId(value) {
        this._recordId = value;
        if (value && !this._isProcessing) {
            this.handleConversion();
        }
    }
 
    get recordId() {
        return this._recordId;
    }
 
    async handleConversion() {
        this._isProcessing = true;
        this.isLoading = true;
        try {
            // Llamada al Apex Service
            const oppId = await convertLead({ leadId: this._recordId });
            if (oppId) {
                this.toast('Éxito', 'Lead convertido correctamente', 'success');
                // Navegación
               // 2. Preparar la navegación
            const pageRef = {
                type: 'standard__recordPage',
                attributes: {
                    recordId: oppId,
                    objectApiName: 'Opportunity',
                    actionName: 'view'
                }
            };
 
            // 3. Navegar
            this[NavigationMixin.Navigate](pageRef);
 
            // 4. Cerrar el modal (con un pequeño retardo para asegurar la navegación)
            setTimeout(() => {
                this.closeAction();
            }, 500);
            }

        } catch (e) {
            this.errorMessage = e.body?.message || e.message;
            this.toast('Error', this.errorMessage, 'error');
        } finally {
            this.isLoading = false;
        }
    }
 
    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
 
    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

}
 