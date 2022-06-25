SELECT * FROM company.Company WHERE id = 278
	--<Migration -1 Month>
	DECLARE @migration_date DATE = '' --yyyy-mm-dd is date format

	--  e.g @migration_date DATE = '2021-04-21' this is the example

	IF OBJECT_ID('tempdb..#Result') IS NOT NULL DROP TABLE #Result;

	SELECT  cd.Id, CONCAT('"',cd.DocumentName,'"') AS DocumentName, CONCAT('"',cd.DocumentReference,'"') AS DocumentReference, CONCAT('"',d.Name ,'"') as DocumentType, 
		( SELECT ISNULL(tmpc.FriendlyId,'') FROM client.Contract AS tmpc JOIN company.ConfiguredStatus AS s ON tmpc.StatusId = s.Id WHERE s.IsContractSigned = 0 AND c.Id=tmpc.Id ) AS leadId,
		( SELECT ISNULL(tmpc.FriendlyId,'') FROM client.Contract AS tmpc JOIN company.ConfiguredStatus AS s ON tmpc.StatusId = s.Id WHERE s.IsContractSigned = 1 AND c.Id=tmpc.Id ) AS clientId,
		u.IsSystemUser, cd.userId, cd.CreatedDate, cd.UpdatedDate,
		CONCAT('"','0D32A11A-2779-41BD-888B-0CEBC9B1D2F3/'+cd.DocumentReference ,'"') as source,
		CONCAT('"','Migration/ERG/Client/'+  cast(c.Id as varchar(20))+'/'+cd.DocumentReference ,'"') as destination
	INTO #Result
	FROM client.ContractCustomDocument AS cd 	
		INNER JOIN client.Contract AS c ON cd.ContractId = c.Id
		INNER JOIN [identity].[Users] AS u ON cd.UserId = u.Id
		LEFT JOIN company.ConfiguredStatus AS ConfiguredStatus ON c.StatusId = ConfiguredStatus.Id 
		LEFT JOIN client.ContractApplicant mainContractApplicant ON c.Id = mainContractApplicant.ContractId 
		INNER JOIN [dbo].DocumentType AS d ON cd.DocumentTypeId = d.Id
		LEFT OUTER JOIN [loan].[LoanSettlementOfferDocument] settlementDoc ON settlementDoc.DocumentId = cd.Id 
			--AND settlementDoc.IsActive = 1 and settlementDoc.Id is null
		LEFT OUTER JOIN [loan].[Document] loanDoc ON loanDoc.DocumentId = cd.Id 
			--AND loanDoc.IsActive = 1 and loanDoc.Id is null
		LEFT OUTER JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration ON mainContractPaymentIntegration.ContractId=c.Id
	WHERE 
		c.CompanyId = 278
		AND mainContractApplicant.IsPrimary=1
		AND mainContractApplicant.IsActive=1 
		AND loanDoc.Id IS NULL AND settlementDoc.Id IS NULL
		AND ((ConfiguredStatus.IsContractSigned = 1 AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
				AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10) 
			OR (ConfiguredStatus.IsContractSigned = 0 AND c.CreatedDate > @migration_date ));
	

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
	FROM #Result AS d 
	IF OBJECT_ID('tempdb..#Result') IS NOT NULL DROP TABLE #Result;
	-- and c.FriendlyId in (113393, 115340, 124024, 124306, 126663, 127662, 129185, 129372, 130551, 126334)