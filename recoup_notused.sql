SELECT 
rp.id,
(ISNULL(CONVERT(nvarchar,rp.ScheduleDate,101),'')) ScheduleDate,
ISNULL(rp.Amount,'')as Amount,
   CASE WHEN companyStatus.IsContractSigned = 0 THEN client.Id ELSE NULL END AS LeadId,
   CASE WHEN companyStatus.IsContractSigned = 1 THEN client.Id ELSE NULL END AS ClientId,
rp.AdvanceId,
ISNULL(rs.Name, '')AS Status,
ISNULL(pid.Name , '')as PaymentProcessor,
ISNULL(pmt.Name , '')AS Method,
ISNULL(t.Date , '')AS ProcessingDate,	
ISNULL(CASE WHEN rp.ExternalId IS NULL THEN 'No' ELSE 'Yes' END, '') AS SyncStatus,
ISNULL(client.CompanyId,'')as CompanyId,
	ISNULL(rp.Comments,'')as Comments,
	rp.CreatedDate, rp.UpdatedDate
FROM [client].[ReturnPayments] rp
	INNER JOIN dbo.ReturnTransaction AS rt ON rt.Id = rp.ReturnType	
	INNER JOIN [dbo].[ReturnStatus] AS rs ON rp.Status = rs.Id
	INNER JOIN client.Contract AS client ON rp.ContractId = client.Id
	LEFT JOIN client.ContractPaymentIntegration AS clientPI ON clientPI.ContractId = client.Id
	LEFT JOIN [company].[PaymentIntegration] AS companyPI ON clientPI.CompanyPaymentIntegrationId = companyPI.Id
	LEFT JOIN [payment].[PaymentIntegrationDefinition] AS pid ON companyPI.IntegrationId = pid.Id
	LEFT JOIN  client.ContractPaymentMethod AS cPM ON client.Id = cPM.ContractId
	LEFT JOIN  [dbo].[PaymentMethodType] AS pmt ON cPM.PaymentMethodTypeId = pmt.Id
	LEFT JOIN [client].[Transaction] AS t ON rp.ExternalId = t.ExternalId AND t.Type = 14
	left join company.ConfiguredStatus as companystatus on companystatus.Id = client.StatusId
WHERE client.CompanyId = 278	AND rt.Id = 5
AND client.UpdatedDate >'2017-01-01 00:00:00.000'