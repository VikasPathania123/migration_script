

--<Migration -1 Month>
DECLARE @migration_date DATE = '' --yyyy-mm-dd is date format

--  e.g @migration_date DATE = '2021-04-21' this is the example

SELECT 
ISNULL(mainTransaction.Id , '')as id,
CASE WHEN companyStatus.IsContractSigned = 0 THEN mainContract.FriendlyId ELSE NULL END AS LeadId,
 CASE WHEN companyStatus.IsContractSigned = 1 THEN mainContract.FriendlyId ELSE NULL END AS ClientId,
ISNULL(mainContract.CompanyId, '') AS company,
ISNULL(mainTransaction.CreatedDate , '')AS createdAt,
ISNULL(mainTransaction.UpdatedDate , '')AS updatedAt,
ISNULL(mainTransaction.Amount, '') AS amount,
ISNULL((SELECT name FROM dbo.TransactionStatus AS t WHERE t.id=mainTransaction.Status), '')as status,
ISNULL(pid.Name , '')as PaymentProcessor,
ISNULL(mainTransaction.Date , '')as processingDate,
ISNULL(mainTransaction.ExternalId, '') as lastSuccessfulSyncStatus,
ISNULL(mainTransaction.ExternalId , '')as SyncStatus,
ISNULL(pmt.Name , '')AS Method,
mainTransaction.CreatedDate, mainTransaction.UpdatedDate


FROM  client.[Transaction] AS mainTransaction
INNER JOIN client.Contract AS mainContract ON mainTransaction.ContractId = mainContract.Id
LEFT JOIN client.ContractPaymentIntegration AS PI ON PI.ContractId = mainContract.Id
LEFT JOIN [company].[PaymentIntegration] AS companyPI ON PI.CompanyPaymentIntegrationId = companyPI.Id
LEFT JOIN [payment].[PaymentIntegrationDefinition] AS pid ON companyPI.IntegrationId = pid.Id
left join company.ConfiguredStatus as companystatus on companystatus.Id = mainContract.StatusId
LEFT JOIN  client.ContractPaymentMethod AS cPM ON mainContract.Id = cPM.ContractId
LEFT JOIN  [dbo].[PaymentMethodType] AS pmt ON cPM.PaymentMethodTypeId = pmt.Id
WHERE TYPE IN(9,11,12,13)

AND mainContract.CompanyId=278   
AND (companystatus.IsContractSigned=1 OR (companystatus.IsContractSigned=0 AND mainContract.CreatedDate > @migration_date));