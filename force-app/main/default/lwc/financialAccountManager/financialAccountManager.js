import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getByAccount from '@salesforce/apex/FinancialAccountController.getByAccount';
import removeFA from '@salesforce/apex/FinancialAccountController.remove';
 
const COLS = [
    { label: 'Card Name',    fieldName: 'Name',                 type: 'text' },
    { label: 'Type',         fieldName: 'CardType__c',           type: 'text' },
    { label: 'Credit Line',  fieldName: 'ApprovedCreditLine__c', type: 'currency' },
    { label: 'Status',       fieldName: 'Status__c',             type: 'text' },
    { label: 'Issued',       fieldName: 'IssuanceDate__c',       type: 'date' },
    { label: 'Holder',       fieldName: 'accountName',           type: 'text' },
    { label: 'Card Number',  fieldName: 'CardNumber__c',         type: 'text' },
    { type: 'action', typeAttributes: { rowActions: [
        { label: 'Edit',   name: 'edit' },
        { label: 'Delete', name: 'delete' }
    ]}}
];
 
export default class FinancialAccountManager extends LightningElement {
    @api recordId;
    @track data        = [];
    @track editRecord  = null;
    @track isModalOpen = false;
    columns = COLS;
    wiredRef;
 
    get modalTitle() {
        return this.editRecord && this.editRecord.Id ? 'Edit Financial Account' : 'New Financial Account';
    }
 
    get currentRecordId() {
        return this.editRecord && this.editRecord.Id ? this.editRecord.Id : null;
    }
 
    get isDataEmpty() {
        return !this.data || this.data.length === 0;
    }
 
    @wire(getByAccount, { accountId: '$recordId' })
    wired(result) {
        this.wiredRef = result;
        if (result.data) {
            this.data = result.data.map(record => ({
                ...record,
                accountName: record.AccountId__r ? record.AccountId__r.Name : ''
            }));
        }
        if (result.error) {
            this.toast(result.error.body.message, 'error');
        }
    }
 
    handleNew() {
        this.editRecord  = {};
        this.isModalOpen = true;
    }
 
    async handleRowAction(evt) {
        const action = evt.detail.action.name;
        const row    = evt.detail.row;
        try {
            if (action === 'edit') {
                this.editRecord  = { ...row };
                this.isModalOpen = true;
            }
            if (action === 'delete') {
                await removeFA({ faId: row.Id });
                this.toast('Registro eliminado', 'success');
                await refreshApex(this.wiredRef);
            }
        } catch (e) {
            this.toast(e.body.message, 'error');
        }
    }
 
    handleSuccess() {
        this.toast('Registro guardado', 'success');
        this.isModalOpen = false;
        this.editRecord  = null;
        refreshApex(this.wiredRef);
    }
 
    handleError(evt) {
        this.toast(evt.detail.message, 'error');
    }
 
    handleCancel() {
        this.isModalOpen = false;
        this.editRecord  = null;
    }
 
    toast(msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title: msg, variant }));
    }
}