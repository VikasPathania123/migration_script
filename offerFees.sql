

--<Migration -1 Month>
DECLARE @migration_date DATE = '' --yyyy-mm-dd is date format

--  e.g @migration_date DATE = '2021-04-21' this is the example


SELECT 
    offerFee.Id, 
    offer.Id AS OfferId, 
    offerFee.Date AS ScheduleDate, 
    offerFee.Amount,	
	offer.UpdatedDate,
    '' AS Method
FROM [loan].[LoanServiceFeePaymentDetails] AS offerFee
	INNER JOIN loan.LoanSettlementOffer AS offer ON offerFee.OfferId = offer.Id
        AND offer.OfferStatusId <> 4 --offer_accepted
	INNER JOIN loan.LoanSettlement AS settment ON offer.SettlementId = settment.Id	
	INNER JOIN loan.Loan AS loan ON settment.LoanId = loan.Id	
	INNER JOIN client.Contract AS mainContract ON mainContract.Id = loan.ContractId	
	LEFT JOIN client.ContractApplicant mainContractApplicant ON mainContract.Id = mainContractApplicant.ContractId 
	LEFT JOIN company.ConfiguredStatus AS ConfiguredStatus ON mainContract.StatusId = ConfiguredStatus.Id 
	LEFT JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration  ON mainContract.Id = mainContractPaymentIntegration.ContractId
	LEFT JOIN company.PaymentIntegration AS mainPaymentIntegration ON mainPaymentIntegration.Id =mainContractPaymentIntegration.CompanyPaymentIntegrationId
	where mainContract.CompanyId=278
	AND mainContractApplicant.IsPrimary=1
	AND (ConfiguredStatus.IsContractSigned=1 OR (ConfiguredStatus.IsContractSigned=0 AND mainContract.CreatedDate > @migration_date))
	AND mainContractApplicant.IsActive=1 
	AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
	AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10
-- and mainContract.FriendlyId in (113393, 115340, 124024, 124306, 126663, 127662, 129185, 129372, 130551, 126334)


    UNION ALL

SELECT 
    payment.Id, 
    payment.OfferId, 
    payment.Date AS ScheduleDate, 
    payment.Amount,	
	offer.UpdatedDate,
    '' AS Method
FROM client.Contract AS mainContract
	INNER JOIN  company.ConfiguredStatus AS ConfiguredStatus  ON mainContract.StatusId = ConfiguredStatus.Id 
	INNER JOIN  client.ContractApplicant AS mainContractApplicant ON mainContract.Id = mainContractApplicant.ContractId 
		AND mainContractApplicant.IsPrimary = 1
        AND mainContractApplicant.IsActive = 1
    INNER JOIN client.ScheduledLoanRelatedFees payment ON payment.ContractId = mainContract.Id 
		AND payment.IsLoanRepaymentFee = 0
        AND payment.StatusId NOT IN (6, 13)
    INNER JOIN loan.LoanSettlementOffer offer ON offer.Id = payment.OfferId
        AND offer.OfferStatusId = 4 --offer_accepted
	LEFT JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration  ON mainContract.Id = mainContractPaymentIntegration.ContractId
	LEFT JOIN company.PaymentIntegration AS mainPaymentIntegration ON mainPaymentIntegration.Id =mainContractPaymentIntegration.CompanyPaymentIntegrationId
WHERE mainContract.CompanyId = 278
    AND ((ConfiguredStatus.IsContractSigned = 1 AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
			AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10) 
		OR (ConfiguredStatus.IsContractSigned = 0 AND mainContract.CreatedDate > @migration_date ))