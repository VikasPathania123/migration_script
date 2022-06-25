
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
    ISNULL(mainContractPaymentIntegration.IntegrationReference,'') AS extClientId,
    ISNULL(mainPaymentIntegration.IntegrationFriendlyName,'') AS paymentProcessor,
	mainPaymentIntegration.Id AS PaymentIntegrationId
    
INTO #ValidContract
FROM client.Contract AS mainContract
    INNER JOIN company.ConfiguredStatus as CompanyStatus on CompanyStatus.id = mainContract.StatusId 
    LEFT JOIN client.ContractApplicant mainContractApplicant ON mainContract.Id = mainContractApplicant.ContractId   
        AND mainContractApplicant.IsPrimary = 1
        AND mainContractApplicant.IsActive = 1
    LEFT JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration  ON mainContract.Id = mainContractPaymentIntegration.ContractId
    LEFT JOIN company.PaymentIntegration AS mainPaymentIntegration ON mainPaymentIntegration.Id = mainContractPaymentIntegration.CompanyPaymentIntegrationId 
WHERE mainContract.CompanyId = 278
    AND (CompanyStatus.IsContractSigned=1 OR (CompanyStatus.IsContractSigned = 0 AND mainContract.CreatedDate > @migration_date))
    AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
    AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10

    ---START FROM HERE BELOW ARE THE 3 BATCHES

SELECT 
    CONCAT(mainLoanSettlement.Id, '', mainLoanSettlementOffer.Id) as id,
    client.ClientId as client_id,
    client.extClientId as cft_client_id,
    ISNULL(mainLoanSettlement.ExternalId,'') AS  cft_settlement_id,
    ISNULL(mainLoanAmount.Amount,'') AS balance,
    ISNULL(mainLoanSettlementOffer.TotalPayments,'')AS amount ,
    ISNULL(mainLoanLender.AccountNumber,'') as current_account_number,
    ISNULL(mainLoanSettlement.LoanId,'') AS debt_id,
    (ISNULL(mainLoan.ExternalId,'')) AS cft_debt_id,
    ISNULL(mainLoanLender.LenderId,'')AS creditor_id,
    ISNULL(cli.ExternalId,'')AS cft_creditor_id,
    settlementStatus.Name AS status,
    mainLoanSettlement.CreatedDate as created_on,
    mainLoanSettlement.UpdatedDate as updated_on
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
    LEFT JOIN loan.Lender lender ON lender.Id = mainLoanLender.LenderId
    LEFT JOIN company.CompanyLender cl on cl.LenderId=lender.id 
    AND cl.CompanyId = 278
    AND cl.IsActive = 1
LEFT JOIN company.CompanyLenderIntegration cli ON cli.CompanyLenderId = cl.Id AND cli.PaymentIntegrationId = client.PaymentIntegrationId
 --AND cli.PaymentIntegrationId = 5

            UNION ALL -- add  not offer declined,accepted,paymentplanstarted,paidoff                      ******** STEP - 2 **************

SELECT 
     CONCAT(mainLoanSettlement.Id, '', mainLoanSettlementOffer.Id) as id,
    client.ClientId as client_id,
    client.extClientId as cft_client_id,
    ISNULL(mainLoanSettlement.ExternalId,'') AS  cft_settlement_id,
    ISNULL(mainLoanAmount.Amount,'') AS balance,
    ISNULL(mainLoanSettlementOffer.TotalPayments,'')AS amount ,
    ISNULL(mainLoanLender.AccountNumber,'') as account_number,
    ISNULL(mainLoanSettlement.LoanId,'') AS debt,
    (ISNULL(mainLoan.ExternalId,'')) AS cft_debt_id,
    ISNULL(mainLoanLender.LenderId,'')AS creditor,
    ISNULL(cli.ExternalId,'')AS cft_creditor_id,
    settlementStatus.Name AS status,
    mainLoanSettlement.CreatedDate,
    mainLoanSettlement.UpdatedDate
FROM loan.LoanSettlement mainLoanSettlement
    INNER JOIN dbo.LoanSettlementStatus AS settlementStatus ON mainLoanSettlement.SettlementStatusId = settlementStatus.Id
        AND settlementStatus.Id NOT IN (6, 9, 11)
    INNER JOIN loan.Loan AS mainLoan ON mainLoanSettlement.LoanId = mainLoan.Id
    INNER JOIN #ValidContract AS client ON client.ContractId = mainLoan.ContractId 
    INNER JOIN loan.LoanSettlementOffer AS  mainLoanSettlementOffer ON mainLoanSettlementOffer.SettlementId = mainLoanSettlement.Id 
    LEFT JOIN loan.LoanAmount AS mainLoanAmount ON mainLoan.Id = mainLoanAmount.LoanId 
        AND IsCurrentValue = 1
    LEFT JOIN loan.LoanLender mainLoanLender ON mainLoanLender.LoanId = mainLoan.Id 
        AND mainLoanLender.IsActive = 1
        LEFT JOIN loan.Lender lender ON lender.Id = mainLoanLender.LenderId
    LEFT JOIN company.CompanyLender cl on cl.LenderId=lender.id 
    AND cl.CompanyId = 278
    AND cl.IsActive = 1
LEFT JOIN company.CompanyLenderIntegration cli ON cli.CompanyLenderId = cl.Id AND cli.PaymentIntegrationId = client.PaymentIntegrationId
    --AND cli.PaymentIntegrationId = 5
WHERE mainLoanSettlementOffer.Id IN (
    SELECT DISTINCT OfferId FROM client.ScheduledLoanRelatedFees fee WHERE fee.StatusId IN (2, 10)
)

            UNION ALL -- add offer declined and now started the new settlement                    ******** STEP - 3 **************

SELECT 
     CONCAT(mainLoanSettlement.Id, '', mainLoanSettlementOffer.Id) as id,
    client.ClientId as client_id,
    client.extClientId as cft_client_id,
    ISNULL(mainLoanSettlement.ExternalId,'') AS  cft_settlement_id,
    ISNULL(mainLoanAmount.Amount,'') AS balance,
    ISNULL(mainLoanSettlementOffer.TotalPayments,'')AS amount ,
    ISNULL(mainLoanLender.AccountNumber,'') as account_number,
    ISNULL(mainLoanSettlement.LoanId,'') AS debt,
    (ISNULL(mainLoan.ExternalId,'')) AS cft_debt_id,
    ISNULL(mainLoanLender.LenderId,'')AS creditor,
    ISNULL(cli.ExternalId,'')AS cft_creditor_id,
    settlementStatus.Name AS status,
    mainLoanSettlement.CreatedDate,
    mainLoanSettlement.UpdatedDate
FROM loan.LoanSettlement mainLoanSettlement
    INNER JOIN dbo.LoanSettlementStatus AS settlementStatus ON mainLoanSettlement.SettlementStatusId = settlementStatus.Id
        AND settlementStatus.Id IN (6, 9, 11) 
    INNER JOIN loan.Loan AS mainLoan ON mainLoanSettlement.LoanId = mainLoan.Id
    INNER JOIN #ValidContract AS client ON client.ContractId = mainLoan.ContractId 
    INNER JOIN loan.LoanSettlementOffer AS  mainLoanSettlementOffer ON mainLoanSettlementOffer.SettlementId = mainLoanSettlement.Id 
        AND mainLoanSettlementOffer.OfferStatusId = 3 --declined
    LEFT JOIN loan.LoanAmount AS mainLoanAmount ON mainLoan.Id = mainLoanAmount.LoanId 
        AND IsCurrentValue = 1
    LEFT JOIN loan.LoanLender mainLoanLender ON mainLoanLender.LoanId = mainLoan.Id 
        AND mainLoanLender.IsActive = 1
        LEFT JOIN loan.Lender lender ON lender.Id = mainLoanLender.LenderId
    LEFT JOIN company.CompanyLender cl on cl.LenderId=lender.id 
    AND cl.CompanyId = 278
    AND cl.IsActive = 1
LEFT JOIN company.CompanyLenderIntegration cli ON cli.CompanyLenderId = cl.Id AND cli.PaymentIntegrationId = client.PaymentIntegrationId
   -- AND cli.PaymentIntegrationId = 5
WHERE mainLoanSettlementOffer.Id IN (
    SELECT DISTINCT OfferId FROM client.ScheduledLoanRelatedFees fee WHERE fee.StatusId IN (2, 10)
)

IF OBJECT_ID('tempdb..#ValidContract') IS NOT NULL DROP TABLE #ValidContract;