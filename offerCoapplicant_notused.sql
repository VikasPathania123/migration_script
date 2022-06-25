
SELECT 
mainLoanSettlementOffer.Id,
ISNULL(mainLoan.ExternalId,'') as externalId,
ISNULL(CONVERT(nvarchar, (DateAdd(DAY,7,client.ContractCustomDocument.CreatedDate )),121),'') as creditorOfferExpiryDate,
ISNULL(CONVERT(nvarchar, client.ContractCustomDocument.CreatedDate,121),'') as creditorOfferPublishDate ,
ISNULL(mainLoanSettlementOffer.OfferStatusId,'') as creditorOfferStatus ,
ISNULL(mainLoanSettlementOffer.TotalPayments,'')as settledAmount ,
ISNULL(mainLoanSettlementOffer.OfferStatusId,'') as clientOfferStatus ,
ISNULL(mainLoanSettlement.LoanId,'') as debt,
(select ISNULL(ll.LenderId,'') from loan.LoanLender ll where ll.LoanId =mainLoan.Id and ll.IsActive=1)as creditor,
ISNULL(mainContract.FriendlyId,'') as ClientId,
nat.Path as template ,
case when mainLoanSettlement.ExternalId= null then 'NO' else 'YES' end as syncStatus,
case when mainLoanSettlement.ExternalId= null then 'NO' else 'YES' end as lastSuccessfulSyncStatus,
ISNULL(company.PaymentIntegration.IntegrationFriendlyName,'') as paymentProcessor,
--case when ScheduledLoanRelatedFees.IsLoanRepaymentFee=1 then ScheduledLoanRelatedFees.Amount else '' end as payments,
ISNULL(metadata.PayeeAccountNumber,'') as creditorBankAccount,
ISNULL(metadata.Address1,'') as Address1,
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
JOIN dbo.LoanSettlementOfferStatus on mainLoanSettlementOffer.OfferStatusId = dbo.LoanSettlementOfferStatus.Id
JOIN client.ContractApplicant as ca on ca.ContractId = mainContract.id
JOIN client.ContractPaymentIntegration on ca.ContractId = client.ContractPaymentIntegration.ContractId
JOIN company.PaymentIntegration on company.PaymentIntegration.Id = client.ContractPaymentIntegration.PaymentIntegrationId
--full outer JOIN client.ScheduledLoanRelatedFees on [Staging_GravityDB].client.ScheduledLoanRelatedFees.ContractId = mainContract.id 
LEFT JOIN loan.LoanSettlementOfferDocument lsod on lsod.OfferId = mainLoanSettlementOffer.Id and lsod.IsActive=1
left JOIN client.ContractCustomDocument on client.ContractCustomDocument.id = lsod.DocumentId
LEFT JOIN loan.LoanSettlementOfferMetadata as metadata on metadata.OfferId = mainLoanSettlementOffer.Id
LEFT JOIN company.Company on mainContract.CompanyId = company.Company.id
LEFT JOIN company.NotificationSetting ns on ns.CompanyId = company.Company.id and ns.NotificationTypeId=12
LEFT JOIN company.NotificationAttachmentTemplate as nat on nat.NotificationSettingId = ns.Id and nat.IsEmbedded=0
 
WHERE mainContract.CompanyId=278
 AND ca.IsPrimary=0;
