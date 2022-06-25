	DECLARE @migration_date DATE = '' --yyyy-mm-dd is date format	

	IF OBJECT_ID('tempdb..#Result') IS NOT NULL DROP TABLE #Result;
	IF OBJECT_ID('tempdb..#Expense') IS NOT NULL DROP TABLE #Expense;
	IF OBJECT_ID('tempdb..#Income') IS NOT NULL DROP TABLE #Income;
	IF OBJECT_ID('tempdb..#Hardship') IS NOT NULL DROP TABLE #Hardship;

	-------------------------- OTHER INCOME ------------------------------------
	
	SELECT client.Id AS contractId,		
		CAST(income.Amount AS varchar(MAX)) AS Value,
		(CASE   
			   WHEN iType.Name = 'Net Income' OR iType.Name = 'Net Income - CoSigner' THEN 'W-2'  
			   WHEN iType.Name = 'SocialSecurity' OR iType.Name = 'SocialSecurity - CoSigner' THEN 'Social Security'    
			   WHEN iType.Name = 'Alimony' OR iType.Name = 'Alimony - CoSigner' THEN 'Alimony'    
			   WHEN iType.Name = 'ChildSupport' OR iType.Name = 'ChildSupport - CoSigner' THEN 'Child Support'    
			   WHEN iType.Name = 'Disability' THEN 'Disability' 
			   WHEN iType.Name = 'Retirement' OR iType.Name = 'Retirement - CoSigner' THEN 'Retirement'
			   WHEN iType.Name = 'Rental' OR iType.Name = 'Rental - CoSigner' THEN 'Rental'          
		   ELSE 'Others' END) AS [Type]	
	INTO #Income
	FROM budget.UnEarnedIncome AS income
		INNER JOIN client.Contract AS client ON income.ContractId = client.Id	
		INNER JOIN dbo.IncomeType AS iType ON income.IncomeTypeId = iType.Id	
		INNER JOIN company.ConfiguredStatus AS companyStatus ON client.StatusId = companyStatus.Id	
		LEFT JOIN [client].[ContractApplicant] AS a ON a.ContractId = client.Id
		LEFT JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration ON mainContractPaymentIntegration.ContractId=client.Id		
	WHERE client.CompanyId = 278 AND a.IsPrimary=1 	
		AND ((CompanyStatus.IsContractSigned = 1 AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
				AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10) 
			OR (CompanyStatus.IsContractSigned = 0 AND client.CreatedDate > @migration_date ))

	-------------------------- NET INCOME ------------------------------------

	INSERT INTO #Income
	SELECT client.Id AS contractId,
		CAST(income.EarnedIncome AS varchar(MAX)) AS Value,
		'W-2' AS [Type]	
	FROM budget.Income AS income
		INNER JOIN client.Contract AS client ON income.ContractId = client.Id			
		INNER JOIN company.ConfiguredStatus AS companyStatus ON client.StatusId = companyStatus.Id	
		LEFT JOIN [client].[ContractApplicant] AS a ON a.ContractId = client.Id
		LEFT JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration ON mainContractPaymentIntegration.ContractId=client.Id
	WHERE client.CompanyId = 278 AND a.IsPrimary=1 		
		AND ((CompanyStatus.IsContractSigned = 1 AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
				AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10) 
			OR (CompanyStatus.IsContractSigned = 0 AND client.CreatedDate > @migration_date ))	

	-------------------------- EXPENCE ------------------------------------

	SELECT client.Id AS contractId,
		CAST(expense.Amount AS varchar(MAX)) AS Value,
		( CASE   
			   WHEN eTyoe.Name = 'Rent / Mortgage' OR eTyoe.Name = '2nd Mortgage/Rent' THEN 'Mortgage'    
			   WHEN eTyoe.Name = 'Gas / Oil' OR eTyoe.Name = 'Average Gas / Electric / Oil' THEN 'Gas / Oil'    
			   WHEN eTyoe.Name = 'Cable / Satellite' THEN 'Cable / Satellite'    
			   WHEN eTyoe.Name = 'Internet' THEN 'Internet' 
			   WHEN eTyoe.Name = 'Phone' OR eTyoe.Name = 'Cell Phone' OR eTyoe.Name = 'Telephone' THEN 'Phone'
			   WHEN eTyoe.Name = 'Auto Payments' OR eTyoe.Name = 'Auto Loans' THEN 'Auto Payments'          
			   WHEN eTyoe.Name = 'Auto Insurance' OR eTyoe.Name = 'Home Owners Insurance' OR eTyoe.Name = 'Home/Renter''s Insurance' THEN 'Insurance'        
			   WHEN eTyoe.Name = 'Fuel' THEN 'Fuel'   
			   WHEN eTyoe.Name = 'Medications' THEN 'Medication'   
		   ELSE 'Others' END) AS [Type]  
	INTO #Expense
	FROM budget.Expense AS expense
		INNER JOIN client.Contract AS client ON expense.ContractId = client.Id
		INNER JOIN dbo.ExpenseType AS eTyoe ON expense.ExpenseTypeId = eTyoe.Id
		INNER JOIN company.ConfiguredStatus AS companyStatus ON client.StatusId = companyStatus.Id	
		LEFT JOIN [client].[ContractApplicant] AS a ON a.ContractId = client.Id
		LEFT JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration ON mainContractPaymentIntegration.ContractId=client.Id
	WHERE client.CompanyId = 278 AND a.IsPrimary=1 		
		AND ((CompanyStatus.IsContractSigned = 1 AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
				AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10) 
			OR (CompanyStatus.IsContractSigned = 0 AND client.CreatedDate > @migration_date ))	

	-------------------------- Hardship ------------------------------------
	SELECT client.Id AS contractId,
		CASE WHEN companyStatus.IsContractSigned = 0 THEN client.FriendlyId ELSE NULL END AS LeadId ,
		CASE WHEN companyStatus.IsContractSigned = 1 THEN client.FriendlyId ELSE NULL END AS ClientId,
		REPLACE(CONCAT(hd.Name,'-',fp.HardshipDescription),'"','""')  AS Value,
		NULL AS [Type] 
	INTO #Hardship
    FROM budget.Hardship  h
		INNER JOIN [budget].FinancialProfile AS fp ON fp.Id = h.FinancialProfileId	
		INNER JOIN [dbo].[HardshipDefinition] AS hd ON h.HardshipDefinitionId = hd.Id
		INNER JOIN client.Contract AS client ON fp.ContractId = client.Id
		INNER JOIN company.ConfiguredStatus AS companyStatus ON client.StatusId = companyStatus.Id	
		LEFT JOIN [client].[ContractApplicant] AS a ON a.ContractId = client.Id 
		LEFT JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration ON mainContractPaymentIntegration.ContractId=client.Id
	WHERE  client.CompanyId = 278 AND a.IsPrimary=1 	
		AND ((CompanyStatus.IsContractSigned = 1 AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
			AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10) 
			OR (CompanyStatus.IsContractSigned = 0 AND client.CreatedDate > @migration_date ))

	-------------------------- FINAL RESULT ------------------------------------
	
	SELECT c.Id,
		CASE WHEN companyStatus.IsContractSigned = 0 THEN c.FriendlyId ELSE NULL END AS LeadId,
		CASE WHEN companyStatus.IsContractSigned = 1 THEN c.FriendlyId ELSE NULL END AS ClientId, 
		'Hardship' AS Source,
		CONCAT('"',STUFF  
		(  
			(  
			  SELECT '|'+ CAST(h.Value AS VARCHAR(MAX)) 
			  FROM #Hardship AS h   
			  WHERE h.contractId = c.Id 
			  FOR XMl PATH('')  
			),1,1,''  
		),'"') AS Value, c.CreatedDate, c.UpdatedDate 	
	INTO #Result
	FROM client.Contract AS c
		INNER JOIN company.ConfiguredStatus AS companyStatus ON c.StatusId = companyStatus.Id			
	WHERE c.CompanyId = 278 AND c.Id IN (SELECT contractId FROM #Hardship )

	INSERT INTO #Result
	SELECT c.Id, 
		CASE WHEN companyStatus.IsContractSigned = 0 THEN c.FriendlyId ELSE NULL END AS LeadId,
		CASE WHEN companyStatus.IsContractSigned = 1 THEN c.FriendlyId ELSE NULL END AS ClientId, 
		'Expense' AS Source,
		CONCAT('"',STUFF  
		(  
			(  
			  SELECT '|'+ CONCAT(CAST(e.Type AS VARCHAR(MAX)),':',e.Value)  
			  FROM #Expense AS e  
			  WHERE e.contractId = c.Id 
			  FOR XMl PATH('')  
			),1,1,''  
		),'"'), 
		c.CreatedDate,
		c.UpdatedDate	
	FROM client.Contract AS c
		INNER JOIN company.ConfiguredStatus AS companyStatus ON c.StatusId = companyStatus.Id	
	WHERE c.CompanyId = 278 AND c.Id IN (SELECT contractId FROM #Expense )

	INSERT INTO #Result
	SELECT c.Id,
		CASE WHEN companyStatus.IsContractSigned = 0 THEN c.FriendlyId ELSE NULL END AS LeadId,
		CASE WHEN companyStatus.IsContractSigned = 1 THEN c.FriendlyId ELSE NULL END AS ClientId, 
		'Income' AS Source,
		CONCAT('"',STUFF  
		(  
			(  
			  SELECT '|'+ CONCAT(CAST(i.Type AS VARCHAR(MAX)),':',i.Value)  
			  FROM #Income AS i   
			  WHERE i.contractId = c.Id 
			  FOR XMl PATH('')  
			),1,1,''  
		),'"') AS Value, c.CreatedDate, c.UpdatedDate 	
	FROM client.Contract AS c
		INNER JOIN company.ConfiguredStatus AS companyStatus ON c.StatusId = companyStatus.Id			
	WHERE c.CompanyId = 278 AND c.Id IN (SELECT contractId FROM #Income )	

	SELECT * FROM #Result ORDER BY Id

	IF OBJECT_ID('tempdb..#Result') IS NOT NULL DROP TABLE #Result;
	IF OBJECT_ID('tempdb..#Expense') IS NOT NULL DROP TABLE #Expense;
	IF OBJECT_ID('tempdb..#Income') IS NOT NULL DROP TABLE #Income;
	IF OBJECT_ID('tempdb..#Hardship') IS NOT NULL DROP TABLE #Hardship;