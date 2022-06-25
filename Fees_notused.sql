
--<Migration -1 Month>
DECLARE @migration_date DATE = '' --yyyy-mm-dd is date format

--  e.g @migration_date DATE = '2021-04-21' this is the example

SELECT p.Id,
   CASE WHEN companyStatus.IsContractSigned = 0 THEN client.Id ELSE NULL END AS LeadId,
   CASE WHEN companyStatus.IsContractSigned = 1 THEN client.Id ELSE NULL END AS ClientId,
settment.Id AS Settlement,
settment.LoanId AS Debt,
(ISNULL(CONVERT(nvarchar,p.Date,101),'')) ScheduleDate,
p.Amount,
feeState.Name AS Status,
	ISNULL(pid.Name,'') PaymentProcessorName,
	ISNULL(pmt.Name,'') AS PaymentMethodName,
	(ISNULL(CONVERT(nvarchar,t.Date,101),'')) AS ProcessingDate,
	CASE WHEN p.ExternalId IS NULL THEN 'NO' ELSE 'YES' END AS SyncStatus, CompanyLI.ExternalId AS LenderExternalId,client.CompanyId AS Company,
p.CreatedDate , p.UpdatedDate
FROM client.ScheduledLoanRelatedFees p
	INNER JOIN loan.LoanSettlementOffer AS offer ON p.OfferId =  offer.Id
	INNER JOIN [dbo].[LoanSettlementOfferStatus] AS offerStatus ON offer.OfferStatusId =  offerStatus.Id
	INNER JOIN loan.LoanSettlement AS settment ON offer.SettlementId = settment.Id	
	INNER JOIN [dbo].[LoanSettlementStatus] AS settmentStatus ON settment.SettlementStatusId = settmentStatus.Id	
	INNER JOIN loan.Loan AS loan ON settment.LoanId = loan.Id	
	INNER JOIN loan.LoanLender AS lender ON settment.LoanId = lender.LoanId AND lender.IsActive = 1
	INNER JOIN company.CompanyLender AS cl ON lender.LenderId = cl.LenderId AND cl.IsActive = 1 AND cl.CompanyId = 278
	INNER JOIN [dbo].[FeeScheduleStatus] AS feeState ON p.StatusId = feeState.Id
	INNER JOIN client.Contract AS client ON loan.ContractId = client.Id
	LEFT JOIN  client.ContractPaymentIntegration AS clientPI ON clientPI.ContractId = client.Id
	LEFT JOIN [company].[PaymentIntegration] AS companyPI ON clientPI.CompanyPaymentIntegrationId = companyPI.Id
	LEFT JOIN [payment].[PaymentIntegrationDefinition] AS pid ON companyPI.IntegrationId = pid.Id
	LEFT JOIN  client.ContractPaymentMethod AS cPM ON client.Id = cPM.ContractId
	LEFT JOIN  [dbo].[PaymentMethodType] AS pmt ON cPM.PaymentMethodTypeId = pmt.Id
	LEFT JOIN [client].[Transaction] AS t ON p.ExternalId = t.ExternalId AND t.Type = 2
	--LEFT JOIN [client].[PaymentCheckTracking] AS pct ON  p.Id = pct.ScheduledLoanRelatedFeeId
	LEFT JOIN [company].[PaymentIntegration] pint ON pint.CompanyId = cl.CompanyId --AND pint.IntegrationId = 4
	LEFT JOIN  company.[CompanyLenderIntegration] AS CompanyLI ON cl.Id = CompanyLI.CompanyLenderId  AND CompanyLI.PaymentIntegrationId = pint.Id	
	LEFT JOIN company.ConfiguredStatus as companystatus on companystatus.Id = client.StatusId
WHERE IsLoanRepaymentFee = 0 AND client.CompanyId = 278 AND settment.SettlementStatusId IN (11,9,7,6)
   AND (companystatus.IsContractSigned=1 OR (companystatus.IsContractSigned=0 AND client.CreatedDate > @migration_date));