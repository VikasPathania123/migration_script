select lender.Id as ID,
      QUOTENAME(cli.ExternalId,'"') as externalId,
      CONCAT('"', lender.Name,'"') as name,
      QUOTENAME(debtType.Name,'"') as type,
      alias.Alias as alias,
      CONCAT('"', address.Address1,'"') address1,
      CONCAT('"', address.Address2,'"') address2,
      QUOTENAME(address.City,'"') as city,     
      QUOTENAME(address.Zip,'"') as zip,
      state.Name as state,
      email.Email as emailAddress,
      --(ISNULL(FORMAT(cast(phone.Number as numeric), '###-###-####'),'')) AS phoneNumber ,
      --(ISNULL(FORMAT(cast(fax.Number as numeric), '###-###-####'),'')) AS faxNumber ,
      fax.Number AS faxNumber ,
      phone.Number AS phoneNumber,
      CONCAT('"', contact.Name ,'"')as contactName,
      (case when lender.IsActive =1 then 'Active' when lender.IsActive=0 then 'Inactive' end) as status,
      (case when preference.VOD_SendEmail =1 then 'Email' 
       when preference.VOD_SendFax =1 then 'Fax' 
       when preference.VOD_SendPhysical =1 then 'Physical' 
      end) as communicationPreference,
      (case when cli.ExternalId is null then 'No'
      when cli.ExternalId is not null then 'Yes' end) as syncStatus,
      lender.CreatedDate, lender.UpdatedDate,
      cpi.IntegrationFriendlyName AS paymentProcessor
from loan.Lender lender
INNER JOIN company.CompanyLender cl on cl.LenderId=lender.id 
	AND cl.CompanyId = 278
	AND cl.IsActive = 1
LEFT JOIN company.CompanyLenderIntegration cli ON cli.CompanyLenderId = cl.Id 
LEFT JOIN [company].[PaymentIntegration] AS cpi ON cli.PaymentIntegrationId = cpi.Id
LEFT JOIN dbo.DebtType debtType ON debtType.Id = lender.DebtTypeId
LEFT JOIN company.CompanyLenderAlias alias ON alias.CompanyLenderId = lender.Id
LEFT JOIN loan.LenderAddress address ON address.LenderId = lender.Id
LEFT JOIN dbo.State state on state.Id = address.StateId
LEFT JOIN loan.LenderEmail as email ON email.LenderId = lender.id
LEFT JOIN loan.LenderPhone as phone on phone.LenderId = lender.id 
	AND phone.PhoneTypeId = 2
LEFT JOIN loan.LenderPhone as fax on fax.LenderId = lender.id 
	AND fax.PhoneTypeId = 4
LeFT JOIN loan.LenderContact as contact on contact.LenderId = lender.Id
LEFT JOIN loan.LenderContactPreferences preference ON preference.LenderId=lender.Id;