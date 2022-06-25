

--<Migration -1 Month>
DECLARE @migration_date DATE = '' --yyyy-mm-dd is date format

--  e.g @migration_date DATE = '2021-04-21' this is the example

select 
mainLoan.Id,
 CASE WHEN companyStatus.IsContractSigned = 0 THEN mainContract.FriendlyId ELSE NULL END AS LeadId,
   CASE WHEN companyStatus.IsContractSigned = 1 THEN mainContract.FriendlyId ELSE NULL END AS ClientId,
ISNULL(mainamount.Amount,'') as outstandingDebtAmount,
ISNULL((SELECT COUNT(tmpLoan.Id) FROM loan.Loan AS tmpLoan WHERE tmpLoan.ContractId=maincontract.Id),'') AS debtCount,
dt.Name as debtType,
ISNULL(mainLoanLender.LenderId ,'')as creditor,
ISNULL(maincontract.FriendlyId,'') as Lead,
ISNULL(maincontract.CompanyId,'') as CompanyID,
ac.ScoreValue  as creditScore,
mainContract.CreatedDate, mainContract.UpdatedDate
from loan.Loan mainLoan
inner join client.Contract as mainContract ON mainContract.id = mainLoan.ContractId
LEFT JOIN [client].[ContractApplicant] AS a ON a.ContractId = mainContract.Id AND a.IsPrimary = 1
LEFT JOIN [client].[ApplicantCreditScore]  AS ac ON a.Id = ac.ApplicantId
left join loan.LoanAmount as mainamount on mainLoan.Id = mainamount.LoanId and mainamount.IsCurrentValue=1
left join loan.LoanLender as mainLoanLender ON mainLoanLender.LoanId = mainLoan.Id and mainLoanLender.IsActive=1
left JOIN loan.Lender as lender ON lender.Id = mainLoanLender.LenderId 
left JOIN dbo.DebtType as dt ON dt.id = lender.DebtTypeId
left join company.ConfiguredStatus as companystatus on companystatus.Id = mainContract.StatusId
LEFT JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration ON mainContractPaymentIntegration.ContractId=mainContract.Id
WHERE mainContract.CompanyId = 278 
	AND a.IsPrimary=1 
	--AND (CompanyStatus.IsContractSigned=1 OR (CompanyStatus.IsContractSigned=0 AND mainContract.CreatedDate > @migration_date))
	AND ((CompanyStatus.IsContractSigned = 1 AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
			AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10) 
		OR (CompanyStatus.IsContractSigned = 0 AND mainContract.CreatedDate > @migration_date ))
-- and mainContract.FriendlyId in (113393, 115340, 124024, 124306, 126663, 127662, 129185, 129372, 130551, 126334)