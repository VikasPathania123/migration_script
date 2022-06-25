SELECT lc.Id, lc.LenderId AS CreditorId, QUOTENAME(lc.Name,'"') Name, lc.Title, 
       cl.CompanyId, CONCAT('"', la.Address1,'"') Address1, CONCAT('"', la.Address2,'"') Address2,
       la.City, state.Name as state, la.Zip	,l.CreatedDate, l.UpdatedDate
FROM  [loan].[LenderContact] AS lc
	INNER JOIN  [loan].[Lender] AS l ON lc.LenderId = l.Id 
	INNER JOIN  [company].[CompanyLender] AS cl ON l.Id = cl.LenderId AND cl.IsActive = 1
	LEFT JOIN  [loan].[LenderAddress] AS la ON la.LenderId = l.Id
    LEFT JOIN dbo.State state on state.Id = la.StateId
WHERE cl.CompanyId = 278
