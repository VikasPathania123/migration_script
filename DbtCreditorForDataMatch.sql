select lender.Id as ID
      ,cli.ExternalId as externalId,
	  cpi.IntegrationFriendlyName as IntegrationName,
      CONCAT('"',lender.Name,'"') as name,
      CONCAT('"',address.Address1,'"') address1,
      CONCAT('"',address.Address2,'"') address2,
      CONCAT('"',address.City,'"') as city,
      state.Name as state,
	  CONCAT('"',address.Zip,'"') as zip
     
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
	AND phone.PhoneTypeId = 1
LEFT JOIN loan.LenderPhone as fax on fax.LenderId = lender.id 
	AND fax.PhoneTypeId = 4
LeFT JOIN loan.LenderContact as contact on contact.LenderId = lender.Id
LEFT JOIN loan.LenderContactPreferences preference ON preference.LenderId=lender.Id;