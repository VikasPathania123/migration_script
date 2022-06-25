SELECT  
	fee.id AS Parent_Id,
	(ISNULL(CONVERT(nvarchar,rp.ScheduleDate,101),'')) ScheduleDate,
	CASE WHEN companyStatus.IsContractSigned = 0 THEN client.Id ELSE NULL END AS LeadId,
	CASE WHEN companyStatus.IsContractSigned = 1 THEN client.Id ELSE NULL END AS ClientId,
	ISNULL(rp.Amount,'')as Amount,
	ISNULL(rp.ContractId,'')as contractId,
	ISNULL(rs.Name, '')AS Status,
	ISNULL(pid.Name , '')as PaymentProcessor,
	ISNULL(pmt.Name , '')AS Method,
	ISNULL(t.Date , '')AS ProcessingDate,	
	ISNULL(CASE WHEN rp.ExternalId IS NULL THEN 'No' ELSE 'Yes' END, '') AS SyncStatus,
	ISNULL(client.CompanyId,'')as CompanyId,
	ISNULL(rp.Comments,'')as Comments,
	rp.CreatedBy, rp.CreatedDate, rp.UpdatedDate
FROM [client].[ReturnPayments] rp
	INNER JOIN dbo.ReturnTransaction AS rt ON rt.Id = rp.ReturnType	
	INNER JOIN [dbo].[ReturnStatus] AS rs ON rp.Status = rs.Id
	INNER JOIN client.Contract AS client ON rp.ContractId = client.Id
	INNER JOIN client.ScheduledLoanRelatedFees AS fee ON rp.ExternalId = fee.ExternalId -- consider ext id must be present
	LEFT JOIN client.ContractPaymentIntegration AS clientPI ON clientPI.ContractId = client.Id
	LEFT JOIN [company].[PaymentIntegration] AS companyPI ON clientPI.CompanyPaymentIntegrationId = companyPI.Id
	LEFT JOIN [payment].[PaymentIntegrationDefinition] AS pid ON companyPI.IntegrationId = pid.Id
	LEFT JOIN  client.ContractPaymentMethod AS cPM ON client.Id = cPM.ContractId
	LEFT JOIN  [dbo].[PaymentMethodType] AS pmt ON cPM.PaymentMethodTypeId = pmt.Id
	LEFT JOIN [client].[Transaction] AS t ON rp.ExternalId = t.ExternalId AND t.Type = 8
	 left join company.ConfiguredStatus as companystatus on companystatus.Id = client.StatusId
WHERE client.CompanyId = 278	
	AND rt.Id = 4
	AND ReturnType = 4;