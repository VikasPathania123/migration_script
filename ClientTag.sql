SELECT 
mainContract.FriendlyId as ClientId,
mainTag.Id as TagId,
tagArchive.CreatedDate, tagArchive.UpdatedDate
FROM client.ContractTag mainContractTag
INNER JOIN client.Contract mainContract ON mainContract.Id = mainContractTag.ContractId
INNER JOIN dbo.Tag mainTag ON  mainTag.Id=mainContractTag.TagId
INNER JOIN [company].[ConfiguredAccountTag] account ON mainContract.CompanyId = account.CompanyId AND account.TagId = mainTag.Id
INNER JOIN [client].[TagArchive] AS tagArchive ON tagArchive.TagId = mainContractTag.TagId AND tagArchive.ContractId =  mainContractTag.ContractId
LEFT OUTER JOIN client.ContractApplicant mainContractApplicant ON mainContract.Id = mainContractApplicant.ContractId
LEFT OUTER JOIN company.ConfiguredStatus AS ConfiguredStatus ON mainContract.StatusId = ConfiguredStatus.Id
LEFT OUTER JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration ON mainContractPaymentIntegration.ContractId=mainContract.Id
WHERE mainContract.CompanyId=278
      AND mainContractApplicant.IsActive=1
      AND ConfiguredStatus.IsContractSigned=1
	  AND mainContractApplicant.IsPrimary=1
	  AND (mainContractPaymentIntegration.IntegrationReference IS NOT NULL AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10)
        -- and mainContract.FriendlyId in (113393, 115340, 124024, 124306, 126663, 127662, 129185, 129372, 130551, 126334)
