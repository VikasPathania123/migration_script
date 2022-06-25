
	--<Migration -1 Month>
	DECLARE @migration_date DATE = '' --yyyy-mm-dd is date format

	--  e.g @migration_date DATE = '2021-04-21' this is the example


	IF OBJECT_ID('tempdb..#ValidContract') IS NOT NULL DROP TABLE #ValidContract;
	IF OBJECT_ID('tempdb..#Result') IS NOT NULL DROP TABLE #Result;

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

	SELECT settlementDoc.Id, CONCAT('"',cd.DocumentName,'"')AS DocumentName , CONCAT('"',cd.DocumentReference,'"') AS DocumentReference,
		CONCAT('"',d.Name,'"')  as DocumentType, client.FriendlyId AS ClientId,CONCAT(mainLoanSettlement.Id, '', mainLoanSettlementOffer.Id) as settlementId,	
		u.IsSystemUser, cd.userId, cd.CreatedDate, cd.UpdatedDate  
	INTO #Result
	FROM client.ContractCustomDocument AS cd 	 
		INNER JOIN #ValidContract AS client ON client.ContractId = cd.ContractId    
		INNER JOIN [dbo].DocumentType AS d ON cd.DocumentTypeId = d.Id
		INNER JOIN [identity].[Users] AS u ON cd.UserId = u.Id
		INNER JOIN [loan].[LoanSettlementOfferDocument] settlementDoc ON settlementDoc.DocumentId = cd.Id 
			AND settlementDoc.IsActive = 1
		INNER JOIN loan.LoanSettlementOffer AS  mainLoanSettlementOffer ON mainLoanSettlementOffer.Id = settlementDoc.OfferId 
			AND mainLoanSettlementOffer.OfferStatusId <> 3
		INNER JOIN loan.LoanSettlement mainLoanSettlement ON mainLoanSettlementOffer.SettlementId = mainLoanSettlement.Id 
			AND mainLoanSettlement.SettlementStatusId IN (6, 9, 11)

		--UNION ALL -- add  not offer declined,accepted,paymentplanstarted,paidoff                      ******** STEP - 2 **************
	INSERT INTO #Result
	SELECT settlementDoc.Id, CONCAT('"',cd.DocumentName,'"')AS DocumentName , CONCAT('"',cd.DocumentReference,'"') AS DocumentReference,
		CONCAT('"',d.Name,'"')  as DocumentType, client.FriendlyId AS ClientId,CONCAT(mainLoanSettlement.Id, '', mainLoanSettlementOffer.Id) as settlementId,	
		u.IsSystemUser, cd.userId, cd.CreatedDate, cd.UpdatedDate  
	FROM client.ContractCustomDocument AS cd 	 
		INNER JOIN #ValidContract AS client ON client.ContractId = cd.ContractId    
		INNER JOIN [dbo].DocumentType AS d ON cd.DocumentTypeId = d.Id
		INNER JOIN [identity].[Users] AS u ON cd.UserId = u.Id
		INNER JOIN [loan].[LoanSettlementOfferDocument] settlementDoc ON settlementDoc.DocumentId = cd.Id 
			AND settlementDoc.IsActive = 1
		INNER JOIN loan.LoanSettlementOffer AS  mainLoanSettlementOffer ON mainLoanSettlementOffer.Id = settlementDoc.OfferId
		INNER JOIN loan.LoanSettlement mainLoanSettlement ON mainLoanSettlementOffer.SettlementId = mainLoanSettlement.Id 
			AND mainLoanSettlement.SettlementStatusId NOT IN (6, 9, 11)
	WHERE mainLoanSettlementOffer.Id IN (
		SELECT DISTINCT OfferId FROM client.ScheduledLoanRelatedFees fee WHERE fee.StatusId IN (2, 10)
	)


		--UNION ALL -- add offer declined and now started the new settlement                    ******** STEP - 3 **************
	INSERT INTO #Result
	SELECT settlementDoc.Id, CONCAT('"',cd.DocumentName,'"')AS DocumentName , CONCAT('"',cd.DocumentReference,'"') AS DocumentReference,
		CONCAT('"',d.Name,'"')  as DocumentType, client.FriendlyId AS ClientId,CONCAT(mainLoanSettlement.Id, '', mainLoanSettlementOffer.Id) as settlementId,	
		u.IsSystemUser, cd.userId, cd.CreatedDate, cd.UpdatedDate  
	FROM client.ContractCustomDocument AS cd 	 
		INNER JOIN #ValidContract AS client ON client.ContractId = cd.ContractId    
		INNER JOIN [dbo].DocumentType AS d ON cd.DocumentTypeId = d.Id
		INNER JOIN [identity].[Users] AS u ON cd.UserId = u.Id
		INNER JOIN [loan].[LoanSettlementOfferDocument] settlementDoc ON settlementDoc.DocumentId = cd.Id 
			AND settlementDoc.IsActive = 1
		INNER JOIN loan.LoanSettlementOffer AS  mainLoanSettlementOffer ON mainLoanSettlementOffer.Id = settlementDoc.OfferId
			AND mainLoanSettlementOffer.OfferStatusId = 3 --declined	
		INNER JOIN loan.LoanSettlement mainLoanSettlement ON mainLoanSettlementOffer.SettlementId = mainLoanSettlement.Id 
			AND mainLoanSettlement.SettlementStatusId IN (6, 9, 11) 
	WHERE mainLoanSettlementOffer.Id IN (
		SELECT DISTINCT OfferId FROM client.ScheduledLoanRelatedFees fee WHERE fee.StatusId IN (2, 10)
	)

	SELECT d.*, (SELECT COUNT(*) FROM [client].[ContractDocumentTag] AS docTags 
				INNER JOIN [dbo].Tag tag ON tag.Id = docTags.TagId
			  WHERE docTags.ContractDocumentId = d.Id) AS  tagCount,
		CONCAT('"',STUFF  
		(  
			(  
			  SELECT DISTINCT ','+ CAST(tag.Value AS VARCHAR(MAX))  
			  FROM [client].[ContractDocumentTag] AS docTags 
				INNER JOIN [dbo].Tag tag ON tag.Id = docTags.TagId
			  WHERE docTags.ContractDocumentId = d.Id 
			  FOR XMl PATH('')  
			),1,1,''  
		),'"') AS Tags 	
	FROM #Result AS d;

	IF OBJECT_ID('tempdb..#ValidContract') IS NOT NULL DROP TABLE #ValidContract;