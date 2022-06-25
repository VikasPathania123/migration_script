    
	--<Migration -1 Month>
	DECLARE @migration_date DATE = '' --yyyy-mm-dd is date format

	--  e.g @migration_date DATE = '2021-04-21' this is the example
    DECLARE @companyId INT = 278;

    IF OBJECT_ID('tempdb..#po_ServiceFeeAmountPerLoanAmount') IS NOT NULL DROP TABLE #po_ServiceFeeAmountPerLoanAmount;
	IF OBJECT_ID('tempdb..#po_LoanAndServiceAmount') IS NOT NULL DROP TABLE #po_LoanAndServiceAmount;
	IF OBJECT_ID('tempdb..#po_DraftsTable') IS NOT NULL DROP TABLE #po_DraftsTable;
	IF OBJECT_ID('tempdb..#po_TotalDebtEstimatedTable') IS NOT NULL DROP TABLE #po_TotalDebtEstimatedTable;

	SELECT l.ContractId AS ContractId, SUM(am.Amount) AS TotalDebtEstimated
    INTO #po_TotalDebtEstimatedTable
         FROM client.[Contract] c 
         INNER JOIN loan.Loan l ON c.Id = l.ContractId
         INNER JOIN loan.loanAmount am ON am.LoanId = l.Id
         WHERE c.CompanyId = @companyId
             AND  am.IsValueDuringEnrollment = 1 
             AND l.LoanStatusId = 1 --only active
    GROUP BY ContractId

    SELECT l.ContractId                                        AS ContractId, 
        (summ.ServiceFeePercentage / 100) * am.Amount          AS ServiceFeeAmount, 
        l.MinimumPayment, 
		am.Amount                                              AS LoanAmount,
        (cl.NegotiatedSettlementPercentage / 100 ) * am.Amount AS SettlementAmountWillBe
    INTO #po_ServiceFeeAmountPerLoanAmount
        FROM client.[Contract] c 
        INNER JOIN loan.Loan l ON c.Id = l.ContractId
        INNER JOIN loan.loanAmount am ON am.LoanId = l.Id
        INNER JOIN loan.LoanLender ll ON l.Id = ll.LoanId AND ll.IsActive = 1
        INNER JOIN [company].[CompanyLender] cl ON ll.LenderId = cl.LenderId 
            AND cl.CompanyId = @companyId
        INNER JOIN client.EstimateSummary summ ON l.ContractId = summ.ContractId 
            AND summ.IsActive = 1
        WHERE c.CompanyId = @companyId
            AND am.IsEnrolledValue = 1 
            AND l.LoanStatusId = 1 --only active
    ORDER BY ContractId


	SELECT sfapl.ContractId, SUM(sfapl.ServiceFeeAmount) / COUNT(sfapl.ContractId)  AS AvarageServiceFee, SUM(LoanAmount) AS LoanAmount_SUM, 
	          SUM(MinimumPayment) AS MinimumPayment_SUM, 
              SUM(sfapl.ServiceFeeAmount) AS TotalFeeAmount_SUM,
              SUM(LoanAmount - SettlementAmountWillBe) AS clientTotalSavedBeforeFees_SUM,
              SUM(SettlementAmountWillBe) AS SettlementAmountWillBe_SUM
    INTO #po_LoanAndServiceAmount
    FROM #po_ServiceFeeAmountPerLoanAmount as sfapl
        GROUP BY sfapl.ContractId

    SELECT RowNum, ContractId, Amount, [Date] 
    INTO #po_DraftsTable
    FROM
        ( SELECT ROW_NUMBER() OVER(PARTITION BY p.Id ORDER BY d.Id) as RowNum, p.ContractId, Amount, [Date]
           FROM  client.[Contract] c 
              INNER JOIN client.ContractPaymentPlan p ON c.Id = p.ContractId
              INNER JOIN client.ContractPaymentDetail d ON d.ContractPaymentPlanId = p.Id
          WHERE c.CompanyId = @companyId
              AND p.IsActive = 1
              AND d.StatusId NOT IN (6, 4)
        ) as TEMPB
    WHERE RowNum < 3

    SELECT
        summ.Id                                   AS ProgramOverviewId,
        c.Id                                      AS ContractId, 
        --c.FriendlyId, 
        debtEstimated.TotalDebtEstimated          AS totalDebtEstimated, 
        firstQuery.MinimumPayment_SUM             AS totalMinPayments, 
        firstQuery.AvarageServiceFee              AS averageFeePerDebt,
        firstQuery.clientTotalSavedBeforeFees_SUM AS clientTotalSavedBeforeFees, 
        firstQuery.TotalFeeAmount_SUM             AS totalFeeAmount,
        summ.ServiceFeePercentage                 AS totalFeePercent,
        --0 AS totalDebtSettlementCostToClient,							-- N/A
        SettlementAmountWillBe_SUM                                      AS estimatedSettlementAmount,        
		CASE WHEN SettlementAmountWillBe_SUM IS NOT NULL AND firstQuery.LoanAmount_SUM IS NOT NULL  AND firstQuery.LoanAmount_SUM <>0
			THEN (SettlementAmountWillBe_SUM / firstQuery.LoanAmount_SUM ) * 100  
			ELSE 0 
		END AS estimatedSettlementPercentage,
        firstQuery.LoanAmount_SUM - summ.ProgramCost                    AS clientTotalSavedAfterFees, 
        firstQuery.LoanAmount_SUM                   AS totalDebtEnrolled,
        summ.ProgramCost                            AS esimatedCostToClient,
        --0 AS totalExtraFees,											--N/A
        --0 AS totalCostWithMinPaymentFor30Yeas,						--N/A
        --NULL AS [Lead],
        summ.NumberOfMonths                           AS programLength,
        first_draft.Amount                            AS monthlyDraftAmount,
        CONVERT(VARCHAR, summ.FirstPaymentDate, 101)  AS programStartDate,
        CONVERT(VARCHAR, first_draft.[Date], 101)     AS firstRecurringDraftDate,
        CONVERT(VARCHAR, second_draft.[Date] , 101)   AS secondRecurringDraftDate,
        first_draft.Amount                            AS firstRecurringDraftAmount,
        second_draft.Amount                           AS secondRecurringDraftAmount,
        first_draft.Amount                            AS firstDraftAmount,
        calcSettingFreq.[Name]                        AS draftFrequency,
		CONVERT(VARCHAR, summ.CreatedDate, 101)       AS createdAt,
		NULL                                          AS updatedAt,
        ( SELECT ISNULL(tmpc.FriendlyId,'') FROM client.Contract AS tmpc JOIN company.ConfiguredStatus AS s ON tmpc.StatusId = s.Id WHERE s.IsContractSigned = 0 AND c.Id=tmpc.Id ) AS lead,
        ( SELECT ISNULL(tmpc.FriendlyId,'') FROM client.Contract AS tmpc JOIN company.ConfiguredStatus AS s ON tmpc.StatusId = s.Id WHERE s.IsContractSigned = 1 AND c.Id=tmpc.Id ) AS clientId
    FROM client.[Contract] c
	INNER JOIN company.ConfiguredStatus AS ConfiguredStatus ON c.StatusId = ConfiguredStatus.Id 
    LEFT OUTER JOIN #po_LoanAndServiceAmount firstQuery ON firstQuery.ContractId = c.Id
    LEFT OUTER JOIN #po_TotalDebtEstimatedTable debtEstimated ON debtEstimated.ContractId = c.Id
    LEFT OUTER JOIN client.EstimateSummary summ ON firstQuery.ContractId = summ.ContractId 
        AND IsActive = 1
    LEFT OUTER JOIN client.PaymentCalculatorSetting calcSetting ON calcSetting.ContractId = firstQuery.ContractId
    LEFT OUTER JOIN dbo.Frequency calcSettingFreq ON calcSetting.FrequencyId = calcSettingFreq.Id
    LEFT OUTER JOIN #po_DraftsTable first_draft ON first_draft.ContractId = firstQuery.ContractId AND first_draft.RowNum = 1
    LEFT OUTER JOIN #po_DraftsTable second_draft ON second_draft.ContractId = firstQuery.ContractId AND second_draft.RowNum = 2
    LEFT JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration ON mainContractPaymentIntegration.ContractId=c.Id
    WHERE c.CompanyId = @companyId 
        AND firstQuery.LoanAmount_SUM IS NOT NULL
        AND summ.Id IS NOT NULL
		--AND (ConfiguredStatus.IsContractSigned=1 OR (ConfiguredStatus.IsContractSigned=0 AND c.CreatedDate > @migration_date));
		AND ((ConfiguredStatus.IsContractSigned = 1 AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
				AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10) 
			OR (ConfiguredStatus.IsContractSigned = 0 AND c.CreatedDate > @migration_date ));
	
    
    IF OBJECT_ID('tempdb..#po_ServiceFeeAmountPerLoanAmount') IS NOT NULL DROP TABLE #po_ServiceFeeAmountPerLoanAmount;
	IF OBJECT_ID('tempdb..#po_LoanAndServiceAmount') IS NOT NULL DROP TABLE #po_LoanAndServiceAmount;
    IF OBJECT_ID('tempdb..#po_DraftsTable') IS NOT NULL DROP TABLE #po_DraftsTable;
    IF OBJECT_ID('tempdb..#po_TotalDebtEstimatedTable') IS NOT NULL DROP TABLE #po_TotalDebtEstimatedTable;
	