select tag.id as 'Id', QUOTENAME(tag.Value,'"') as name from 
company.ConfiguredAccountTag companyTag
JOIN dbo.Tag tag on tag.id = companyTag.TagId
where companyTag.CompanyId=278;
