-- 48276 

SELECT  
( SELECT ISNULL(tmpc.FriendlyId,'') FROM client.Contract AS tmpc JOIN company.ConfiguredStatus AS s ON tmpc.StatusId = s.Id WHERE s.IsContractSigned = 1 AND mainContract.Id=tmpc.Id ) AS 'client_id',
mainContractPaymentIntegration.IntegrationReference as 'cft_client_id' ,
mainLoan.Id AS 'id',
(ISNULL(mainLoan.ExternalId,'')) AS 'cft_debt_id',

(CASE WHEN mainLoan.LoanStatusId=1 THEN 'Enrolled' 
        WHEN mainLoan.LoanStatusId=2 THEN 'Enrolled-Negotiating'
        WHEN mainLoan.LoanStatusId=3 THEN 'Enrolled-New' 
        WHEN mainLoan.LoanStatusId=3 THEN 'Eligible'
        WHEN mainLoan.LoanStatusId=5 THEN 'ineligible' 
        WHEN mainLoan.LoanStatusId=6 THEN 'Under negotiation'
        WHEN mainLoan.LoanStatusId=7 THEN 'Making Payment' 
        WHEN mainLoan.LoanStatusId=8 THEN 'Repaid'
        WHEN mainLoan.LoanStatusId=9 THEN 'Created'
        WHEN mainLoan.LoanStatusId=10 THEN 'Settled'
        WHEN mainLoan.LoanStatusId=11 THEN 'Settled-Payments-Schedulded' 
       ELSE '' 
      END) AS status,
CONCAT('"',(SELECT ISNULL(mainLoanLender.AccountNumber,'') FROM  loan.LoanLender mainLoanLender WHERE mainLoanLender.LoanId = mainLoan.Id AND mainLoanLender.Version=1),'"') AS 'original_account_number',
CONCAT('"',(SELECT ISNULL(mainLoanLender.AccountNumber,'') FROM  loan.LoanLender mainLoanLender WHERE mainLoanLender.LoanId = mainLoan.Id AND mainLoanLender.IsActive=1),'"') AS 'current_account_number',

 (SELECT ISNULL(mainLoanLender.LenderId,'') FROM loan.LoanLender mainLoanLender WHERE mainLoanLender.LoanId = mainLoan.Id  AND mainLoanLender.Version =1) AS 'original_creditor_id',

 (SELECT ISNULL(mainLoanLender.LenderId,'') FROM loan.LoanLender mainLoanLender WHERE mainLoanLender.LoanId = mainLoan.Id  AND mainLoanLender.IsActive =1 ) AS 'current_creditor_id',
 (SELECT ISNULL(cli.ExternalId,'') FROM loan.LoanLender mainLoanLender 
 INNER JOIN loan.Lender lender ON lender.id = mainLoanLender.LenderId 
LEFT JOIN company.CompanyLender cl on cl.LenderId=lender.id 
	AND cl.CompanyId = 278
	AND cl.IsActive = 1
LEFT JOIN company.CompanyLenderIntegration cli ON cli.CompanyLenderId = cl.Id 
	--AND cli.PaymentIntegrationId = 5
	AND cli.PaymentIntegrationId = mainContractPaymentIntegration.CompanyPaymentIntegrationId
 WHERE mainLoanLender.LoanId = mainLoan.Id  AND mainLoanLender.Version =1) AS 'original_creditor_cft_id',
  (SELECT ISNULL(cli.ExternalId,'') FROM loan.LoanLender mainLoanLender 
 INNER JOIN loan.Lender lender ON lender.id = mainLoanLender.LenderId 
LEFT JOIN company.CompanyLender cl on cl.LenderId=lender.id 
	AND cl.CompanyId = 278
	AND cl.IsActive = 1
LEFT JOIN company.CompanyLenderIntegration cli ON cli.CompanyLenderId = cl.Id 
	--AND cli.PaymentIntegrationId = 5
	AND cli.PaymentIntegrationId = mainContractPaymentIntegration.CompanyPaymentIntegrationId
 WHERE mainLoanLender.LoanId = mainLoan.Id  AND mainLoanLender.IsActive =1) AS 'current_creditor_cft_id',

CONCAT('"', (SELECT ISNULL(lender.Name,'') FROM loan.LoanLender mainLoanLender 
 INNER JOIN loan.Lender lender ON lender.id = mainLoanLender.LenderId 
 WHERE mainLoanLender.LoanId = mainLoan.Id  AND mainLoanLender.Version =1),'"') AS 'original_creditor_name',

 CONCAT('"',  (SELECT ISNULL(lender.Name,'') FROM loan.LoanLender mainLoanLender 
 INNER JOIN loan.Lender lender ON lender.id = mainLoanLender.LenderId 
 WHERE mainLoanLender.LoanId = mainLoan.Id  AND mainLoanLender.IsActive =1),'"') AS 'current_creditor_name',
 (SELECT ISNULL(tmpmainLoanAmount.Amount,'') FROM loan.LoanAmount AS tmpmainLoanAmount WHERE tmpmainLoanAmount.IsCurrentValue=1 AND tmpmainLoanAmount.LoanId=mainLoan.Id ) AS 'current_balance',
 (SELECT ISNULL (SUM(tmpmainLoanAmount1.Amount),'') FROM loan.LoanAmount AS tmpmainLoanAmount1 WHERE tmpmainLoanAmount1.IsCurrentValue=1 AND tmpmainLoanAmount1.LoanId=mainLoan.Id ) AS 'enrolled_debt_amount',
 (select ISNULL(tmploanAmount.Amount,'')from loan.LoanAmount as tmploanAmount  where tmploanAmount.IsCurrentValue=1 and tmploanAmount.LoanId=mainLoan.Id) AS 'original_balance'
 
FROM loan.Loan AS mainLoan 
--INNER JOIN loan.LoanLender ll ON ll.LoanId=mainLoan.Id and ll.IsActive=1
--INNER JOIN loan.Lender lender ON lender.id = ll.LenderId 
--LEFT JOIN company.CompanyLender cl on cl.LenderId=lender.id 
	--AND cl.CompanyId = 302
	--AND cl.IsActive = 1
--LEFT JOIN company.CompanyLenderIntegration cli ON cli.CompanyLenderId = cl.Id 
	--AND cli.PaymentIntegrationId = 5
INNER JOIN client.Contract AS mainContract ON mainContract.id = mainLoan.ContractId
FULL OUTER JOIN client.ContractApplicant mainContractApplicant ON mainContract.Id = mainContractApplicant.ContractId 
FULL OUTER JOIN client.Detail AS mainDetail ON mainDetail.Id=mainContractApplicant.ClientId
INNER JOIN company.Company ON mainContract.CompanyId = company.Company.id
FULL OUTER JOIN company.ConfiguredStatus AS ConfiguredStatus ON mainContract.StatusId = ConfiguredStatus.Id 
LEFT OUTER JOIN client.ContractAssignment AS mainContractAssignment1 ON mainContractAssignment1.ContractId = mainContract.Id and mainContractAssignment1.RoleTypeId=1 and mainContractAssignment1.StatusId IN (1,2)
LEFT OUTER JOIN client.ContractAssignment AS mainContractAssignment2 ON mainContractAssignment2.ContractId = mainContract.Id and mainContractAssignment2.RoleTypeId=2 and mainContractAssignment2.StatusId IN (1,2)
LEFT OUTER JOIN client.ContractAssignment AS mainContractAssignment3 ON mainContractAssignment3.ContractId = mainContract.Id and mainContractAssignment3.RoleTypeId=3 and mainContractAssignment3.StatusId IN (1,2)
LEFT OUTER JOIN loan.LoanSettlement AS mainLoanSettlement ON mainLoanSettlement.LoanId = mainLoan.Id
LEFT OUTER JOIN loan.LoanSettlementOffer as mainLoanSettlementOffer ON mainLoanSettlementOffer.SettlementId = mainLoanSettlement.Id  AND mainLoanSettlementOffer.OfferStatusId=4
LEFT JOIN loan.LoanAmount AS amount ON mainLoan.Id = amount.LoanId AND amount.IsCurrentValue = 1
LEFT OUTER JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration  ON mainContract.Id = mainContractPaymentIntegration.ContractId
LEFT OUTER JOIN company.PaymentIntegration AS mainPaymentIntegration ON mainPaymentIntegration.Id = mainContractPaymentIntegration.CompanyPaymentIntegrationId
  
WHERE company.Company.id=278 
AND mainContractApplicant.IsPrimary=1
AND (ConfiguredStatus.IsContractSigned=1 )
AND mainContractApplicant.IsActive=1
 AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
	AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10
	
-- and mainContract.FriendlyId in (113393, 115340, 124024, 124306, 126663, 127662, 129185, 129372, 130551, 126334, 135554, 135551, 135550, 135924, 135940)
