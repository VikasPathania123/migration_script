    SELECT a.Id, a.[Name], a.Email, CONCAT('"', a.[Address], '"') as [Address], a.Phone, a.Fax, s.Code AS [State],a.CreatedDate
    FROM [company].[Attorney] AS a 
	    INNER JOIN company.StateToAttorneyMapping AS am ON a.Id = am.AttorneyId AND am.IsActive = 1
        INNER JOIN dbo.[State] AS s ON am.StateId = s.Id
    WHERE a.ParentCompanyId = 278 AND a.IsActive = 1