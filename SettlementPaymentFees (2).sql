SELECT 
    --CASE WHEN c.CompanyId = 302 THEN 'JWF' ELSE 'LAC' END AS Company,
	'ERG' AS Company,
    CASE WHEN slrf.IsLoanRepaymentFee = 1 THEN 'PAYMENT' ELSE 'FEE' END AS Company,
    slrf.Id AS ID, c.FriendlyId AS CLID, slrf.[Date] AS PAYMENTDATE, NULL AS POSTDATE, slrf.Amount AS AMOUNT, slrf.ExternalId AS PAYMENTSCHEDULEID, fss.Name AS TRANSACTIONSTATUS,
    stfm.Fee TRANSACTIONFEE
FROM client.Contract c
    INNER JOIN company.ConfiguredStatus cs ON c.StatusId = cs.Id
        AND cs.IsContractSigned = 1
    INNER JOIN client.ScheduledLoanRelatedFees slrf ON c.Id = slrf.ContractId
        --AND slrf.Date BETWEEN '2020-12-28' AND '2021-02-04'
    INNER JOIN dbo.FeeScheduleStatus fss ON slrf.StatusId = fss.Id
    LEFT OUTER JOIN company.SettlementTransactionFeeMapping stfm ON slrf.FeeMappingId = stfm.Id
WHERE c.CompanyId IN (278)
ORDER BY c.CompanyId, slrf.IsLoanRepaymentFee, slrf.[Date]