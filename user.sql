declare @companyReference NVARCHAR(100);

SELECT  @companyReference = Reference FROM company.Company WHERE Id = 278;

SELECT 
    u.Id, 
    u.Name,
    Ltrim(SubString(u.Name,1,Isnull(Nullif(CHARINDEX(' ',u.Name),0),1000))) As FirstName,
    Ltrim(SUBSTRING(u.Name,CharIndex(' ',u.Name),CAse When (CHARINDEX(' ',u.Name,CHARINDEX(' ',u.Name)+1)-CHARINDEX(' ',u.Name))<=0 then 0 else CHARINDEX(' ',u.Name,CHARINDEX(' ',u.Name)+1)-CHARINDEX(' ',u.Name) end )) as MiddleName,
    Ltrim(SUBSTRING(u.Name,Isnull(Nullif(CHARINDEX(' ',u.Name,Charindex(' ',u.Name)+1),0),CHARINDEX(' ',u.Name)),Case when Charindex(' ',u.Name)=0 then 0 else LEN(u.Name) end)) as LastName,
    u.Email, 
    u.PasswordHash, 
    u.SecurityStamp, 
    u.CreatedDate, 
    u.UpdatedDate, 
    Company.Id AS Subscriber,   
    r.Name AS RoleName,
    CompanyAccess.IsActive, 
    negotiatorProfile.Phone, 
    negotiatorProfile.PhoneExtension,
	negotiatorProfile.JobTitle,
    r.Id AS RoleId,
    (CASE WHEN [company].CompanyAccess.IsActive = 1 THEN 'True' else 'False'   END) AS CompanyAccessIsActive 
FROM [identity].[Users] AS u
    INNER JOIN [identity].[UserRoles] ON u.Id = [identity].[UserRoles].UserId
	INNER JOIN [identity].Roles AS r ON [identity].[UserRoles].RoleId = r.Id
    INNER JOIN [company].[CompanyAccess] ON u.Id = [company].[CompanyAccess].UserId
    INNER JOIN [company].[Company] ON [company].[CompanyAccess].CompanyId = [company].[Company].Id
    LEFT OUTER JOIN [identity].Profile negotiatorProfile ON negotiatorProfile.UserId = u.Id
WHERE [company].[Company].Id = 278;    