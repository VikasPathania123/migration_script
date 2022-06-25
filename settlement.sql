
--<Migration -1 Month>
DECLARE @migration_date DATE = '' --yyyy-mm-dd is date format

--  e.g @migration_date DATE = '2021-04-21' this is the example


IF OBJECT_ID('tempdb..#ValidContract') IS NOT NULL DROP TABLE #ValidContract;

SELECT 
    mainContract.Id AS ContractId,
    mainContract.FriendlyId,
    CASE 
        WHEN companyStatus.IsContractSigned = 0 
        THEN mainContract.FriendlyId 
        ELSE NULL 
    END AS LeadId,
    CASE 
        WHEN companyStatus.IsContractSigned = 1 
        THEN mainContract.FriendlyId 
        ELSE NULL 
    END AS ClientId,
    ISNULL(mainPaymentIntegration.IntegrationFriendlyName,'') AS paymentProcessor 
INTO #ValidContract
FROM client.Contract AS mainContract
    INNER JOIN company.ConfiguredStatus as CompanyStatus on CompanyStatus.id = mainContract.StatusId 
    LEFT JOIN client.ContractApplicant mainContractApplicant ON mainContract.Id = mainContractApplicant.ContractId   
        AND mainContractApplicant.IsPrimary = 1
        AND mainContractApplicant.IsActive = 1
    LEFT JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration  ON mainContract.Id = mainContractPaymentIntegration.ContractId
    LEFT JOIN company.PaymentIntegration AS mainPaymentIntegration ON mainPaymentIntegration.Id = mainContractPaymentIntegration.CompanyPaymentIntegrationId 
WHERE mainContract.CompanyId = 278
	AND ((CompanyStatus.IsContractSigned = 1 AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
				AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10) 
			OR (CompanyStatus.IsContractSigned = 0 AND mainContract.CreatedDate > @migration_date ))    

	---START FROM HERE BELOW ARE THE 3 BATCHES

SELECT 
    CONCAT(mainLoanSettlement.Id, '', mainLoanSettlementOffer.Id) as id,
    ISNULL(mainLoanSettlement.ExternalId,'') AS externalId,
    ISNULL(mainLoanAmount.Amount,'') AS balance,
    ISNULL(mainLoanSettlementOffer.TotalPayments,'')AS amount ,
    ISNULL(mainLoanSettlementOffer.id,'')AS offer ,
    --ISNULL(mainLoanSettlementOfferStatus.Name,'')AS status,
    settlementStatus.Name AS status,
    ISNULL(mainLoanLender.LenderId,'')AS creditor,
    ISNULL(mainLoanSettlement.LoanId,'') AS debt,
	client.LeadId,
	client.ClientId,
    CASE WHEN mainLoanSettlement.ExternalId IS NULL THEN 'NO' ELSE 'YES' end AS syncStatus,
    CASE WHEN mainLoanSettlement.ExternalId IS NULL THEN 'NO' ELSE 'YES' end AS lastSuccessfulSyncStatus,
	client.paymentProcessor,
	settlementAssignment.UserId AS assignedUser,
    mainLoanSettlement.CreatedDate,
    mainLoanSettlement.UpdatedDate
FROM loan.LoanSettlement mainLoanSettlement
    INNER JOIN dbo.LoanSettlementStatus AS settlementStatus ON mainLoanSettlement.SettlementStatusId = settlementStatus.Id
    	AND settlementStatus.Id IN (6, 9, 11) 
    INNER JOIN loan.Loan AS mainLoan ON mainLoanSettlement.LoanId = mainLoan.Id
    INNER JOIN #ValidContract AS client ON client.ContractId = mainLoan.ContractId 
    INNER JOIN loan.LoanSettlementOffer AS  mainLoanSettlementOffer ON mainLoanSettlementOffer.SettlementId = mainLoanSettlement.Id 
        AND mainLoanSettlementOffer.OfferStatusId <> 3
	LEFT JOIN [loan].[SettlementNegotiatorAssignment] settlementAssignment ON settlementAssignment.LoanSettlementId = mainLoanSettlement.Id
            AND settlementAssignment.IsActive = 1
    LEFT JOIN loan.LoanAmount AS mainLoanAmount ON mainLoan.Id = mainLoanAmount.LoanId 
        AND IsCurrentValue = 1
    LEFT JOIN loan.LoanLender mainLoanLender ON mainLoanLender.LoanId = mainLoan.Id 
        AND mainLoanLender.IsActive = 1

            UNION ALL -- add  not offer declined,accepted,paymentplanstarted,paidoff                      ******** STEP - 2 **************

SELECT 
    CONCAT(mainLoanSettlement.Id, '', mainLoanSettlementOffer.Id) as id,
    ISNULL(mainLoanSettlement.ExternalId,'') AS externalId,
    ISNULL(mainLoanAmount.Amount,'') AS balance,
    ISNULL(mainLoanSettlementOffer.TotalPayments,'')AS amount ,
    ISNULL(mainLoanSettlementOffer.id,'')AS offer,
    'Accepted' AS status,
    ISNULL(mainLoanLender.LenderId,'')AS creditor,
    ISNULL(mainLoanSettlement.LoanId,'') AS debt,
	client.LeadId,
	client.ClientId,
    CASE WHEN mainLoanSettlement.ExternalId IS NULL THEN 'NO' ELSE 'YES' end AS syncStatus,
    CASE WHEN mainLoanSettlement.ExternalId IS NULL THEN 'NO' ELSE 'YES' end AS lastSuccessfulSyncStatus,
	client.paymentProcessor,
	settlementAssignment.UserId AS assignedUser,
    mainLoanSettlement.CreatedDate,
    mainLoanSettlement.UpdatedDate
FROM loan.LoanSettlement mainLoanSettlement
    INNER JOIN dbo.LoanSettlementStatus AS settlementStatus ON mainLoanSettlement.SettlementStatusId = settlementStatus.Id
    	AND settlementStatus.Id NOT IN (6, 9, 11)
    INNER JOIN loan.Loan AS mainLoan ON mainLoanSettlement.LoanId = mainLoan.Id
    INNER JOIN #ValidContract AS client ON client.ContractId = mainLoan.ContractId 
    INNER JOIN loan.LoanSettlementOffer AS  mainLoanSettlementOffer ON mainLoanSettlementOffer.SettlementId = mainLoanSettlement.Id 
	LEFT JOIN [loan].[SettlementNegotiatorAssignment] settlementAssignment ON settlementAssignment.LoanSettlementId = mainLoanSettlement.Id
            AND settlementAssignment.IsActive = 1
    LEFT JOIN loan.LoanAmount AS mainLoanAmount ON mainLoan.Id = mainLoanAmount.LoanId 
        AND IsCurrentValue = 1
    LEFT JOIN loan.LoanLender mainLoanLender ON mainLoanLender.LoanId = mainLoan.Id 
        AND mainLoanLender.IsActive = 1
WHERE mainLoanSettlementOffer.Id IN (
	SELECT DISTINCT OfferId FROM client.ScheduledLoanRelatedFees fee WHERE fee.StatusId IN (2, 10)
)

            UNION ALL -- add offer declined and now started the new settlement                    ******** STEP - 3 **************

SELECT 
    CONCAT(mainLoanSettlement.Id, '', mainLoanSettlementOffer.Id) as id,
    ISNULL(mainLoanSettlement.ExternalId,'') AS externalId,
    ISNULL(mainLoanAmount.Amount,'') AS balance,
    ISNULL(mainLoanSettlementOffer.TotalPayments,'')AS amount ,
    ISNULL(mainLoanSettlementOffer.id,'')AS offer,
    --ISNULL(mainLoanSettlementOfferStatus.Name,'')AS status,
    'SettlementVoided' AS status,
    ISNULL(mainLoanLender.LenderId,'')AS creditor,
    ISNULL(mainLoanSettlement.LoanId,'') AS debt,
	client.LeadId,
	client.ClientId,
    CASE WHEN mainLoanSettlement.ExternalId IS NULL THEN 'NO' ELSE 'YES' end AS syncStatus,
    CASE WHEN mainLoanSettlement.ExternalId IS NULL THEN 'NO' ELSE 'YES' end AS lastSuccessfulSyncStatus,
	client.paymentProcessor,
	settlementAssignment.UserId AS assignedUser,
    mainLoanSettlement.CreatedDate,
    mainLoanSettlement.UpdatedDate
FROM loan.LoanSettlement mainLoanSettlement
    INNER JOIN dbo.LoanSettlementStatus AS settlementStatus ON mainLoanSettlement.SettlementStatusId = settlementStatus.Id
    	AND settlementStatus.Id IN (6, 9, 11) 
    INNER JOIN loan.Loan AS mainLoan ON mainLoanSettlement.LoanId = mainLoan.Id
    INNER JOIN #ValidContract AS client ON client.ContractId = mainLoan.ContractId 
    INNER JOIN loan.LoanSettlementOffer AS  mainLoanSettlementOffer ON mainLoanSettlementOffer.SettlementId = mainLoanSettlement.Id 
        AND mainLoanSettlementOffer.OfferStatusId = 3 --declined
	LEFT JOIN [loan].[SettlementNegotiatorAssignment] settlementAssignment ON settlementAssignment.LoanSettlementId = mainLoanSettlement.Id
            AND settlementAssignment.IsActive = 1
    LEFT JOIN loan.LoanAmount AS mainLoanAmount ON mainLoan.Id = mainLoanAmount.LoanId 
        AND IsCurrentValue = 1
    LEFT JOIN loan.LoanLender mainLoanLender ON mainLoanLender.LoanId = mainLoan.Id 
        AND mainLoanLender.IsActive = 1
WHERE mainLoanSettlementOffer.Id IN (
	SELECT DISTINCT OfferId FROM client.ScheduledLoanRelatedFees fee WHERE fee.StatusId IN (2, 10)
)

IF OBJECT_ID('tempdb..#ValidContract') IS NOT NULL DROP TABLE #ValidContract;