({
    doInit : function(component, event, helper) {
        // Configuración de columnas según requerimiento de la imagen
        component.set('v.columns', [
            {label: 'Prioridad', fieldName: 'Priority__c', type: 'number', initialWidth: 80},
            {label: 'Tarjeta', fieldName: 'CardName__c', type: 'text'},
            {label: 'TEA', fieldName: 'AnnualEffectiveRate__c', type: 'percent', 
                typeAttributes: { step: '0.01' }},
            {label: 'Millas', fieldName: 'Miles__c', type: 'number'},
            {label: 'CashBack', fieldName: 'CashBack__c', type: 'percent'}
           //{label: 'Cuota Anual', fieldName: 'AnnualFee__c', type: 'currency'},
            //{label: 'Límite Ref.', fieldName: 'ReferentialCreditLimit__c', type: 'currency'},
            //{label: 'Seguros', fieldName: 'AssociatedInsurance__c', type: 'text'}
        ]);
 
        helper.fetchData(component);
    }
})