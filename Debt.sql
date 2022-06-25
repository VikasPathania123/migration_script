
--<Migration -1 Month>
DECLARE @migration_date DATE = '' --yyyy-mm-dd is date format

--  e.g @migration_date DATE = '2021-04-21' this is the example

DECLARE @curent_date DATE = GETDATE();

SELECT  
    mainLoan.Id AS id,
    (ISNULL(mainLoan.ExternalId,'')) AS externalId,
    (SELECT top 1 ISNULL(paymentStatus.Name,'') 
                    FROM client.ScheduledLoanRelatedFees AS mainScheduledLoanRelatedFees 
                            INNER JOIN [dbo].[FeeScheduleStatus] AS paymentStatus ON mainScheduledLoanRelatedFees.StatusId = paymentStatus.Id
                    WHERE mainScheduledLoanRelatedFees.ContractId = mainContract.id 
                            AND mainScheduledLoanRelatedFees.OfferId = mainLoanSettlementOffer.Id
                            AND mainScheduledLoanRelatedFees.StatusId NOT IN (6, 13)
                            AND mainScheduledLoanRelatedFees.IsLoanRepaymentFee = 1  
                            AND (mainScheduledLoanRelatedFees.Date < @curent_date) 
                            ORDER BY mainScheduledLoanRelatedFees.Date desc) AS PreviousPaymentStatus,
    (SELECT ISNULL(tmploanAmount.Amount,'') FROM loan.LoanAmount AS tmploanAmount  WHERE tmploanAmount.IsEnrolledValue = 1 AND tmploanAmount.LoanId = mainLoan.Id) AS orignalBalance,
    (ISNULL(mainLoanSettlementOffer.TotalPayments,'')) AS SettlementAmount,
    (ISNULL(mainLoan.CreditLimit,'')) AS creditLimit,
    (ISNULL(mainLoan.MinimumPayment,'')) AS minMonthlyPayment,
    QUOTENAME((SELECT ISNULL(mainLoanLender.AccountNumber,'') FROM  loan.LoanLender mainLoanLender WHERE mainLoanLender.LoanId = mainLoan.Id AND mainLoanLender.Version=1),'"') AS orignalAccountNumber,
    QUOTENAME((SELECT ISNULL(mainLoanLender.AccountNumber,'') FROM  loan.LoanLender mainLoanLender WHERE mainLoanLender.LoanId = mainLoan.Id AND mainLoanLender.IsActive=1),'"') AS currentAccountNumber,
    (case WHEN 
     mainContractAssignment1.UserId IS NOT NULL THEN mainContractAssignment1.UserId
     WHEN mainContractAssignment2.UserId IS NOT NULL THEN mainContractAssignment2.UserId
     WHEN mainContractAssignment3.UserId IS NOT NULL THEN mainContractAssignment3.UserId
     else '' end)AS assignedUser,
    ( CASE   
           WHEN mainLoan.LoanStatusId = 2   THEN 'Deleted'    
           WHEN mainLoan.LoanStatusId = 4   THEN 'Deleted'    
           WHEN mainLoan.LoanStatusId = 3   THEN 'Voided'     
		   WHEN (mainLoan.LoanStatusId = 1 AND mainLoanSettlement.SettlementStatusId = 1)   THEN 'Eligible' 
           WHEN (mainLoan.LoanStatusId = 1 AND mainLoanSettlement.SettlementStatusId = 2)   THEN 'Eligible' 
           WHEN (mainLoan.LoanStatusId = 1 AND mainLoanSettlement.SettlementStatusId = 3)   THEN 'Eligible' 
           WHEN (mainLoan.LoanStatusId = 1 AND mainLoanSettlement.SettlementStatusId = 7)   THEN 'Voided' 
           
           WHEN (mainLoan.LoanStatusId = 1 AND mainLoanSettlement.SettlementStatusId = 11)   THEN 'Repaid'    
           
           WHEN (mainLoan.LoanStatusId = 1 AND mainLoanSettlement.SettlementStatusId = 6)   THEN 'Under Negotiation' 
           WHEN (mainLoan.LoanStatusId = 1 AND mainLoanSettlement.SettlementStatusId = 9)   THEN 'Making Payments'
           
           WHEN (mainLoan.LoanStatusId = 1 AND mainLoanSettlement.SettlementStatusId = 4)   THEN 'Under Negotiation' 
           WHEN (mainLoan.LoanStatusId = 1 AND mainLoanSettlement.SettlementStatusId = 5)   THEN 'Under Negotiation'
		   WHEN (mainLoan.LoanStatusId = 1 AND mainLoanSettlement.SettlementStatusId = 8)   THEN 'Under Negotiation'
           WHEN (mainLoan.LoanStatusId = 1 AND mainLoanSettlement.SettlementStatusId = 10)   THEN 'Under Negotiation' 
           WHEN (mainLoan.LoanStatusId = 1 AND mainLoanSettlement.SettlementStatusId = 12)   THEN 'Under Negotiation'
           WHEN (mainLoan.LoanStatusId = 1 AND mainLoanSettlement.SettlementStatusId = 13)   THEN 'Under Negotiation'
       ELSE 'Eligible' 
          END) AS status,
    (SELECT top 1 ISNULL(paymentStatus.Name,'') 
                    FROM client.ScheduledLoanRelatedFees AS mainScheduledLoanRelatedFees 
                            INNER JOIN [dbo].[FeeScheduleStatus] AS paymentStatus ON mainScheduledLoanRelatedFees.StatusId = paymentStatus.Id
                    WHERE mainScheduledLoanRelatedFees.ContractId = mainContract.id 
                            AND mainScheduledLoanRelatedFees.OfferId = mainLoanSettlementOffer.Id
                            AND mainScheduledLoanRelatedFees.StatusId NOT IN (6, 13)
                            AND mainScheduledLoanRelatedFees.IsLoanRepaymentFee = 1  
                            AND (mainScheduledLoanRelatedFees.Date < @curent_date) 
                            ORDER BY mainScheduledLoanRelatedFees.Date desc) AS lastPaymentStatus,
     (SELECT ISNULL(mainLoanLender.LenderId,'') FROM loan.LoanLender mainLoanLender WHERE mainLoanLender.LoanId = mainLoan.Id  AND mainLoanLender.Version =1) AS orignalCreditor,
     (SELECT ISNULL(mainLoanLender.LenderId,'') FROM loan.LoanLender mainLoanLender WHERE mainLoanLender.LoanId = mainLoan.Id  AND mainLoanLender.IsActive =1 ) AS currentCreditor,
      (SELECT ISNULL(debtType.Name,'') 
    	FROM loan.LoanLender mainLoanLender 
    		INNER JOIN loan.Lender AS lender ON mainLoanLender.LenderId = lender.Id
    		INNER JOIN dbo.DebtType AS debtType ON lender.DebtTypeId = debtType.Id
    	WHERE mainLoanLender.LoanId = mainLoan.Id  AND mainLoanLender.IsActive =1 ) AS debtType,
     (ISNULL(mainLoan.ExternalId,'')) AS cftId,
     (ISNULL((SELECT
				CASE WHEN mainLoanSettlementOffer.TotalPayments IS NOT NULL AND tmpstlloanAmount.Amount IS NOT NULL AND tmpstlloanAmount.Amount != 0
    				THEN mainLoanSettlementOffer.TotalPayments * 100 /tmpstlloanAmount.Amount    
					ELSE 0 
				END AS settlementPercentage 
			FROM loan.LoanAmount as tmpstlloanAmount  where tmpstlloanAmount.IsCurrentValue=1 and tmpstlloanAmount.LoanId=mainLoan.Id) ,''))AS settlementPercentage,
     ( SELECT ISNULL(tmpc.FriendlyId,'') FROM client.Contract AS tmpc JOIN company.ConfiguredStatus AS s ON tmpc.StatusId = s.Id WHERE s.IsContractSigned = 0 AND mainContract.Id=tmpc.Id ) AS lead,
     ( SELECT ISNULL(tmpc.FriendlyId,'') FROM client.Contract AS tmpc JOIN company.ConfiguredStatus AS s ON tmpc.StatusId = s.Id WHERE s.IsContractSigned = 1 AND mainContract.Id=tmpc.Id ) AS clientId,
     (SELECT ISNULL(tmpmainLoanAmount.Amount,'') FROM loan.LoanAmount AS tmpmainLoanAmount WHERE tmpmainLoanAmount.IsCurrentValue=1 AND tmpmainLoanAmount.LoanId=mainLoan.Id ) AS CurrentBalance,
     (SELECT ISNULL (SUM(tmpmainLoanAmount1.Amount),'') FROM loan.LoanAmount AS tmpmainLoanAmount1 WHERE tmpmainLoanAmount1.IsCurrentValue=1 AND tmpmainLoanAmount1.LoanId=mainLoan.Id ) AS enrolledDebtAmount,
     QUOTENAME((ISNULL(mainLoan.NameOnAccount,'')),'"') AS accountName,
     (ISNULL(CONVERT(nvarchar,mainLoan.InDefaultSince,101),'')) AS defaultedDate,
     (SELECT ISNULL(str(mainLoan.Interest,25,3),'')) AS interestRate,
     ISNULL(
         (SELECT top 1 ISNULL(mainScheduledLoanRelatedFees.Amount,'') 
          FROM client.ScheduledLoanRelatedFees AS mainScheduledLoanRelatedFees 
          WHERE mainScheduledLoanRelatedFees.ContractId = mainContract.id 
              AND mainScheduledLoanRelatedFees.OfferId = mainLoanSettlementOffer.Id
              AND mainScheduledLoanRelatedFees.StatusId NOT IN (6, 13) 
              AND mainScheduledLoanRelatedFees.IsLoanRepaymentFee = 1 
              AND (mainScheduledLoanRelatedFees.Date < @curent_date
          )ORDER BY mainScheduledLoanRelatedFees.Date DESC)
     ,'') AS previousPaymentAmount,
     ISNULL(
          (SELECT top 1  CONVERT(nvarchar,mainScheduledLoanRelatedFees.Date,101) 
          FROM client.ScheduledLoanRelatedFees AS mainScheduledLoanRelatedFees 
          WHERE mainScheduledLoanRelatedFees.ContractId = mainContract.id 
          AND mainScheduledLoanRelatedFees.OfferId = mainLoanSettlementOffer.Id
          AND mainScheduledLoanRelatedFees.StatusId NOT IN (6, 13)  
          AND mainScheduledLoanRelatedFees.IsLoanRepaymentFee = 1 
          AND (mainScheduledLoanRelatedFees.Date < @curent_date
          )ORDER BY mainScheduledLoanRelatedFees.Date DESC)
     ,'') AS previousPaymentdate,
     (SELECT case when tmpLoanStatus.Name='Active'THEN 'true' else 'false' end FROM dbo.LoanStatus AS tmpLoanStatus WHERE tmpLoanStatus.Id=mainLoan.LoanStatusId) AS isActive,
     (ISNULL(CONVERT(nvarchar,mainLoanSettlementOffer.TotalFees),'')) AS settlementFee,
     ISNULL(CASE WHEN mainLoan.ExternalId IS NULL THEN 'NO' ELSE 'YES' END, '') AS SyncStatus,
     (SELECT tmpLoanSettlementStatus.Name FROM dbo.LoanSettlementStatus tmpLoanSettlementStatus WHERE tmpLoanSettlementStatus.Id=mainLoanSettlement.SettlementStatusId) AS negotiationStatus,
     mainContractAssignment3.UserId  AS nogotiater,
     (ISNULL(mainPaymentIntegration.IntegrationFriendlyName,'')) AS paymentProcessor, 
     CASE WHEN amount.Amount IS NOT NULL AND amount.Amount != 0 AND mainLoanSettlementOffer.TotalFees IS NOT NULL 
    	THEN mainLoanSettlementOffer.TotalFees/amount.Amount * 100        
           ELSE 0 
          END AS settlementFeePercentage,
     (SELECT MAX(la.StatementDate) FROM loan.LoanAmount AS la WHERE la.LoanId = mainLoan.Id) AS StatementDate,
     mainLoan.CreatedDate, mainLoan.UpdatedDate
FROM loan.Loan AS mainLoan 
    INNER JOIN client.Contract AS mainContract ON mainContract.id = mainLoan.ContractId
        AND mainContract.CompanyId = 278 -- FOR ERG ONLY
    FULL OUTER JOIN client.ContractApplicant mainContractApplicant ON mainContract.Id = mainContractApplicant.ContractId 
        AND mainContractApplicant.IsPrimary = 1 
        AND mainContractApplicant.IsActive = 1
    FULL OUTER JOIN client.Detail AS mainDetail ON mainDetail.Id = mainContractApplicant.ClientId
    FULL OUTER JOIN company.ConfiguredStatus AS ConfiguredStatus ON mainContract.StatusId = ConfiguredStatus.Id 
    LEFT OUTER JOIN client.ContractAssignment AS mainContractAssignment1 ON mainContractAssignment1.ContractId = mainContract.Id 
        AND mainContractAssignment1.RoleTypeId = 1 
        AND mainContractAssignment1.StatusId IN (1,2)
    LEFT OUTER JOIN client.ContractAssignment AS mainContractAssignment2 ON mainContractAssignment2.ContractId = mainContract.Id 
        AND mainContractAssignment2.RoleTypeId = 2 
        AND mainContractAssignment2.StatusId IN (1,2)
    LEFT OUTER JOIN client.ContractAssignment AS mainContractAssignment3 ON mainContractAssignment3.ContractId = mainContract.Id 
        AND mainContractAssignment3.RoleTypeId = 3 
        AND mainContractAssignment3.StatusId IN (1,2)
    LEFT OUTER JOIN loan.LoanSettlement AS mainLoanSettlement ON mainLoanSettlement.LoanId = mainLoan.Id
    LEFT OUTER JOIN loan.LoanSettlementOffer as mainLoanSettlementOffer ON mainLoanSettlementOffer.SettlementId = mainLoanSettlement.Id  
        AND mainLoanSettlementOffer.OfferStatusId = 4 --Accepted
    LEFT JOIN loan.LoanAmount AS amount ON mainLoan.Id = amount.LoanId 
        AND amount.IsCurrentValue = 1
    LEFT OUTER JOIN client.ContractPaymentIntegration AS mainContractPaymentIntegration  ON mainContract.Id = mainContractPaymentIntegration.ContractId
    LEFT OUTER JOIN company.PaymentIntegration AS mainPaymentIntegration ON mainPaymentIntegration.Id =mainContractPaymentIntegration.CompanyPaymentIntegrationId
WHERE (ConfiguredStatus.IsContractSigned = 1 AND mainContractPaymentIntegration.IntegrationReference IS NOT NULL 
			AND LEN(mainContractPaymentIntegration.IntegrationReference) < 10) 
	OR (ConfiguredStatus.IsContractSigned = 0 AND mainContract.CreatedDate > @migration_date )
-- and mainContract.FriendlyId in (113393, 115340, 124024, 124306, 126663, 127662, 129185, 129372, 130551, 126334, 135554, 135551, 135550, 135924, 135940)
