/**

* @description       : API REST para obtener oportunidades ganadas por cliente

* @author            : ChangeMeIn@UserSettingsUnder.SFDoc

* @group             : Integraciones

* @last modified on  : 04-15-2026

* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc

**/

@RestResource(urlMapping='/v1/clientes/*/oportunidades-ganadas')

global with sharing class OportunidadesGanadasAPI {
 
    @HttpGet

    global static void getOportunidades() {

        RestRequest req = RestContext.request;

        RestResponse res = RestContext.response;
 
        // Definir el tipo de contenido como JSON

        res.addHeader('Content-Type', 'application/json');
 
        try {

            // 1. Extraer el clientId de la URL

            String requestURI = req.requestURI;

            String clientId = requestURI.substringBetween('clientes/', '/oportunidades-ganadas');
 
            // 2. Buscar la cuenta y sus oportunidades ganadas.

            // AÑADIDO: WITH SECURITY_ENFORCED para validar permisos CRUD/FLS

            List<Account> cuentas = [

                SELECT Id, Name, NationalId__c,

                       (SELECT Id, Amount, CreditLine__c, CloseDate, LeadSource, Owner.Name, Product__c, InterestRate__c

                        FROM Opportunities

                        WHERE StageName = 'Closed Won') 

                FROM Account

                WHERE NationalId__c = :clientId

                WITH SECURITY_ENFORCED

                LIMIT 1

            ];
 
            if (cuentas.isEmpty()) {

                res.statusCode = 404;

                res.responseBody = Blob.valueOf('{"error": "Cliente no encontrado"}');

                return;

            }
 
            Account cliente = cuentas[0];
 
            // 3. Construir la respuesta mapeando a nuestras clases Wrapper

            RespuestaJSON respuesta = new RespuestaJSON();

            respuesta.clientId = cliente.NationalId__c;

            respuesta.nombreCliente = cliente.Name;

            respuesta.oportunidadesGanadas = new List<OportunidadDetalle>();
 
            for (Opportunity opp : cliente.Opportunities) {

                OportunidadDetalle det = new OportunidadDetalle();

                det.oportunidadId = opp.Id;

                det.producto = opp.Product__c;

                det.montoAprobado = opp.Amount;

                det.lineaCredito = opp.CreditLine__c;

                det.tasaInteres = opp.InterestRate__c;

                det.fechaCierre = String.valueOf(opp.CloseDate);

                det.canalOrigen = opp.LeadSource;

                det.ejecutivo = opp.Owner.Name;
 
                respuesta.oportunidadesGanadas.add(det);

            }
 
            respuesta.totalOportunidades = respuesta.oportunidadesGanadas.size();
 
            // 4. Enviar respuesta exitosa

            res.statusCode = 200;

            res.responseBody = Blob.valueOf(JSON.serialize(respuesta));
 
        } catch (System.QueryException qe) {

            // Captura específica si falla el WITH SECURITY_ENFORCED por falta de permisos

            res.statusCode = 403;

            res.responseBody = Blob.valueOf('{"error": "El usuario de integración no tiene permisos para leer los campos solicitados."}');

        } catch (Exception e) {

            // Captura general

            res.statusCode = 500;

            res.responseBody = Blob.valueOf('{"error": "' + e.getMessage() + '"}');

        }

    }
 
    // --- CLASES WRAPPER PARA GENERAR LA ESTRUCTURA EXACTA DEL JSON ---

    global class RespuestaJSON {

        public String clientId;

        public String nombreCliente;

        public List<OportunidadDetalle> oportunidadesGanadas;

        public Integer totalOportunidades;

    }
 
    global class OportunidadDetalle {

        public String oportunidadId;

        public String producto;

        public Decimal montoAprobado;

        public Decimal lineaCredito;

        public Decimal tasaInteres;

        public String fechaCierre;

        public String canalOrigen;

        public String ejecutivo;

    }

}
 