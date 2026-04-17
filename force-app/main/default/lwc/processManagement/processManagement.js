import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccountDefaults from '@salesforce/apex/ProcessManagementController.getAccountDefaults';
export default class ProcessManagement extends NavigationMixin(LightningElement) {
    @api recordId;  // Account Id
    isLoading = true; // Empieza cargando mientras traemos los datos
    accountData;
    // Conectamos con Apex automáticamente al cargar la página
    @wire(getAccountDefaults, { accountId: '$recordId' })
    wiredDefaults({ error, data }) {
        if (data) {
            this.accountData = data;
            this.isLoading = false;
        } else if (error) {
            this.toast('Error', 'No se pudieron cargar los datos de la cuenta.', 'error');
            this.isLoading = false;
        }
    }
 
    handleSale() {
        if (!this.accountData) return;
        // 1. Mapear los campos pre-llenados
        const defaultValues = encodeDefaultFieldValues({
            FirstName: this.accountData.acc.Name.split(' ')[0],
            LastName: this.accountData.acc.Name.split(' ')[1],
            Company: this.accountData.acc.Name.split(' ')[1],
            NationalId__c: this.accountData.acc.NationalId__c,
            ExistingAccount__c: this.recordId,
            Status: 'Start'
        });
        // 2. Abrir el modal estándar de Salesforce para Nuevo Lead
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Lead',
                actionName: 'new'
            },

            state: {
                defaultFieldValues: defaultValues,
                recordTypeId: this.accountData.leadRecordTypeId
            }
        });
    }
 
    handleClaim() {
        if (!this.accountData) return;
        // 1. Mapear los campos pre-llenados para el Caso
        const defaultValues = encodeDefaultFieldValues({
            AccountId: this.recordId,
            Status: 'In Review',
            Origin: 'Web',
            Subject: 'Claim from 360° view'
        });
        // 2. Abrir el modal estándar de Salesforce para Nuevo Caso
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues,
                recordTypeId: this.accountData.caseRecordTypeId
            }
        });
    }
 
    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
 