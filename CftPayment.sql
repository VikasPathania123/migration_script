SELECT 
    s.id AS id,
    s.external_id AS externalId,
    (SELECT 
            name
        FROM
            schedule_type_enum
        WHERE
            id = s.transaction_type_id) AS type,
    s.check_number AS checkNumber,
    sa.trace_number AS trackingNumber,
    s.reason AS reason,
    (CASE
        WHEN pcm.dbt_creditor_id IS NOT NULL THEN pcm.dbt_creditor_id
        WHEN
            pcm.dbt_creditor_id IS NULL
                AND pc.id IS NOT NULL
        THEN
            pc.id
        ELSE - 1
    END) AS creditor,
    ra.account_number AS routableAccountNumber,
    ra.preferred_routing_number AS routableRoutingNumber,
    (SELECT 
            name
        FROM
            entity_name_enum
        WHERE
            id = s.routable_account_owner) AS routingAccountOwner,
    (CASE
        WHEN pdm.dbt_debt_id IS NOT NULL THEN pdm.dbt_debt_id
        WHEN
            pdm.dbt_debt_id IS NULL
                AND pd.id IS NOT NULL
        THEN
            pd.id
        ELSE - 1
    END) AS debt,
(CASE
        WHEN psm.dbt_stl_id IS NOT NULL THEN psm.dbt_stl_id
        WHEN
            psm.dbt_stl_id IS NULL
                AND ps.id IS NOT NULL
        THEN
            ps.id
        ELSE - 1
    END) AS settlement,
    sa.return_code AS returnCode,
    sa.tracking_id AS trackingId,
    sa.courier_vendor AS shippedBy,
    s.schedule_date AS scheduleDate,
    IFNULL(s.allow_duplicate_schedule, 0) AS isAllowDuplicate,
    s.amount AS amount,
    (SELECT 
            name
        FROM
            schedule_status_enum
        WHERE
            id = s.status) AS status,
    s.status_reason AS statusReason,
    (SELECT 
            name
        FROM
            transaction_method_enum
        WHERE
            id = s.transaction_method_id) AS method,
    (SELECT 
            external_id
        FROM
            deposit_account
        WHERE
            id = s.from_deposit_account_id) AS sourceAccount,
    (SELECT 
            external_id
        FROM
            external_account
        WHERE
            id = s.to_external_account_id) AS destinationAccount,
    (SELECT 
            id
        FROM
            address
        WHERE
            id = s.to_address_id) AS destAddress,
    c.external_id AS clientExternalId,
    s.processing_date AS processingDate,
    s.remark AS comment,
    s.created_on AS createdDate,
    s.last_updated_on AS updatedDate,
    cu.email AS createdBy,
    lu.email AS lastUpdatedBy
   
FROM
    schedule s
        INNER JOIN
    settlement stl ON stl.id = s.settlement_id
    -- JOIN with matched stl
		LEFT JOIN 
        (SELECT 
        cft_stl_id,
            MAX(dbt_stl_id) AS dbt_stl_id
    FROM
        tmp.pdi_matched_stl
    GROUP BY cft_stl_id) psm ON psm.cft_stl_id = stl.id
    -- join with dbt settlements
        LEFT JOIN
    (SELECT 
        MAX(id) AS id, cft_settlement_id
    FROM
        tmp.tmp_pdi_mgr_settlement
    GROUP BY cft_settlement_id) ps ON ps.cft_settlement_id = stl.id
        LEFT JOIN
    schedule_attribute sa ON sa.schedule_id = s.id
        INNER JOIN
    creditor cr ON cr.id = s.creditor_id
        LEFT JOIN
        -- join with matched creditors
    (SELECT 
        cft_creditor_id,
            MAX(dbt_creditor_id) AS dbt_creditor_id
    FROM
        tmp.pdi_matched_creditors
    GROUP BY cft_creditor_id) pcm ON pcm.cft_creditor_id = cr.id
    -- join with dbt creditors
        LEFT JOIN
    (SELECT 
        MAX(id) AS id, cft_creditor_id
    FROM
        tmp.tmp_pdi_mgr_creditor
    GROUP BY cft_creditor_id) pc ON pc.cft_creditor_id = cr.id
        INNER JOIN
    debt d ON d.id = s.debt_id
    -- join with matched debts
        LEFT JOIN
    (SELECT 
        cft_debt_id, MAX(dbt_debt_id) AS dbt_debt_id
    FROM
        tmp.pdi_matched_debts
    GROUP BY cft_debt_id) pdm ON pdm.cft_debt_id = d.id
    -- join with dbt debts
        LEFT JOIN
    (SELECT 
        MAX(id) AS id, cft_debt_id
    FROM
        tmp.tmp_pdi_mgr_debt
    GROUP BY cft_debt_id) pd ON pd.cft_debt_id = d.id
        INNER JOIN
    enrollment e ON e.id = s.enrollment_id
        INNER JOIN
    tmp.tmp_pdi_clients t ON t.cft_enrollment_id = e.id
        INNER JOIN
    client c ON c.id = e.client_id
        INNER JOIN
    user cu ON cu.id = s.created_by
        INNER JOIN
    user lu ON lu.id = s.last_updated_by
        LEFT JOIN
    routable_account ra ON ra.id = s.routable_account_id
WHERE
    s.schedule_class_id = 3
        AND s.subscriber_id = 200065
        AND s.status NOT IN (16 , 3, 10, 11) ;