SELECT 
ISNULL(rp.Id,'') as id,
 CASE WHEN companyStatus.IsContractSigned = 0 THEN client.Id ELSE NULL END AS LeadId,
 CASE WHEN companyStatus.IsContractSigned = 1 THEN client.Id ELSE NULL END AS ClientId,
(ISNULL(CONVERT(nvarchar,rp.ScheduleDate,101),'')) ScheduleDate,
ISNULL(rp.Amount,'')as Amount,
ISNULL(rp.ContractId,'')as contractId,
ISNULL(rs.Name, '')AS Status,  
ISNULL(pid.Name , '')as PaymentProcessorName,
ISNULL(pmt.Name , '')AS Method,
ISNULL(t.Date , '')AS ProcessingDate,
ISNULL(CASE WHEN rp.ExternalId IS NULL THEN 'NO' ELSE 'YES' END, '') AS SyncStatus,
ISNULL(client.CompanyId,'') as company,
rp.CreatedDate,rp.UpdatedDate
	
FROM [client].[ReturnPayments] rp
	INNER JOIN dbo.ReturnTransaction AS rt ON rt.Id = rp.ReturnType	
	INNER JOIN [dbo].[ReturnStatus] AS rs ON rp.Status = rs.Id
	INNER JOIN client.Contract AS client ON rp.ContractId = client.Id
	LEFT JOIN client.ContractPaymentIntegration AS clientPI ON clientPI.ContractId = client.Id
	LEFT JOIN [company].[PaymentIntegration] AS companyPI ON clientPI.CompanyPaymentIntegrationId = companyPI.Id
	left join company.ConfiguredStatus as companystatus on companystatus.Id = client.StatusId
	LEFT JOIN [payment].[PaymentIntegrationDefinition] AS pid ON companyPI.IntegrationId = pid.Id
	LEFT JOIN  client.ContractPaymentMethod AS cPM ON client.Id = cPM.ContractId
	LEFT JOIN  [dbo].[PaymentMethodType] AS pmt ON cPM.PaymentMethodTypeId = pmt.Id
	LEFT JOIN [client].[Transaction] AS t ON rp.ExternalId = t.ExternalId AND t.Type = 6

WHERE 
 rt.Id = 2
AND client.CompanyId=278
AND client.UpdatedDate >'2017-01-01 00:00:00.000'
