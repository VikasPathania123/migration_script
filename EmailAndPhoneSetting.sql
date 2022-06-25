SELECT 'ERG' AS Company, ei.Setting, sps.FriendlyName, sps.Phone, sps.IsDefault
FROM company.EmailIntegration ei 
    INNER JOIN company.SenderPhoneSetting sps ON ei.Id = sps.EmailIntegrationId
WHERE ei.CompanyId IN (278)
ORDER BY Company, sps.IsDefault DESC