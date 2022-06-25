SELECT 
    --CASE WHEN c.CompanyId = 302 THEN 'JWF' ELSE 'LAC' END AS Company,
	'ERG' AS Company,
    cpd.Id AS ID, c.FriendlyId AS CLID, cpd.[Date] AS PAYMENTDATE, cpdad.ThirdPartyUpdateDate AS POSTDATE, cpd.Amount AS AMOUNT, cpdad.PaymentReference AS PAYMENTSCHEDULEID, ps.Name AS DRAFTSTATUS
FROM client.Contract c
    INNER JOIN company.ConfiguredStatus cs ON c.StatusId = cs.Id
        AND cs.IsContractSigned = 1
    INNER JOIN client.ContractPaymentPlan cpp ON c.Id = cpp.ContractId
        AND cpp.IsActive = 1
    INNER JOIN client.ContractPaymentDetail cpd ON cpp.Id = cpd.ContractPaymentPlanId
        --AND cpd.Date BETWEEN '2020-12-28' AND '2021-02-04'
    INNER JOIN dbo.PaymentStatus ps ON cpd.StatusId = ps.Id
    LEFT OUTER JOIN client.ContractPaymentDetailAchDispatch cpdad ON cpd.Id = cpdad.ContractPaymentDetailId
        AND cpdad.IsActive = 1
WHERE c.CompanyId IN (278)
ORDER BY c.CompanyId, cpd.[Date]