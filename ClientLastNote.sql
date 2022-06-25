SELECT al.Id, mainContract.FriendlyId as ClientId, CONCAT('"',REPLACE(al.LastNote,'"','""') ,'"') as LastNote, al.CreatedDate, al.UpdatedDate
FROM [audit].[LastNote] al 	
INNER JOIN client.Contract mainContract ON mainContract.Id=al.ContractId 
LEFT OUTER JOIN client.ContractApplicant mainContractApplicant ON mainContract.Id = mainContractApplicant.ContractId
LEFT OUTER JOIN company.ConfiguredStatus AS ConfiguredStatus ON mainContract.StatusId = ConfiguredStatus.Id
LEFT OUTER JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration ON mainContractPaymentIntegration.ContractId=mainContract.Id
WHERE mainContract.CompanyId=278
AND mainContractApplicant.IsActive=1
AND mainContractApplicant.IsPrimary=1
AND ConfiguredStatus.IsContractSigned=1
AND (mainContractPaymentIntegration.IntegrationReference IS NOT NULL AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10)
-- and mainContract.FriendlyId in (113393, 115340, 124024, 124306, 126663, 127662, 129185, 129372, 130551, 126334)