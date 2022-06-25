DECLARE @compare_date DATE = DATEADD(month,-1,GETDATE());

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
    AND (CompanyStatus.IsContractSigned=1 OR (CompanyStatus.IsContractSigned = 0 AND mainContract.CreatedDate > @compare_date))
    AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
	AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10

	---START FROM HERE BELOW ARE THE 3 BATCHES

SELECT
    'Settlement: Accepted,PaymentPlanStarted,PaidOff' AS BatchType,
    COUNT(*)
FROM loan.LoanSettlement mainLoanSettlement
    INNER JOIN dbo.LoanSettlementStatus AS settlementStatus ON mainLoanSettlement.SettlementStatusId = settlementStatus.Id
    	AND settlementStatus.Id IN (6, 9, 11) 
    INNER JOIN loan.Loan AS mainLoan ON mainLoanSettlement.LoanId = mainLoan.Id
    INNER JOIN #ValidContract AS client ON client.ContractId = mainLoan.ContractId 
    INNER JOIN loan.LoanSettlementOffer AS  mainLoanSettlementOffer ON mainLoanSettlementOffer.SettlementId = mainLoanSettlement.Id 
        AND mainLoanSettlementOffer.OfferStatusId <> 3
    LEFT JOIN loan.LoanAmount AS mainLoanAmount ON mainLoan.Id = mainLoanAmount.LoanId 
        AND IsCurrentValue = 1
    LEFT JOIN loan.LoanLender mainLoanLender ON mainLoanLender.LoanId = mainLoan.Id 
        AND mainLoanLender.IsActive = 1

           -- UNION ALL -- add  not offer declined,accepted,paymentplanstarted,paidoff                      ******** STEP - 2 **************

SELECT 
    'OfferAccepted' AS BatchType,
    COUNT(*)
FROM loan.LoanSettlement mainLoanSettlement
    INNER JOIN dbo.LoanSettlementStatus AS settlementStatus ON mainLoanSettlement.SettlementStatusId = settlementStatus.Id
    	AND settlementStatus.Id NOT IN (6, 9, 11)
    INNER JOIN loan.Loan AS mainLoan ON mainLoanSettlement.LoanId = mainLoan.Id
    INNER JOIN #ValidContract AS client ON client.ContractId = mainLoan.ContractId 
    INNER JOIN loan.LoanSettlementOffer AS  mainLoanSettlementOffer ON mainLoanSettlementOffer.SettlementId = mainLoanSettlement.Id 
        AND mainLoanSettlementOffer.OfferStatusId = 4 --ACCEPTED
    LEFT JOIN loan.LoanAmount AS mainLoanAmount ON mainLoan.Id = mainLoanAmount.LoanId 
        AND IsCurrentValue = 1
    LEFT JOIN loan.LoanLender mainLoanLender ON mainLoanLender.LoanId = mainLoan.Id 
        AND mainLoanLender.IsActive = 1
WHERE mainLoanSettlementOffer.Id IN (
	SELECT DISTINCT OfferId FROM client.ScheduledLoanRelatedFees fee WHERE fee.StatusId IN (2, 10)
)

           -- UNION ALL -- add offer declined                     ******** STEP - 3 **************

SELECT 'SettlementVoided' AS BatchType,
    COUNT(*)
FROM loan.LoanSettlement mainLoanSettlement
    INNER JOIN dbo.LoanSettlementStatus AS settlementStatus ON mainLoanSettlement.SettlementStatusId = settlementStatus.Id
    	AND settlementStatus.Id NOT IN (6, 9, 11) 
    INNER JOIN loan.Loan AS mainLoan ON mainLoanSettlement.LoanId = mainLoan.Id
    INNER JOIN #ValidContract AS client ON client.ContractId = mainLoan.ContractId 
    INNER JOIN loan.LoanSettlementOffer AS  mainLoanSettlementOffer ON mainLoanSettlementOffer.SettlementId = mainLoanSettlement.Id 
        AND mainLoanSettlementOffer.OfferStatusId <> 4 --accepted
    LEFT JOIN loan.LoanAmount AS mainLoanAmount ON mainLoan.Id = mainLoanAmount.LoanId 
        AND IsCurrentValue = 1
    LEFT JOIN loan.LoanLender mainLoanLender ON mainLoanLender.LoanId = mainLoan.Id 
        AND mainLoanLender.IsActive = 1
WHERE mainLoanSettlementOffer.Id IN (
	SELECT DISTINCT OfferId FROM client.ScheduledLoanRelatedFees fee WHERE fee.StatusId IN (2, 10)
)

IF OBJECT_ID('tempdb..#ValidContract') IS NOT NULL DROP TABLE #ValidContract;