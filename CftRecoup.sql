SELECT 
    s.id AS id,
    s.external_id AS externalId,
    s.reason AS reason,
    IFNULL(s.process_instantly, 0) AS instantProcess,
    s.schedule_date AS scheduleDate,
    IFNULL(s.allow_duplicate_schedule, 0) AS isAllowDuplicate,
    s.amount AS amount,
    c.external_id AS clientExternalId,
    s.parent_schedule_external_id AS parentTransactionExtId,
    s.parent_schedule_id as parentTransactionIdCFT,
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
    s.processing_date AS processingDate,
    (SELECT 
            external_id
        FROM
            deposit_account
        WHERE
            id = s.from_deposit_account_id) AS sourceAccount,
    /*(SELECT 
            external_id
        FROM
            deposit_account
        WHERE
            id = s.to_deposit_account_id) AS destinationAccount,*/
    s.remark AS comment,
    s.created_on AS createdDate,
    s.last_updated_on AS updatedDate,
    cu.email AS createdBy,
    lu.email AS lastUpdatedBy
FROM
    schedule s
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
WHERE
    s.schedule_class_id = 9
        AND s.subscriber_id = 200065
        AND s.status not in (16, 3, 10, 11)
        -- AND s.created_on >= '2016-08-04 00:00:00'
        -- AND e.external_id in (113393, 115340, 124024, 124306, 126663, 127662, 129185, 129372, 130551,126334);
