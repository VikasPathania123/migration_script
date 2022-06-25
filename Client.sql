EXEC [secure].[OpenKey]
IF OBJECT_ID('tempdb..#Drafts') IS NOT NULL DROP TABLE #Drafts;
IF OBJECT_ID('tempdb..#DebtSummary') IS NOT NULL DROP TABLE #DebtSummary;

 SELECT X.Id , 
        MAX(CASE WHEN X.Seq = 1 THEN X.Amount ELSE 0 END) AS FirstDraftAmount,
        MAX(CASE WHEN X.Seq = 1 THEN X.Date ELSE NULL END) AS FirstDraftDate,
        MAX(CASE WHEN X.Seq = 2 THEN X.Amount ELSE 0 END) AS SecoundDraftAmount,     
        MAX(CASE WHEN X.Seq = 2 THEN X.Date ELSE NULL END) AS SecoundDraftDate       
    INTO #Drafts
    FROM
        (SELECT c.Id, cpd.[Date], cpd.Amount, ROW_NUMBER() OVER (PARTITION BY c.Id ORDER BY cpd.[Date]) Seq                    
        FROM client.Contract c
            INNER JOIN client.ContractPaymentPlan cpp ON c.Id = cpp.ContractId
                AND cpp.IsActive = 1
            INNER JOIN client.ContractPaymentDetail cpd ON cpp.Id = cpd.ContractPaymentPlanId
            WHERE c.CompanyId = 278) X
    GROUP BY X.Id;		

	SELECT c.Id,
	COUNT(l.Id) AS DebtCount,
	SUM(la.Amount) AS TotalDebtAmount,
	SUM(CASE WHEN ls.SettlementStatusId IN (1, 2, 3) THEN la.Amount ELSE 0 END) AS TotalEligibleDebt,    
    COUNT(CASE WHEN ls.SettlementStatusId IN (6, 9, 11) THEN ls.Id ELSE NULL END) AS SettledDebtCount,
    COUNT(CASE WHEN ls.SettlementStatusId NOT IN (6, 9, 11) THEN la.Amount ELSE NULL END) AS UnSettledDebtCount,
    COUNT(CASE WHEN ls.SettlementStatusId IN (11) THEN la.Amount ELSE NULL END) AS PaidOffDebtCount
	INTO #DebtSummary
	FROM client.Contract AS c
		INNER JOIN loan.Loan l ON c.Id = l.ContractId
			--AND l.LoanStatusId = 1
		INNER JOIN loan.LoanAmount la ON l.Id = la.LoanId
			AND la.IsCurrentValue = 1
		INNER JOIN loan.LoanSettlement ls ON l.Id = ls.LoanId
	WHERE c.CompanyId = 278 GROUP BY c.Id;

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
CONCAT('"', max(permanentAddress2),'"') AS permanentAddress2,
max(city) AS city,
max(state) AS state,
max(zipcode) AS zipcode,
CONCAT('"', max(mailinAadress1),'"') AS mailinAadress1,
CONCAT('"', max(mailingAdress2),'"') AS mailingAdress2,
max(mailingcity) AS mailingcity,
max(mailingstate) AS mailingstate,
max(mailingzipcode) AS mailingzipcode,
max(coApplicant) AS coApplicant,
max(source) AS source,
max(affiliate) AS affiliate,
max(affilateAgent) AS affilateAgent,
MAX(CASE WHEN affilateAgentIsSystemUser=1 THEN 1 ELSE 0 END) AS affilateAgentIsSystemUser,
max(SalesAgent) AS SalesAgent,
MAX(CASE WHEN SalesAgentIsSystemUser=1 THEN 1 ELSE 0 END) AS SalesAgentIsSystemUser,
max(negotiationsAgent) AS negotiationsAgent,
MAX(CASE WHEN negotiationsAgentIsSystemUser=1 THEN 1 ELSE 0 END) AS negotiationsAgentIsSystemUser,
max(status) AS status,
max(prefferedLanguage) AS prefferedLanguage,
max(paymentProcessor) AS paymentProcessor,
max(estimatedDebt) AS estimatedDebt,
max(timezone) AS timezone,
max(lastContactedOn) AS lastContactedOn,
max(rateCard) AS rateCard,
--max(paymentProcessor2) AS paymentProcessor2,
max(specialPurposeAccount) AS specialPurposeAccount,
max(SyncStatus) AS SyncStatus,
max(enrollmentContractStatus) AS enrollmentContractStatus,
max(reference) as reference,
MAX(lastContactedBy) AS lastContactedBy,
MAX(enrollmentDate) AS enrollmentDate,
MAX(draftFrequency) AS draftFrequency,
MAX(programLength) AS programLength,
MAX(settlementFeePercentage) AS settlementFeePercentage,	
MAX(programStartDate) AS programStartDate,
MAX(FirstDraftAmount) AS monthlyDraftAmount,
MAX(FirstDraftDate) AS firstRecurringDraftDate,
MAX(SecoundDraftDate) AS secondRecurringDraftDate, 
 MAX(DebtCount) AS DebtCount,
 MAX(TotalDebtAmount) AS TotalDebtAmount,
 MAX(TotalEligibleDebt) AS TotalEligibleDebt,
 MAX(SettledDebtCount) AS SettledDebtCount,
 MAX(UnSettledDebtCount) AS UnSettledDebtCount,
 MAX(PaidOffDebtCount) AS PaidOffDebtCount,
max(createdOn) as createdOn,
max(updatedOn) as updatedOn
 FROM 
(
SELECT 
mainContract.FriendlyId as Id, 
 (ISNULL(mainContractPaymentIntegration.IntegrationReference , '')) AS externalId,
 (ISNULL(mainContract.CompanyId ,''))AS companyHolder,
 ISNULL((SELECT mainTitle.Name FROM client.Name AS mainName1 JOIN dbo.Title AS mainTitle ON mainTitle.Id=mainName1.TitleId WHERE mainDetail.Id=mainName1.ClientId),'')AS Title,
 (SELECT ISNULL(mainName2.FirstName,'') FROM client.Name AS mainName2 WHERE mainDetail.Id=mainName2.ClientId) AS firstName,
 (SELECT ISNULL(mainName3.MiddleName,'') FROM client.Name AS mainName3 WHERE mainDetail.Id=mainName3.ClientId) AS middleName,
 (SELECT ISNULL(mainName4.LastName,'') FROM client.Name AS mainName4 WHERE mainDetail.Id=mainName4.ClientId) AS LastName,
 (ISNULL(concat((SELECT ISNULL(mainTitle.Name,'') FROM client.Name AS mainName1 JOIN dbo.Title AS mainTitle ON mainTitle.Id=mainName1.TitleId WHERE mainDetail.Id=mainName1.ClientId),' ',(SELECT ISNULL(mainName5.FirstName,'') FROM client.Name AS mainName5 WHERE mainDetail.Id=mainName5.ClientId), ' ', (SELECT ISNULL(mainName3.MiddleName,'') FROM client.Name AS mainName3 WHERE mainDetail.Id=mainName3.ClientId) ,' ',(SELECT ISNULL(mainName4.LastName,'') FROM client.Name AS mainName4 WHERE mainDetail.Id=mainName4.ClientId)),''))mfullName,
 (SELECT ISNULL(mainName5.Suffix,'') FROM client.Name AS mainName5 WHERE mainDetail.Id=mainName5.ClientId ) AS Suffix,
 ISNULL((SELECT mainGender.Name FROM dbo.Gender AS mainGender WHERE mainGender.ID=mainDetail.GenderId), '') AS Gender,
 (ISNULL(mainDetail.MotherMaidenName , ''))as maidenName,
 --(ISNULL(FORMAT(cast( [secure].[Decrypt](mainDetail.SSN)as numeric), '###-##-####'),'')) AS SSN ,
  (ISNULL([secure].[Decrypt](mainDetail.SSN),'')) AS SSN ,
 (ISNULL(CONVERT(nvarchar,mainDetail.BirthDate,101) ,''))AS dob,
 ISNULL((SELECT mainEMAIL.Email FROM client.Email AS mainEMAIL WHERE mainEMAIL.ClientId=mainDetail.Id ),'') AS Email,
(SELECT mainCOMNphone1.Number FROM client.ClientPhone AS mainPhone1 JOIN dbo.PhoneType AS mainPhoneType ON mainPhoneType.Id=mainPhone1.PhoneTypeId JOIN comn.Phone AS mainCOMNphone1 ON mainCOMNphone1.Id=mainPhone1.PhoneId WHERE mainPhone1.ClientId=mainDetail.Id AND mainPhone1.PhoneTypeId = 1) AS primaryMobileNumber,
(SELECT mainCOMNphone2.Number FROM client.ClientPhone AS mainPhone2 JOIN dbo.PhoneType AS mainPhoneType ON mainPhoneType.Id=mainPhone2.PhoneTypeId JOIN comn.Phone AS mainCOMNphone2 ON mainCOMNphone2.Id=mainPhone2.PhoneId WHERE mainPhone2.ClientId=mainDetail.Id AND mainPhone2.PhoneTypeId = 2) AS workPhone,
(SELECT mainCOMNphone3.Number FROM client.ClientPhone AS mainPhone3 JOIN dbo.PhoneType AS mainPhoneType ON mainPhoneType.Id=mainPhone3.PhoneTypeId JOIN comn.Phone AS mainCOMNphone3 ON mainCOMNphone3.Id=mainPhone3.PhoneId WHERE mainPhone3.ClientId=mainDetail.Id AND mainPhone3.PhoneTypeId = 3) AS homePhoneNumber,
(SELECT mainCOMNphone4.Number FROM client.ClientPhone AS mainPhone4 JOIN dbo.PhoneType AS mainPhoneType ON mainPhoneType.Id=mainPhone4.PhoneTypeId JOIN comn.Phone AS mainCOMNphone4 ON mainCOMNphone4.Id=mainPhone4.PhoneId WHERE mainPhone4.ClientId=mainDetail.Id AND mainPhone4.PhoneTypeId = 4) AS FaxNumber,
 (ISNULL(mainDetail.OptedInToSMS,''))AS smsCommunicationMode,
 (ISNULL(mainDetail.OptedInToEmail,''))AS emailCommunicationMode,
 REPLACE(tmpCOMNPermanentAddress.dAddress1,',','')AS permanentAddress1,
 (ISNULL(tmpCOMNPermanentAddress.dAddress2  ,''))AS permanentAddress2,
 (ISNULL(tmpCOMNPermanentAddress.dmainCity ,'')) AS city,
 (ISNULL(tmpCOMNPermanentAddress.dmainState ,'')) AS state,
 (ISNULL(tmpCOMNPermanentAddress.dZipCode ,'')) AS zipcode,
 (ISNULL(tmpCOMNMailingAddress.dAddress1 ,'')) AS mailinAadress1,
 (ISNULL(tmpCOMNMailingAddress.dAddress2  ,''))AS mailingAdress2,
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
 ISNULL(affilateAgent.UserId,'') AS affilateAgent,
 ISNULL(affilateAgentUser.IsSystemUser,'') AS affilateAgentIsSystemUser,
 ISNULL(SalesAgent.UserId,'') AS SalesAgent,
 ISNULL(SalesAgentUser.IsSystemUser,'') AS SalesAgentIsSystemUser,
 ISNULL(negotiationsAgent.UserId,'') AS negotiationsAgent,
 ISNULL(negotiationsAgentUser.IsSystemUser,'') AS negotiationsAgentIsSystemUser,
 (SELECT ISNULL(mainConfiguredStatus.Name,'') FROM company.ConfiguredStatus AS mainConfiguredStatus WHERE mainConfiguredStatus.Id=mainContract.StatusId ) AS status,
 --(ISNULL(mainContract.StatusId,'') )AS status,
 (ISNULL(mainDetail.LanguageId,''))AS prefferedLanguage,
 (ISNULL(mainCompanyPaymentIntegration.IntegrationFriendlyName,'')) AS paymentProcessor,
 (SELECT ISNULL(SUM(tmpLoanamount.Amount),'') FROM loan.loan AS tmpLoan JOIN  loan.LoanAmount AS tmpLoanamount ON tmpLoan.Id=tmpLoanamount.LoanId WHERE tmpLoanamount.IsEnrolledValue = 1 AND tmpLoan.ContractId=mainContract.Id)AS estimatedDebt,
 (SELECT mainTimezone.Abbreviation FROM  dbo.TimeZone AS mainTimezone WHERE mainTimezone.id=tmpCOMNPermanentAddress.dTimeZoneId) AS timezone,
 (mainContract.LastContactDate)AS lastContactedOn,
 (ISNULL(mainContractPaymentIntegration.RateCardVersion,'') )AS rateCard,
 (ISNULL(mainContractPaymentIntegration.IntegrationReference,'')) AS specialPurposeAccount,
 
 ISNULL(CASE WHEN mainContractPaymentIntegration.IntegrationReference IS NULL THEN 'NO' ELSE 'YES' END, '') AS SyncStatus,
 (SELECT TOP 1 srs.Name AS [Status] FROM client.ContractSignatureRequest AS csr
	INNER JOIN [dbo].[SignatureRequestStatus] AS srs ON csr.RequestStatusId = srs.Id 
	INNER JOIN [company].[DocumentPackage] AS dp ON dp.[Id] = csr.PackageId
	INNER JOIN [dbo].[DocumentPackageType] AS dpt ON dpt.Id = dp.TypeId AND dp.TypeId = 1
	WHERE csr.ContractId =mainContract.id ORDER BY csr.UpdatedDate) AS enrollmentContractStatus,
 mainContract.Reference as reference,
 ln.UserId AS lastContactedBy,
 e.TimeStamp AS enrollmentDate,
 f.Name AS draftFrequency,
 summary.NumberOfMonths AS programLength,
 summary.FirstPaymentDate AS programStartDate,	
 summary.ServiceFeePercentage AS settlementFeePercentage,	
 d.FirstDraftAmount,
 d.FirstDraftDate,
 d.SecoundDraftDate,
 debtSummay.DebtCount,
 debtSummay.TotalDebtAmount,
 debtSummay.TotalEligibleDebt,
 debtSummay.SettledDebtCount,
 debtSummay.UnSettledDebtCount,
 debtSummay.PaidOffDebtCount,
 p.Name AS investorName, 
 ps.Name investorStatus,
 cp.PortfolioId,
 cp.RequestDate, 
 cp.RequestUpdateDate AS PurchaseDate,
 mainContract.CreatedDate as createdOn,
 mainContract.UpdatedDate as updatedOn

FROM client.Contract AS mainContract
  LEFT OUTER JOIN client.ContractApplicant mainContractApplicant ON mainContract.Id = mainContractApplicant.ContractId
  LEFT OUTER JOIN client.Detail AS mainDetail ON mainDetail.Id=mainContractApplicant.ClientId
  LEFT OUTER JOIN company.ConfiguredStatus AS ConfiguredStatus ON mainContract.StatusId = ConfiguredStatus.Id
  LEFT OUTER JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration ON mainContractPaymentIntegration.ContractId=mainContract.Id
  LEFT OUTER JOIN company.PaymentIntegration AS mainCompanyPaymentIntegration ON mainCompanyPaymentIntegration.id=mainContractPaymentIntegration.CompanyPaymentIntegrationId
  LEFT JOIN audit.LastNote AS ln ON mainContract.Id = ln.ContractId
  LEFT JOIN client.Enrollment AS e ON mainContract.Id = e.ContractId 
  LEFT JOIN client.PaymentCalculatorSetting AS setting ON mainContract.Id = setting.ContractId   
  LEFT JOIN [dbo].[Frequency] AS f ON setting.FrequencyId = f.Id
  LEFT JOIN client.EstimateSummary AS summary ON mainContract.Id = summary.ContractId
  LEFT JOIN client.ContractAssignment AS affilateAgent ON affilateAgent.RoleTypeId = 1 AND affilateAgent.StatusId IN (1,2) AND mainContract.id=affilateAgent.ContractId
  LEFT JOIN [identity].[Users] AS affilateAgentUser ON affilateAgent.UserId = affilateAgentUser.Id
  LEFT JOIN client.ContractAssignment AS SalesAgent ON SalesAgent.RoleTypeId = 1 AND SalesAgent.StatusId IN (1,2) AND mainContract.id=SalesAgent.ContractId
  LEFT JOIN [identity].[Users] AS SalesAgentUser ON SalesAgent.UserId = SalesAgentUser.Id
  LEFT JOIN client.ContractAssignment AS negotiationsAgent ON negotiationsAgent.RoleTypeId = 3 AND negotiationsAgent.StatusId IN (1,2) AND mainContract.id=negotiationsAgent.ContractId
  LEFT JOIN [identity].[Users] AS negotiationsAgentUser ON negotiationsAgent.UserId = negotiationsAgentUser.Id
  LEFT OUTER JOIN client.ContractPurchaser cp ON mainContract.Id = cp.ContractId
  LEFT OUTER JOIN company.Purchaser AS p ON cp.PurchaserId = p.Id
  LEFT OUTER JOIN dbo.PurchaserStatus AS ps ON cp.StatusId = ps.Id  
  LEFT JOIN #Drafts AS d ON mainContract.Id = d.Id
  LEFT JOIN #DebtSummary AS debtSummay ON mainContract.Id = debtSummay.Id
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
      AND ConfiguredStatus.IsContractSigned=1
	  AND mainContractApplicant.IsPrimary=1 
      AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
	AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10
    -- and mainContract.FriendlyId in (113393, 115340, 124024, 124306, 126663, 127662, 129185, 129372, 130551, 126334)
    )as mainQuery
group by id order by id;
 IF OBJECT_ID('tempdb..#Drafts') IS NOT NULL DROP TABLE #Drafts;
 IF OBJECT_ID('tempdb..#DebtSummary') IS NOT NULL DROP TABLE #DebtSummary;