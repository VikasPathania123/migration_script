
--<Migration -1 Month>
DECLARE @migration_date DATE = '' --yyyy-mm-dd is date format

--  e.g @migration_date DATE = '2021-04-21' this is the example

EXEC [secure].[OpenKey]
SELECT 
mainContract.Id as Id, 
CASE WHEN ConfiguredStatus.IsContractSigned = 0 THEN mainContract.FriendlyId ELSE NULL END AS LeadId,
   CASE WHEN ConfiguredStatus.IsContractSigned = 1 THEN mainContract.FriendlyId ELSE NULL END AS ClientId,
 (ISNULL(mainContractPaymentIntegration.IntegrationReference , '')) AS externalId,
 (ISNULL(mainContract.CompanyId ,''))AS companyHolder,
 ISNULL((SELECT mainTitle.Name FROM client.Name AS mainName1 JOIN dbo.Title AS mainTitle ON mainTitle.Id=mainName1.TitleId WHERE mainDetail.Id=mainName1.ClientId),'')AS Title,
 (SELECT ISNULL(mainName2.FirstName,'') FROM client.Name AS mainName2 WHERE mainDetail.Id=mainName2.ClientId) AS firstName,
 (SELECT ISNULL(mainName3.MiddleName,'') FROM client.Name AS mainName3 WHERE mainDetail.Id=mainName3.ClientId) AS middleName,
 (SELECT ISNULL(mainName4.LastName,'') FROM client.Name AS mainName4 WHERE mainDetail.Id=mainName4.ClientId) AS LastName,
 (ISNULL(concat((SELECT ISNULL(mainTitle.Name,'') FROM client.Name AS mainName1 JOIN dbo.Title AS mainTitle ON mainTitle.Id=mainName1.TitleId WHERE mainDetail.Id=mainName1.ClientId), ' ', (SELECT ISNULL(mainName3.MiddleName,'') FROM client.Name AS mainName3 WHERE mainDetail.Id=mainName3.ClientId) ,' ',(SELECT ISNULL(mainName4.LastName,'') FROM client.Name AS mainName4 WHERE mainDetail.Id=mainName4.ClientId)),''))mfullName,
 (SELECT ISNULL(mainName5.Suffix,'') FROM client.Name AS mainName5 WHERE mainDetail.Id=mainName5.ClientId ) AS Suffix,
 ISNULL((SELECT mainGender.Name FROM dbo.Gender AS mainGender WHERE mainGender.ID=mainDetail.GenderId), '') AS Gender,
 (ISNULL(mainDetail.MotherMaidenName , ''))as maidenName,
 --(ISNULL(FORMAT(cast( [secure].[Decrypt](mainDetail.SSN)as numeric), '###-##-####'),'')) AS SSN ,
  (ISNULL([secure].[Decrypt](mainDetail.SSN),'')) AS SSN ,
 (ISNULL(CONVERT(nvarchar,mainDetail.BirthDate,101) ,''))AS dob,
 ISNULL((SELECT mainEMAIL.Email FROM client.Email AS mainEMAIL WHERE mainEMAIL.ClientId=mainDetail.Id ),'') AS Email,
 ISNULL((SELECT mainCOMNphone1.Number FROM client.ClientPhone AS mainPhone1 JOIN dbo.PhoneType AS mainPhoneType ON mainPhoneType.Id=mainPhone1.PhoneTypeId JOIN comn.Phone AS mainCOMNphone1 ON mainCOMNphone1.Id=mainPhone1.PhoneId WHERE mainPhone1.ClientId=mainDetail.Id AND mainPhone1.PhoneTypeId = 1),'')AS primaryMobileNumber,
 ISNULL((SELECT mainCOMNphone2.Number FROM client.ClientPhone AS mainPhone2 JOIN dbo.PhoneType AS mainPhoneType ON mainPhoneType.Id=mainPhone2.PhoneTypeId JOIN comn.Phone AS mainCOMNphone2 ON mainCOMNphone2.Id=mainPhone2.PhoneId WHERE mainPhone2.ClientId=mainDetail.Id AND mainPhone2.PhoneTypeId = 2),'') AS workPhone,
 ISNULL((SELECT mainCOMNphone3.Number FROM client.ClientPhone AS mainPhone3 JOIN dbo.PhoneType AS mainPhoneType ON mainPhoneType.Id=mainPhone3.PhoneTypeId JOIN comn.Phone AS mainCOMNphone3 ON mainCOMNphone3.Id=mainPhone3.PhoneId WHERE mainPhone3.ClientId=mainDetail.Id AND mainPhone3.PhoneTypeId = 3),'') AS homePhoneNumber,
 ISNULL((SELECT mainCOMNphone4.Number FROM client.ClientPhone AS mainPhone4 JOIN dbo.PhoneType AS mainPhoneType ON mainPhoneType.Id=mainPhone4.PhoneTypeId JOIN comn.Phone AS mainCOMNphone4 ON mainCOMNphone4.Id=mainPhone4.PhoneId WHERE mainPhone4.ClientId=mainDetail.Id AND mainPhone4.PhoneTypeId = 4),'') AS FaxNumber,
 (ISNULL(mainDetail.OptedInToSMS,''))AS smsCommunicationMode,
 (ISNULL(mainDetail.OptedInToEmail,''))AS emailCommunicationMode,
  CONCAT('"',(ISNULL (tmpCOMNPermanentAddress.dAddress1 ,'') ) ,'"') AS permanentAddress1,
  CONCAT('"',(ISNULL(tmpCOMNPermanentAddress.dAddress2  ,'')) ,'"') AS permanentAddress2,
 (ISNULL(tmpCOMNPermanentAddress.dmainCity ,'')) AS city,
 (ISNULL(tmpCOMNPermanentAddress.dmainState ,'')) AS state,
 (ISNULL(tmpCOMNPermanentAddress.dZipCode ,'')) AS zipcode,
  CONCAT('"',(ISNULL(tmpCOMNMailingAddress.dAddress1 ,'')),'"') AS mailinAadress1,
  CONCAT('"',(ISNULL(tmpCOMNMailingAddress.dAddress2  ,'')),'"') AS mailingAdress2,
 (ISNULL(tmpCOMNMailingAddress.dmainCity  ,''))AS mailingcity,
 (ISNULL(tmpCOMNMailingAddress.dmainState ,'') )AS mailingstate,
 (ISNULL(tmpCOMNMailingAddress.dZipCode  ,''))AS mailingzipcode,
 (ISNULL(CASE WHEN mainContractApplicant.IsPrimary = 0 THEN mainDetail.Id   END,'')) AS coApplicant,
 (ISNULL(CASE WHEN mainContract.AffiliateSourceId =1 THEN 'CALL'
               WHEN mainContract.AffiliateSourceId =2 THEN 'TV'
               WHEN mainContract.AffiliateSourceId =3 THEN 'RADIO'
               WHEN mainContract.AffiliateSourceId =4 THEN 'AFFILATE'
               WHEN mainContract.AffiliateSourceId =5 THEN 'LGP'
               ELSE 'CALL' END,'')) AS source,
 (ISNULL(mainContract.AffiliateId,'')) AS affiliate,
 ISNULL((SELECT mainContractAssignment1.UserId FROM client.ContractAssignment AS mainContractAssignment1 WHERE mainContractAssignment1.RoleTypeId = 1 AND mainContractAssignment1.StatusId IN (1,2) AND mainContract.id=mainContractAssignment1.ContractId),'') AS affilateAgent,
 ISNULL((SELECT mainContractAssignment2.UserId FROM client.ContractAssignment AS mainContractAssignment2 WHERE mainContractAssignment2.RoleTypeId = 1 AND mainContractAssignment2.StatusId IN (1,2) AND mainContract.id=mainContractAssignment2.ContractId),'') AS SalesAgent,
 ISNULL((SELECT mainContractAssignment3.UserId FROM client.ContractAssignment AS mainContractAssignment3 WHERE mainContractAssignment3.RoleTypeId = 3 AND mainContractAssignment3.StatusId IN (1,2) AND mainContract.id=mainContractAssignment3.ContractId),'') AS negotiationsAgent,
 (SELECT ISNULL(mainConfiguredStatus.Name,'') FROM company.ConfiguredStatus AS mainConfiguredStatus WHERE mainConfiguredStatus.Id=mainContract.StatusId ) AS stage,
 (ISNULL(mainContract.StatusId,'') )AS status,
 --(ISNULL(mainTag.Value,'')) AS tags,
 (ISNULL(mainDetail.LanguageId,''))AS prefferedLanguage,
 (ISNULL(mainCompanyPaymentIntegration.IntegrationFriendlyName,'')) AS paymentProcessor,
 (SELECT ISNULL(SUM(tmpLoanamount.Amount),'') FROM loan.loan AS tmpLoan JOIN  loan.LoanAmount AS tmpLoanamount ON tmpLoan.Id=tmpLoanamount.LoanId WHERE tmpLoanamount.IsEnrolledValue = 1 AND tmpLoan.ContractId=mainContract.Id)AS estimatedDebt,
 (SELECT mainTimezone.Abbreviation FROM  dbo.TimeZone AS mainTimezone WHERE mainTimezone.id=tmpCOMNPermanentAddress.dTimeZoneId) AS timezone,
 (ISNULL(CONVERT(nvarchar,mainContract.LastContactDate,101),''))AS lastContactedOn,
 (ISNULL(mainContractPaymentIntegration.RateCardVersion,'') )AS rateCard,
 (ISNULL(mainContractPaymentIntegration.IntegrationReference,'')) AS specialPurposeAccount,
 ISNULL(CASE WHEN mainContractPaymentIntegration.IntegrationReference IS NULL THEN 'NO' ELSE 'YES' END, '') AS SyncStatus,
mainContract.CreatedDate, mainContract.UpdatedDate


FROM client.Contract AS mainContract
  LEFT OUTER JOIN client.ContractApplicant mainContractApplicant ON mainContract.Id = mainContractApplicant.ContractId
  LEFT OUTER JOIN client.Detail AS mainDetail ON mainDetail.Id=mainContractApplicant.ClientId
  --LEFT OUTER JOIN client.ContractTag mainContractTag ON mainContract.Id = mainContractTag.ContractId
  --LEFT OUTER JOIN dbo.Tag mainTag ON mainTag.Id=mainContractTag.TagId
  LEFT OUTER JOIN company.ConfiguredStatus AS ConfiguredStatus ON mainContract.StatusId = ConfiguredStatus.Id
  LEFT OUTER JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration ON mainContractPaymentIntegration.ContractId=mainContract.Id
  LEFT OUTER JOIN company.PaymentIntegration AS mainCompanyPaymentIntegration ON mainCompanyPaymentIntegration.id=mainContractPaymentIntegration.CompanyPaymentIntegrationId
            LEFT JOIN (SELECT 
             distinct mainAddress.AddressId dComA ,
                      mainAddress.ClientId dCid,
                      mainZip.Code dZipCode,
                      mainAdderssType.Id dmainAdderssType,
                      mainState.Name dmainState,
                      mainCity.Name dmainCity,
                      mainCOMNaddress.Address1 dAddress1,
                      mainCOMNaddress.Address2 dAddress2,
                      mainZip.TimeZoneId dTimeZoneId

                       FROM  client.ClientAddress AS mainAddress 
                       JOIN dbo.AddressType AS mainAdderssType ON mainAdderssType.Id=mainAddress.AddressTypeId
                       JOIN comn.Address AS  mainCOMNaddress ON mainCOMNaddress.Id=mainAddress.AddressId 
                       JOIN dbo.ZipCode AS mainZip ON mainCOMNaddress.ZipCodeId=mainZip.Id
                       JOIN dbo.City AS mainCity ON mainZip.CityId = mainCity.Id
                       JOIN  dbo.State as mainState ON mainState.Id =mainCity.StateId
					   where mainAddress.AddressTypeId=1
             )tmpCOMNPermanentAddress ON tmpCOMNPermanentAddress.dCid=mainDetail.id
			 LEFT JOIN (SELECT 
             distinct mainAddress.AddressId dComA ,
                      mainAddress.ClientId dCid,
                      mainZip.Code dZipCode,
                      mainAdderssType.Id dmainAdderssType,
                      mainState.Name dmainState,
                      mainCity.Name dmainCity,
                      mainCOMNaddress.Address1 dAddress1,
                      mainCOMNaddress.Address2 dAddress2,
                      mainZip.TimeZoneId dTimeZoneId

                       FROM  client.ClientAddress AS mainAddress 
                       JOIN dbo.AddressType AS mainAdderssType ON mainAdderssType.Id=mainAddress.AddressTypeId
                       JOIN comn.Address AS  mainCOMNaddress ON mainCOMNaddress.Id=mainAddress.AddressId 
                       JOIN dbo.ZipCode AS mainZip ON mainCOMNaddress.ZipCodeId=mainZip.Id
                       JOIN dbo.City AS mainCity ON mainZip.CityId = mainCity.Id
                       JOIN  dbo.State as mainState ON mainState.Id =mainCity.StateId
					   where mainAddress.AddressTypeId=2
             )tmpCOMNMailingAddress ON tmpCOMNMailingAddress.dCid=mainDetail.id

WHERE mainContract.CompanyId=278
    AND mainContractApplicant.IsActive=1
	AND mainContractApplicant.IsPrimary=0
    AND ((ConfiguredStatus.IsContractSigned = 1 AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
			AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10) 
		OR (ConfiguredStatus.IsContractSigned = 0 AND mainContract.CreatedDate > @migration_date ))  
	
    -- and mainContract.FriendlyId in (113393, 115340, 124024, 124306, 126663, 127662, 129185, 129372, 130551, 126334)