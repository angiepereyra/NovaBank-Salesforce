/**

* @description Controller para la generación de contratos en PDF.

* Se eliminan warnings de PMD y se asegura el cumplimiento de CRUD/FLS.

*/

public with sharing class ContractGeneratorController {

    private final Opportunity currentOpp;
 
    /**

     * @description Constructor de la extensión.

     * Se asigna el registro para evitar el warning 'EmptyStatementBlock'.

     * @param stdCtrl Standard Controller de Opportunity

     */

    public ContractGeneratorController(ApexPages.StandardController stdCtrl) {

        this.currentOpp = (Opportunity) stdCtrl.getRecord();

    }
 
    /**

     * @description Genera el PDF y lo adjunta a la Oportunidad.

     * @param oppId ID de la Oportunidad

     * @return Id del ContentDocument generado

     */

    @AuraEnabled

    public static Id generateContract(Id oppId) {

        if (oppId == null) {

            throw new AuraHandledException('El ID de la oportunidad es nulo.');

        }
 
        // 1. Validar seguridad CRUD proactiva

        if (!Schema.sObjectType.ContentVersion.isCreateable() || 

            !Schema.sObjectType.ContentDocumentLink.isCreateable()) {

            throw new AuraHandledException('No tienes permisos suficientes para crear archivos.');

        }
 
        try {

            // 2. Consulta con WITH USER_MODE para FLS

            Opportunity o = [

                SELECT Id, Name, Account.Name 

                FROM Opportunity 

                WHERE Id = :oppId 

                WITH USER_MODE 

                LIMIT 1

            ];
 
            // 3. Generación del PDF

            PageReference pdfPage = Page.ContractTemplate;

            pdfPage.getParameters().put('id', oppId);
 
            Blob pdfBlob;

            if (Test.isRunningTest()) {

                pdfBlob = Blob.valueOf('Test');

            } else {

                // Si ya diste permisos al perfil en la página, esto no debería lanzar GACK

                pdfBlob = pdfPage.getContentAsPDF();

            }
 
            // 4. Inserción de ContentVersion

            ContentVersion cv = new ContentVersion();

            cv.Title = 'Contrato_' + o.Name + '.pdf';

            cv.PathOnClient = 'Contrato.pdf';

            cv.VersionData = pdfBlob;

            cv.IsMajorVersion = true;

            // Reforzamos seguridad en DML

            insert as user cv;
 
            // 5. Obtener el DocumentId

            ContentVersion cvRecord = [

                SELECT ContentDocumentId 

                FROM ContentVersion 

                WHERE Id = :cv.Id 

                WITH USER_MODE 

                LIMIT 1

            ];
 
            // 6. Vinculación

            ContentDocumentLink cdl = new ContentDocumentLink();

            cdl.LinkedEntityId = oppId;

            cdl.ContentDocumentId = cvRecord.ContentDocumentId;

            cdl.ShareType = 'V';

            cdl.Visibility = 'AllUsers';

            insert as user cdl;
 
            return cvRecord.ContentDocumentId;
 
        } catch (System.QueryException qe) {

            throw new AuraHandledException('Error de acceso: No se encontró el registro o falta de permisos.');

        } catch (Exception e) {

            System.debug(LoggingLevel.ERROR, 'Error detectado: ' + e.getMessage());

            throw new AuraHandledException('Error en la generación: ' + e.getMessage());

        }

    }

}
 