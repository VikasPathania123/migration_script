SELECT  
mainContractPaymentDetail.id,
(ISNULL(CONVERT(nvarchar,mainContractPaymentDetail.Date,101),'')) scheduledate,
ISNULL(mainContractPaymentDetail.Amount,'') as Amount ,
   CASE WHEN companyStatus.IsContractSigned = 0 THEN mainContract.Id ELSE NULL END AS LeadId,
   CASE WHEN companyStatus.IsContractSigned = 1 THEN mainContract.Id ELSE NULL END AS ClientId,
ISNULL(Case WHEN pcs.FrequencyId=6 THEN ' Monthly'
            WHEN pcs.FrequencyId=4 THEN ' BiWeekly' END ,'')as  frequency,
ISNULL(mainDispatch.PaymentReference,'')AS PaymentReference,
ISNULL(CONVERT(nvarchar,mainContractPaymentDetail.Date,101) ,'')as Date,
ISNULL(pcs.ContractId ,'')as ContractId,
ISNULL(Case WHEN mainContractPaymentDetail.StatusId=1 THEN 'Scheduled'
     WHEN mainContractPaymentDetail.StatusId=2 THEN 'Cleared'
	 WHEN mainContractPaymentDetail.StatusId=3 THEN 'NSF' 
	 WHEN mainContractPaymentDetail.StatusId=4 THEN 'Rescheduled'
	 WHEN mainContractPaymentDetail.StatusId=5 THEN 'Dispatched'
	 WHEN mainContractPaymentDetail.StatusId=6 THEN 'Deleted'
	 WHEN mainContractPaymentDetail.StatusId=7 THEN 'Processing'
	 WHEN mainContractPaymentDetail.StatusId=8 THEN 'Returned'
	 else '' end ,'')as Status,
	 ISNULL(PaymentIntegration.IntegrationFriendlyName ,'')AS paymentProcessor,
	 ISNULL(Case WHEN CPM.PaymentMethodTypeId = 1 THEN 'Money Order' 
	      WHEN CPM.PaymentMethodTypeId = 2 THEN 'ACH'
	      WHEN CPM.PaymentMethodTypeId = 3 THEN 'Credit Card'
		  else '' end ,'')as Method,
		  ISNULL(CONVERT(nvarchar,mainTransaction.Date,101) ,'') as processingDate,
		  ISNULL(CASE WHEN mainDispatch.PaymentReference IS null THEN 'NO' else 'YES' end,'') as syncStatus,
		  ISNULL(CASE WHEN mainDispatch.PaymentReference IS null THEN 'NO' else 'YES' end ,'')as lastSucessfulSyncStatus,
		  ISNULL(maincontract.CompanyId ,'')as company,
mainContractPaymentPlan.CreatedDate, mainContractPaymentPlan.UpdatedDate

FROM client.ContractPaymentDetail AS  mainContractPaymentDetail
LEFT OUTER JOIN client.ContractPaymentPlan AS mainContractPaymentPlan ON mainContractPaymentDetail.ContractPaymentPlanId=mainContractPaymentPlan.Id
LEFT OUTER JOIN client.ContractPaymentDetailAchDispatch AS mainDispatch ON mainDispatch.ContractPaymentDetailId = mainContractPaymentDetail.Id  AND mainDispatch.IsActive=1
LEFT OUTER JOIN client.ContractPaymentIntegration ContractPaymentIntegration ON ContractPaymentIntegration.Id=mainDispatch.PaymentIntegrationId
LEFT OUTER JOIN company.PaymentIntegration AS PaymentIntegration ON PaymentIntegration.Id = ContractPaymentIntegration.CompanyPaymentIntegrationId
LEFT OUTER JOIN client.ContractPaymentMethod cpm ON cpm.ContractId = ContractPaymentIntegration.ContractId
LEFT OUTER JOIN client.PaymentCalculatorSetting pcs ON pcs.ContractId=ContractPaymentIntegration.ContractId
LEFT OUTER JOIN client.[Transaction] AS mainTransaction ON mainTransaction.ExternalId=mainDispatch.PaymentReference
LEFT OUTER JOIN  client.Contract  as maincontract ON maincontract.Id=mainTransaction.ContractId
join company.ConfiguredStatus as CompanyStatus on CompanyStatus.id = mainContract.StatusId 
where mainTransaction.Type=1
AND maincontract.CompanyId = 278 ;