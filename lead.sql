
--<Migration -1 Month>
DECLARE @migration_date DATE = '' --yyyy-mm-dd is date format

--  e.g @migration_date DATE = '2021-04-21' this is the example

EXEC [secure].[OpenKey]
Select
    MainQuery.id,
    max(externalId) AS externalId,
    max(companyHolder) AS companyHolder,
    max(Title) AS Title,
    max(firstName) AS firstName,
    max(middleName) AS middleName,
    max(LastName) AS LastName,
    max(mfullName) AS mfullName,
    max(Suffix) AS Suffix,
    max(Gender) AS Gender,
    max(maidenName) AS maidenName,
    max(SSN ) AS SSN,
    max(dob) AS dob,
    max(Email) AS Email,
    max(primaryMobileNumber) AS primaryMobileNumber,
    max(workPhone) AS workPhone,
    max(homePhoneNumber) AS homePhoneNumber,
    max(FaxNumber) AS FaxNumber,
    max(smsCommunicationMode) AS smsCommunicationMode,
    max(emailCommunicationMode) AS emailCommunicationMode,
    CONCAT('"', max(permanentAddress1),'"') AS permanentAddress1,
    CONCAT('"', max(permanentAddress2) ,'"')AS permanentAddress2,
    max(city1) AS city1,
    max(state1) AS state1,
    max(zipcode1) AS zipcode1,
    CONCAT('"', max(mailinAadress1) ,'"') AS mailinAadress1,
    CONCAT('"', max(mailingAdress2),'"') AS mailingAdress2,
    max(city2) AS city2,
    max(state2) AS state2,
    max(zipcode2) AS zipcode2,
    max(coApplicant) AS coApplicant,
    max(affiliate) AS affiliate,
    max(affilateAgent) AS affilateAgent,
	MAX(CASE WHEN affilateAgentIsSystemUser=1 THEN 1 ELSE 0 END) AS affilateAgentIsSystemUser,
    max(SalesAgent) AS SalesAgent,
	MAX(CASE WHEN SalesAgentIsSystemUser=1 THEN 1 ELSE 0 END) AS SalesAgentIsSystemUser,
    max(negotiationsAgent) AS negotiationsAgent,
	MAX(CASE WHEN negotiationsAgentIsSystemUser=1 THEN 1 ELSE 0 END) AS negotiationsAgentIsSystemUser,
    max(pdiLeadStage) AS pdiLeadStage,
    max(status) AS status,
    max(lastContactedOn) AS lastContactedOn,
    max(prefferedLanguage) AS prefferedLanguage,
    max(isEmployed) AS isEmployed,
    max(paymentProcessor) AS paymentProcessor,
    max(employmentType) AS employmentType,
    max(totalEnrolledDebt) AS totalEnrolledDebt,
    max(timezone) AS timezone,
    max(CFTId) AS CFTId,
    --max(paymentProcessor2) AS paymentProcessor2,
    max(creditScore) AS creditScore,
    max(client) AS client,
    max(enrollmentContractStatus) AS enrollmentContractStatus,
    max(reference) as reference,
    MAX(lastContactedBy) AS lastContactedBy,
    MAX(enrollmentDate) AS enrollmentDate,
    MAX(mailingCampaign) AS mailingCampaign,
    MAX(CurrentAssigment)AS CurrentAssigment,
    max(createdOn) as createdOn,
    max(updatedOn) as updatedOn
 FROM 
(
SELECT 
mainContract.FriendlyId id,
 (ISNULL(mainContractPaymentIntegration.IntegrationReference , '')) AS externalId,
 (ISNULL(mainContract.CompanyId ,''))AS companyHolder,
 ISNULL((SELECT mainTitle.Name FROM client.Name AS mainName1 JOIN dbo.Title AS mainTitle ON mainTitle.Id=mainName1.TitleId WHERE mainDetail.Id=mainName1.ClientId),'')AS Title,
 (SELECT ISNULL(mainName2.FirstName,'') FROM client.Name AS mainName2 WHERE mainDetail.Id=mainName2.ClientId) AS firstName,
 (SELECT ISNULL(mainName3.MiddleName,'') FROM client.Name AS mainName3 WHERE mainDetail.Id=mainName3.ClientId) AS middleName,
 (SELECT ISNULL(mainName4.LastName,'') FROM client.Name AS mainName4 WHERE mainDetail.Id=mainName4.ClientId) AS LastName,
 (ISNULL(concat((SELECT ISNULL(mainTitle.Name,'') FROM client.Name AS mainName1 JOIN dbo.Title AS mainTitle ON mainTitle.Id=mainName1.TitleId WHERE mainDetail.Id=mainName1.ClientId), ' ',(SELECT ISNULL(mainName3.FirstName,'') FROM client.Name AS mainName3 WHERE mainDetail.Id=mainName3.ClientId) ,' ', (SELECT ISNULL(mainName3.MiddleName,'') FROM client.Name AS mainName3 WHERE mainDetail.Id=mainName3.ClientId) ,' ',(SELECT ISNULL(mainName4.LastName,'') FROM client.Name AS mainName4 WHERE mainDetail.Id=mainName4.ClientId)),''))mfullName,
 (SELECT ISNULL(mainName5.Suffix,'') FROM client.Name AS mainName5 WHERE mainDetail.Id=mainName5.ClientId ) AS Suffix,
 ISNULL((SELECT mainGender.Name FROM dbo.Gender AS mainGender WHERE mainGender.ID=mainDetail.GenderId), '') AS Gender,
 (ISNULL(mainDetail.MotherMaidenName , ''))as maidenName,
 --(ISNULL(FORMAT(cast( [secure].[Decrypt](mainDetail.SSN)as numeric), '###-##-####'),'')) AS SSN ,
  (ISNULL([secure].[Decrypt](mainDetail.SSN),'')) AS SSN ,
 (ISNULL(CONVERT(nvarchar,mainDetail.BirthDate,101) ,''))AS dob,
 (SELECT ISNULL(mainEMAIL.Email,'') FROM client.Email AS mainEMAIL WHERE mainEMAIL.ClientId=mainDetail.Id ) AS Email,
(SELECT mainCOMNphone1.Number FROM client.ClientPhone AS mainPhone1 JOIN dbo.PhoneType AS mainPhoneType ON mainPhoneType.Id=mainPhone1.PhoneTypeId JOIN comn.Phone AS mainCOMNphone1 ON mainCOMNphone1.Id=mainPhone1.PhoneId WHERE mainPhone1.ClientId=mainDetail.Id AND mainPhone1.PhoneTypeId = 1) AS primaryMobileNumber,
(SELECT mainCOMNphone2.Number FROM client.ClientPhone AS mainPhone2 JOIN dbo.PhoneType AS mainPhoneType ON mainPhoneType.Id=mainPhone2.PhoneTypeId JOIN comn.Phone AS mainCOMNphone2 ON mainCOMNphone2.Id=mainPhone2.PhoneId WHERE mainPhone2.ClientId=mainDetail.Id AND mainPhone2.PhoneTypeId = 2) AS workPhone,
(SELECT mainCOMNphone3.Number FROM client.ClientPhone AS mainPhone3 JOIN dbo.PhoneType AS mainPhoneType ON mainPhoneType.Id=mainPhone3.PhoneTypeId JOIN comn.Phone AS mainCOMNphone3 ON mainCOMNphone3.Id=mainPhone3.PhoneId WHERE mainPhone3.ClientId=mainDetail.Id AND mainPhone3.PhoneTypeId = 3) AS homePhoneNumber,
(SELECT mainCOMNphone4.Number FROM client.ClientPhone AS mainPhone4 JOIN dbo.PhoneType AS mainPhoneType ON mainPhoneType.Id=mainPhone4.PhoneTypeId JOIN comn.Phone AS mainCOMNphone4 ON mainCOMNphone4.Id=mainPhone4.PhoneId WHERE mainPhone4.ClientId=mainDetail.Id AND mainPhone4.PhoneTypeId = 4) AS FaxNumber,
(ISNULL(mainDetail.OptedInToSMS,''))AS smsCommunicationMode,
 (ISNULL(mainDetail.OptedInToEmail,''))AS emailCommunicationMode,
 (ISNULL(REPLACE((CASE WHEN tmpCOMNAddress.dmainAdderssType = 1 THEN tmpCOMNAddress.dAddress1 END),',',''),'') )AS permanentAddress1,
 (ISNULL(CASE WHEN tmpCOMNAddress.dmainAdderssType = 1 THEN  tmpCOMNAddress.dAddress2 END ,''))AS permanentAddress2,
 (ISNULL(CASE WHEN tmpCOMNAddress.dmainAdderssType = 1 THEN tmpCOMNAddress.dmainCity END,'')) AS city1,
 (ISNULL(CASE WHEN tmpCOMNAddress.dmainAdderssType = 1 THEN tmpCOMNAddress.dmainState END,'')) AS state1,
 (ISNULL(CASE WHEN tmpCOMNAddress.dmainAdderssType = 1 THEN tmpCOMNAddress.dZipCode END,'')) AS zipcode1,
 (ISNULL(CASE WHEN tmpCOMNAddress.dmainAdderssType = 2 THEN tmpCOMNAddress.dAddress1 END,'')) AS mailinAadress1,
 (ISNULL(CASE WHEN tmpCOMNAddress.dmainAdderssType = 2 THEN tmpCOMNAddress.dAddress2 END ,''))AS mailingAdress2,
 (ISNULL(CASE WHEN tmpCOMNAddress.dmainAdderssType = 2 THEN tmpCOMNAddress.dmainCity END ,''))AS city2,
 (ISNULL(CASE WHEN tmpCOMNAddress.dmainAdderssType = 2 THEN tmpCOMNAddress.dmainState END,'') )AS state2,
 (ISNULL(CASE WHEN tmpCOMNAddress.dmainAdderssType = 2 THEN tmpCOMNAddress.dZipCode END ,''))AS zipcode2,
 (ISNULL(CASE WHEN mainContractApplicant.IsPrimary = 0 THEN mainDetail.Id   END,'')) AS coApplicant,
 (ISNULL(CASE WHEN mainContract.AffiliateSourceId =1 THEN 'CALL'
               WHEN mainContract.AffiliateSourceId =2 THEN 'TV'
               WHEN mainContract.AffiliateSourceId =3 THEN 'RADIO'
               WHEN mainContract.AffiliateSourceId =4 THEN 'AFFILATE'
               WHEN mainContract.AffiliateSourceId =5 THEN 'LGP'
               ELSE 'CALL' END,'')) AS source,
 (ISNULL(mainContract.AffiliateId,'')) AS affiliate,
 ISNULL(affilateAgent.UserId,'') AS affilateAgent,
 ISNULL(affilateAgentUser.IsSystemUser,'') AS affilateAgentIsSystemUser,
 ISNULL(SalesAgent.UserId,'') AS SalesAgent,
 ISNULL(SalesAgentUser.IsSystemUser,'') AS SalesAgentIsSystemUser,
 ISNULL(negotiationsAgent.UserId,'') AS negotiationsAgent,
 ISNULL(negotiationsAgentUser.IsSystemUser,'') AS negotiationsAgentIsSystemUser,
 (ISNULL(ConfiguredStatus.Name, '')) AS pdiLeadStage,
 (ISNULL(mainContract.StatusId,'') )AS status,
  (ISNULL(CONVERT(nvarchar,mainContract.LastContactDate,101),''))AS lastContactedOn,
 (ISNULL(language.Name,''))AS prefferedLanguage,
 (select CASE WHEN tbudgetEmployer.Employer != null THEN 'YES' else 'NO'   END FROM budget.Employer AS tbudgetEmployer WHERE tbudgetEmployer.ContractId = mainContract.Id  ) AS isEmployed,
 (ISNULL(mainCompanyPaymentIntegration.IntegrationFriendlyName,'')) AS paymentProcessor,
 ISNULL((SELECT CASE WHEN budgetEmployer.EmployeeTypeId=1 THEN 'Employee' WHEN budgetEmployer.EmployeeTypeId=2 THEN 'Self-Employed' WHEN budgetEmployer.EmployeeTypeId=3 THEN 'Exempt'  END FROM budget.Employer AS budgetEmployer WHERE budgetEmployer.ContractId = mainContract.Id),'') AS employmentType,
 (SELECT ISNULL(SUM(tmpLoanamount.Amount),'') FROM loan.loan AS tmpLoan JOIN  loan.LoanAmount AS tmpLoanamount ON tmpLoan.Id=tmpLoanamount.LoanId WHERE tmpLoanamount.IsEnrolledValue = 1 AND tmpLoan.ContractId=mainContract.Id)AS totalEnrolledDebt,
 (SELECT mainTimezone.Abbreviation FROM  dbo.TimeZone AS mainTimezone WHERE mainTimezone.id=tmpCOMNAddress.dTimeZoneId) AS timezone,
 (ISNULL(mainContractPaymentIntegration.IntegrationReference , '')) AS CFTId,
 --(ISNULL(mainCompanyPaymentIntegration.IntegrationFriendlyName,'')) AS paymentProcessor,
 (ISNULL(client.ApplicantCreditScore.ScoreValue , ' ')) AS creditScore,
 (SELECT ISNULL(tmpc.FriendlyId,'') FROM client.Contract AS tmpc JOIN company.ConfiguredStatus AS s ON tmpc.StatusId = s.Id WHERE s.IsContractSigned = 1 AND mainContract.Id=tmpc.Id ) AS client,
 	 (SELECT TOP 1 srs.Name AS [Status] FROM client.ContractSignatureRequest AS csr
	INNER JOIN [dbo].[SignatureRequestStatus] AS srs ON csr.RequestStatusId = srs.Id 
	INNER JOIN [company].[DocumentPackage] AS dp ON dp.[Id] = csr.PackageId
	INNER JOIN [dbo].[DocumentPackageType] AS dpt ON dpt.Id = dp.TypeId AND dp.TypeId = 1
	WHERE csr.ContractId =mainContract.id ORDER BY csr.UpdatedDate) AS enrollmentContractStatus,
 mainContract.Reference as reference,
 ln.UserId AS lastContactedBy,
 e.TimeStamp AS enrollmentDate,
 st.CampaignName AS mailingCampaign,
 ISNULL(CASE 
		WHEN ConfiguredStatus.IsContractSigned = 0 
			THEN (SELECT TOP 1 UserId FROM client.ContractAssignment ca 
					WHERE ca.RoleTypeId = 1 AND ca.ContractId = mainContract.Id
						ORDER BY ca.CreatedDate DESC) 
		WHEN ConfiguredStatus.IsContractSigned = 1 AND 
					EXISTS(SELECT  1 FROM loan.loan l
								INNER JOIN loan.LoanSettlement AS ls ON l.Id = ls.LoanId AND ls.SettlementStatusId IN (6,9) 
							WHERE mainContract.Id = l.ContractId)
			THEN (SELECT TOP 1 UserId FROM client.ContractAssignment ca 
					WHERE ca.RoleTypeId = 3 AND ca.ContractId = mainContract.Id 
						ORDER BY ca.CreatedDate DESC)
		WHEN ConfiguredStatus.IsContractSigned = 1 
			THEN (SELECT TOP 1 UserId FROM client.ContractAssignment ca 
					WHERE ca.RoleTypeId = 2 AND ca.ContractId = mainContract.Id 
						ORDER BY ca.CreatedDate DESC)		
			ELSE NULL END,'')  AS CurrentAssigment,
 mainContract.CreatedDate as createdOn,
 mainContract.UpdatedDate as updatedOn
FROM 
client.Contract AS mainContract
--FULL OUTER JOIN client.ContractAssignment ON mainContract.Id = client.ContractAssignment.ContractId 
FULL OUTER JOIN client.ContractApplicant mainContractApplicant ON mainContract.Id = mainContractApplicant.ContractId 
FULL OUTER JOIN client.Detail AS mainDetail ON mainDetail.Id=mainContractApplicant.ClientId
LEFT JOIN  dbo.Language as language ON language.Id = mainDetail.LanguageId
FULL OUTER JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration ON mainContractPaymentIntegration.ContractId=mainContract.Id
FULL OUTER JOIN company.PaymentIntegration AS mainCompanyPaymentIntegration ON mainCompanyPaymentIntegration.id=mainContractPaymentIntegration.CompanyPaymentIntegrationId
FULL OUTER JOIN company.ConfiguredStatus AS ConfiguredStatus ON mainContract.StatusId = ConfiguredStatus.Id 
FULL OUTER JOIN client.ApplicantCreditScore ON mainContractApplicant.Id = client.ApplicantCreditScore.ApplicantId
LEFT JOIN audit.LastNote AS ln ON mainContract.Id = ln.ContractId
LEFT JOIN client.Enrollment AS e ON mainContract.Id = e.ContractId
LEFT JOIN client.SourceTracking AS st ON mainContract.Id = st.ContractId
  LEFT JOIN client.ContractAssignment AS affilateAgent ON affilateAgent.RoleTypeId = 1 AND affilateAgent.StatusId IN (1,2) AND mainContract.id=affilateAgent.ContractId
  LEFT JOIN [identity].[Users] AS affilateAgentUser ON affilateAgent.UserId = affilateAgentUser.Id
  LEFT JOIN client.ContractAssignment AS SalesAgent ON SalesAgent.RoleTypeId = 1 AND SalesAgent.StatusId IN (1,2) AND mainContract.id=SalesAgent.ContractId
  LEFT JOIN [identity].[Users] AS SalesAgentUser ON SalesAgent.UserId = SalesAgentUser.Id
  LEFT JOIN client.ContractAssignment AS negotiationsAgent ON negotiationsAgent.RoleTypeId = 3 AND negotiationsAgent.StatusId IN (1,2) AND mainContract.id=negotiationsAgent.ContractId
  LEFT JOIN [identity].[Users] AS negotiationsAgentUser ON negotiationsAgent.UserId = negotiationsAgentUser.Id
JOIN (SELECT 
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
             )tmpCOMNAddress ON tmpCOMNAddress.dCid=mainDetail.id

WHERE mainContract.CompanyId=278 
AND mainContractApplicant.IsPrimary=1
AND mainContractApplicant.IsActive=1
AND ((ConfiguredStatus.IsContractSigned = 1 AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
			AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10) 
	OR (ConfiguredStatus.IsContractSigned = 0 AND mainContract.CreatedDate > @migration_date ))
-- and mainContract.FriendlyId in (113393, 115340, 124024, 124306, 126663, 127662, 129185, 129372, 130551, 126334)
) as mainQuery
group by id order by id 
