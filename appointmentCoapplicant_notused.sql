SELECT 
ta.Id id,
ISNULL(CASE WHEN ta.CalendarTypeId=1 THEN 'Follow Up By Appointment'
     WHEN ta.CalendarTypeId=2 THEN 'Follow Up By Phone'
	 WHEN ta.CalendarTypeId=3 THEN 'Follow Up By Email'
	 WHEN ta.CalendarTypeId=4 THEN 'Follow Up By Task'
	 end ,'') AS type,
ISNULL(CONVERT(nvarchar,ta.Date,101) ,'') AS date,
ISNULL(State.Name ,'') AS leadState,
ISNULL(ta.UserId,'') AS assignee,
ISNULL( CASE WHEN ConfiguredStatus.IsContractOpen=1 THEN ta.ContractId END ,'') AS lead,
ISNULL(CASE WHEN ConfiguredStatus.IsContractOpen=0 THEN ta.ContractId END ,'') AS client,
ISNULL(dbo.TimeZone.Abbreviation,'')timeZone,
 ISNULL(CASE WHEN atd.DispositionStatus=1 THEN 'Scheduled'
      WHEN atd.DispositionStatus=2 THEN 'NoShow'
	  WHEN atd.DispositionStatus=3 THEN 'Missed'
	  WHEN atd.DispositionStatus=4 THEN 'ReScheduled'
	  WHEN atd.DispositionStatus=5 THEN 'Completed'
	  WHEN atd.DispositionStatus=6 THEN 'Deleted'
	  WHEN atd.DispositionStatus=7 THEN 'NotSet'
	  ELSE'' END ,'') AS status,
	  ISNULL(CONVERT(nvarchar,ta.ReminderDate,101),'') AS setReminder,
	  ta.CreatedDate, ta.UpdatedDate

FROM task.Appointment AS ta
INNER JOIN client.Contract  AS mainCon  ON ta.ContractId = mainCon.Id
INNER JOIN company.Company ON mainCon.CompanyId = company.Company.id
INNER JOIN client.ContractApplicant ON mainCon.Id = client.ContractApplicant.ContractId    
INNER JOIN client.Detail ON client.ContractApplicant.ClientId = client.Detail.Id 
INNER JOIN client.Name ON client.Name.ClientId = client.Detail.Id
INNER JOIN client.ClientAddress ON client.ClientAddress.ClientId = client.[Name].ClientId
LEFT JOIN comn.[Address] ON comn.Address.Id = client.ClientAddress.AddressId
LEFT JOIN dbo.ZipCode ON comn.Address.ZipCodeId = dbo.ZipCode.Id
LEFT JOIN dbo.City ON dbo.ZipCode.CityId = dbo.City.Id
LEFT JOIN dbo.State ON dbo.State.Id = dbo.City.StateId
LEFT JOIN  dbo.TimeZone ON dbo.TimeZone.Id = dbo.ZipCode.TimeZoneId
INNER JOIN task.AppointmentTaskDisposition  AS atd ON atd.AppointmentId = ta.id AND IsCurrent=1 
INNER JOIN company.ConfiguredStatus ON mainCon.StatusId = company.ConfiguredStatus.Id

WHERE company.Company.id=278
AND client.ContractApplicant.IsPrimary=0;
