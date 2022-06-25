

--<Migration -1 Month>
DECLARE @migration_date DATE = '' --yyyy-mm-dd is date format

--  e.g @migration_date DATE = '2021-04-21' this is the example


IF OBJECT_ID('tempdb..#offer_document') IS NOT NULL DROP TABLE #offer_document;

SELECT RowNum, ContractId, OfferId, CreatedDate 
INTO #offer_document
FROM
    ( SELECT ROW_NUMBER() OVER(PARTITION BY offer.Id ORDER BY offer.Id) as RowNum, l.ContractId, lsod.OfferId,  client.ContractCustomDocument.CreatedDate
       FROM client.[Contract] c
           INNER JOIN loan.Loan l ON l.ContractId = c.Id
           INNER JOIN loan.LoanSettlement s ON s.LoanId = l.Id
           INNER JOIN loan.LoanSettlementOffer offer ON offer.SettlementId = s.Id
           LEFT JOIN loan.LoanSettlementOfferDocument lsod ON lsod.OfferId = offer.Id 
               AND lsod.IsActive = 1
           LEFT JOIN client.ContractCustomDocument ON client.ContractCustomDocument.id = lsod.DocumentId
      WHERE c.CompanyId = 278
    ) as TEMPB
WHERE RowNum = 1

SELECT
mainLoanSettlementOffer.Id,
 CASE WHEN companyStatus.IsContractSigned = 0 THEN mainContract.FriendlyId ELSE NULL END AS LeadId,
   CASE WHEN companyStatus.IsContractSigned = 1 THEN mainContract.FriendlyId ELSE NULL END AS ClientId,
ISNULL(mainLoan.ExternalId,'') as externalId,
ISNULL(CONVERT(nvarchar, (DateAdd(DAY,7,CCD.CreatedDate )),101),'') as creditorOfferExpiryDate,
ISNULL(CONVERT(nvarchar, CCD.CreatedDate,101),'') as creditorOfferPublishDate ,
ISNULL(offerStatus.Name,'') as creditorOfferStatus ,
ISNULL(mainLoanSettlementOffer.TotalPayments,'')as settledAmount ,
ISNULL(offerStatus.Name,'') as clientOfferStatus ,
ISNULL(mainLoanSettlement.LoanId,'') as debt,
(select ISNULL(ll.LenderId,'') from loan.LoanLender ll where ll.LoanId =mainLoan.Id and ll.IsActive=1)as creditor,

nat.Path as template ,
case when mainLoanSettlement.ExternalId= null then 'NO' else 'YES' end as syncStatus,
case when mainLoanSettlement.ExternalId= null then 'NO' else 'YES' end as lastSuccessfulSyncStatus,
ISNULL(mainPaymentIntegration.IntegrationFriendlyName,'') as paymentProcessor,
--case when ScheduledLoanRelatedFees.IsLoanRepaymentFee=1 then ScheduledLoanRelatedFees.Amount else '' end as payments,
ISNULL(metadata.PayeeAccountNumber,'') as creditorBankAccount,
CONCAT('"', ISNULL(metadata.Address1,''),'"') as Address1,
ISNULL(metadata.City,'') as city,
ISNULL(metadata.Zipcode,'') as Zipcode,
--ISNULL(Document.DocumentId,'') as clientAuth,
--ISNULL(Document.DocumentId,'') as creditorAuth,
(SELECT ISNULL(e.Email,'') FROM client.Email e WHERE e.ClientId=ca.ClientId ) as Email,
mainLoanSettlementOffer.CreatedDate, mainLoanSettlementOffer.UpdatedDate

FROM
loan.LoanSettlementOffer mainLoanSettlementOffer
JOIN loan.LoanSettlement as  mainLoanSettlement on mainLoanSettlementOffer.SettlementId =mainLoanSettlement.Id
JOIN loan.Loan as mainLoan on   mainLoanSettlement.LoanId =mainLoan.Id
JOIN client.Contract mainContract on  mainContract.id = mainLoan.ContractId 
JOIN dbo.LoanSettlementOfferStatus as offerStatus on mainLoanSettlementOffer.OfferStatusId = offerStatus.Id
JOIN client.ContractApplicant as ca on ca.ContractId = mainContract.id
LEFT OUTER JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration  ON mainContract.Id = mainContractPaymentIntegration.ContractId
LEFT OUTER JOIN company.PaymentIntegration AS mainPaymentIntegration ON mainPaymentIntegration.Id =mainContractPaymentIntegration.CompanyPaymentIntegrationId
--JOIN client.ContractPaymentIntegration on ca.ContractId = client.ContractPaymentIntegration.ContractId
--JOIN company.PaymentIntegration on company.PaymentIntegration.Id = client.ContractPaymentIntegration.PaymentIntegrationId
LEFT JOIN #offer_document as CCD ON CCD.OfferId = mainLoanSettlementOffer.Id
--LEFT JOIN loan.LoanSettlementOfferDocument lsod on lsod.OfferId = mainLoanSettlementOffer.Id and lsod.IsActive=1
--left JOIN client.ContractCustomDocument on client.ContractCustomDocument.id = lsod.DocumentId
LEFT JOIN loan.LoanSettlementOfferMetadata as metadata on metadata.OfferId = mainLoanSettlementOffer.Id
LEFT JOIN company.Company on mainContract.CompanyId = company.Company.id
LEFT JOIN company.NotificationSetting ns on ns.CompanyId = company.Company.id and ns.NotificationTypeId=12
LEFT JOIN company.NotificationAttachmentTemplate as nat on nat.NotificationSettingId = ns.Id and nat.IsEmbedded=0
 left join company.ConfiguredStatus as companyStatus on companyStatus.Id = mainContract.StatusId
WHERE mainContract.CompanyId=278
	AND ca.IsPrimary=1 
	AND ((CompanyStatus.IsContractSigned = 1 AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
			AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10) 
		OR (CompanyStatus.IsContractSigned = 0 AND mainContract.CreatedDate > @migration_date))
-- and mainContract.FriendlyId in (113393, 115340, 124024, 124306, 126663, 127662, 129185, 129372, 130551, 126334)

IF OBJECT_ID('tempdb..#offer_document') IS NOT NULL DROP TABLE #offer_document;