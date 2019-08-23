SELECT 
	s.Netbios_Name0 as DeviceName,
	sd.CustomSetupDiagResult0 as Result,
	sd.ProfileName0 as ProfileName,
	sd.FailureData0 as FailureData,
	sd.FailureDetails0 as FailureDetails,
	sd.Remediation0 as Remediation
FROM 
	v_r_system s INNER JOIN
	V_GS_CM_SetupDiag sd ON s.ResourceID = sd.ResourceID
where 
	sd.CustomSetupDiagResult0 <> 'Success' AND
	sd.profilename0 <> 'FindSuccessfulUpgrade'
order by 
	datecollected0 desc