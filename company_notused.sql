SELECT c.Id,
  CONCAT('"', c.name ,'"') 'legalname',
  CONCAT('"', c.name,'"') 'displayName',
  c.Code,
  c.CompanyStatusId'status',
  c.CreatedDate,
  c.UpdatedDate,
  'Subscriber' AS type ,NULL as 'Subscriber',
  Null AS 'Address' -- subscriber address is not present in the debtonator side.
FROM company.Company AS c 
WHERE Id = 278
   
UNION ALL

 SELECT affiliateCompany.Id,
  CONCAT('"',  affiliateCompany.Name ,'"') 'legalname',
   CONCAT('"', affiliateCompany.Name ,'"') 'displayName',
   affiliateCompany.Code,
   affiliateCompany.CompanyStatusId'status',
   affiliateCompany.CreatedDate,
   affiliateCompany.UpdatedDate,
   'Afilate' ,affiliate.ParentCompanyId as 'Subscriber',
 CONCAT('"',  affiliate.Address,'"')  'Address'
FROM [company].Affiliate affiliate 
        INNER JOIN [company].[Company] affiliateCompany ON affiliateCompany.Id = affiliate.CompanyId       
WHERE affiliate.ParentCompanyId = 278 
	AND affiliate.IsActive = 1
    
UNION ALL

 SELECT attorneyCompany.Id,
   CONCAT('"',attorneyCompany.Name,'"') 'legalname',
   CONCAT('"',attorneyCompany.Name ,'"') 'displayname',
  attorneyCompany.Code,
  attorneyCompany.CompanyStatusId'status',
  attorneyCompany.CreatedDate,
  attorneyCompany.UpdatedDate,
  'Attorney',attorney.ParentCompanyId as 'Subscriber',
 CONCAT('"', attorney.address,'"')  'Address'
  FROM [company].Attorney attorney 
      INNER JOIN [company].[Company] attorneyCompany ON attorneyCompany.Id = attorney.CompanyId       
WHERE attorney.ParentCompanyId = 278
	AND attorney.IsActive = 1;