{{ config(materialized='view') }}
/*
*/
with CodingCompletedEncounters as (

select MM.Market,HealthPlan_City,ESI.Patientid,ESI.Encounterdate,esi.Visit_Category,Coder_locked_date,Coder_locked_name,
ATR.Activity_Created_Date, ATR.EMR_created_timezone,ESI.Provider_login,ESI.Encounter_Id
from Encountersummaryinfo ESI 
JOIN Member_Master MM ON ESI.patientid = MM.PatientID
JOIN activity_tracking ATR on ATR.PatientID =MM.PatientID and ATR.encounter_id =ESI.encounter_id
 WHERE ATR.Encounter_Status='Coding Review Completed' and datediff(day,ATR.Activity_Created_Date,getdate())<=20
),

CodingCompleteddetailsICDCodes as (select OP1.No_of_ICDCodes,E.* from CodingCompletedEncounters E
LEFT Join ( select count(*) as No_of_ICDCodes,D.Encounterid from Member_EMR_Diagnosis_Code D where Ubiquity_IsActive=1 Group by D.EncounterId) OP1 on op1.Encounterid =E.encounter_id
),

CodingCompleteddetailsCPTCodes as (select OP1.No_of_CPT_Codes,E.* from CodingCompletedEncounters E
LEFT Join ( select count(*) as No_of_CPT_Codes,D.Encounter from CPT_codes D where IsActive=1 Group by D.Encounter) OP1 on op1.Encounter =E.encounter_id
),

final as (
select
E.Market,
E.HealthPlan_City,
E.Patientid,
E.Encounterdate,
E.Provider_login,
Concat(UM.User_first_Name, ' ', UM.user_last_Name) as Provider_Name,
E.Visit_Category,
Concat(UM1.User_first_Name, ' ', UM1.user_last_Name) as Coder_locked_name,
cast(E.Coder_locked_date as datetime )Coder_locked_date,
E.Activity_Created_Date as Coding_Completed_Date_Time,
E.EMR_created_timezone AS Timezone,
ICD.No_of_ICDCodes,
CPT.No_of_CPT_Codes

from CodingCompletedEncounters E
left join user_Master UM ON UM.user_login_name = E.provider_login
left join user_Master UM1 ON UM1.user_login_name = E.Coder_locked_name
left join CodingCompleteddetailsICDCodes ICD ON E.Encounter_Id =ICD.encounter_id
left join CodingCompleteddetailsCPTCodes CPT ON E.Encounter_Id =CPT.encounter_id

)

select * from final


/*
    Uncomment the line below to remove records with null `id` values
*/

-- where id is not null


