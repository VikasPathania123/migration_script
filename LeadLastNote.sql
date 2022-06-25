--<Migration -1 Month>
DECLARE @migration_date DATE = '' --yyyy-mm-dd is date format

--  e.g @migration_date DATE = '2021-04-21' this is the example

SELECT al.Id, mainContract.FriendlyId as LeadId, CONCAT('"',al.LastNote,'"') as LastNote, al.CreatedDate, al.UpdatedDate
FROM [audit].[LastNote] al 	
INNER JOIN client.Contract mainContract ON mainContract.Id=al.ContractId 
LEFT OUTER JOIN client.ContractApplicant mainContractApplicant ON mainContract.Id = mainContractApplicant.ContractId
LEFT OUTER JOIN company.ConfiguredStatus AS ConfiguredStatus ON mainContract.StatusId = ConfiguredStatus.Id
WHERE mainContract.CompanyId=278
AND mainContractApplicant.IsActive=1
AND mainContractApplicant.IsPrimary=1
AND ConfiguredStatus.IsContractSigned=0
AND mainContract.CreatedDate > @migration_date
-- and mainContract.FriendlyId in (130417,130763, 131081, 131879, 132691, 119346, 122066, 113029, 129175, 123937, 130145)