

--<Migration -1 Month>
DECLARE @migration_date DATE = '' --yyyy-mm-dd is date format

--  e.g @migration_date DATE = '2021-04-21' this is the example

SELECT   
   cfp.Id as id,
   CASE WHEN companyStatus.IsContractSigned = 0 THEN client.FriendlyId ELSE NULL END AS LeadId,
   CASE WHEN companyStatus.IsContractSigned = 1 THEN client.FriendlyId ELSE NULL END AS ClientId,
       ISNULL ((SELECT CASE WHEN fgpa.Answer=1 THEN 'YES' Else ' NO' END as filedBankruptcy  
                FROM budget.FinancialProfileCustomAnswer AS fgpa 
                        JOIN company.CompanyFinancialProfileQuestions AS q ON q.Id = fgpa.QuestionId
                        JOIN budget.FinancialProfile fProfile ON fgpa.FinancialProfileId = fProfile.Id
                WHERE q.Id = 66 AND client.Id= fProfile.ContractId),'') AS filedBankruptcy, 
        ISNULL( (SELECT fgpa.Answer
                FROM  budget.FinancialProfileCustomAnswer AS fgpa 
                        JOIN company.CompanyFinancialProfileQuestions AS q ON q.Id = fgpa.QuestionId
                        JOIN budget.FinancialProfile fProfile ON fgpa.FinancialProfileId = fProfile.Id
        WHERE q.Id=67 AND client.Id= fProfile.ContractId),'') AS bankcruptyFiledYear ,

		CONCAT('"', ISNULL ((SELECT fgpa.Answer
                FROM  budget.FinancialProfileCustomAnswer AS fgpa 
                        JOIN company.CompanyFinancialProfileQuestions AS q ON q.Id = fgpa.QuestionId
                        JOIN budget.FinancialProfile fProfile ON fgpa.FinancialProfileId = fProfile.Id
        WHERE q.Id=68 AND client.Id= fProfile.ContractId),'') ,'"')AS bankcruptyType, 

		 NULL AS  enrolledInCreditCounselling,

		 NULL AS ownHome,

		NULL AS homeValue,

		 NULL AS mortageAmount ,

		 NULL AS totalDependents,
		
		NULL AS ficoScore ,
		
		cfp.CreatedDate, cfp.UpdatedDate
		
FROM client.Contract AS client
      INNER JOIN [budget].[FinancialProfile] AS cfp ON client.Id = cfp.ContractId    
		join company.ConfiguredStatus as CompanyStatus on CompanyStatus.id = client.StatusId 
		LEFT JOIN [client].[ContractApplicant] AS a ON a.ContractId = client.Id AND a.IsPrimary = 1
		LEFT JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration ON mainContractPaymentIntegration.ContractId=client.Id
WHERE client.CompanyId = 278 
	AND a.IsPrimary=1 
	--AND (CompanyStatus.IsContractSigned=1 OR (CompanyStatus.IsContractSigned=0 AND client.CreatedDate > @migration_date))
	AND ((CompanyStatus.IsContractSigned = 1 AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
				AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10) 
			OR (CompanyStatus.IsContractSigned = 0 AND client.CreatedDate > @migration_date ))
-- and client.FriendlyId in (113393, 115340, 124024, 124306, 126663, 127662, 129185, 129372, 130551, 126334)

