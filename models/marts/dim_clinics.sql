{{ config(materialized='table') }}

select
    clinic_code,
    clinic_name,
    -- Add derived fields for clinic analysis
    case 
        when clinic_name like '%LLC%' then 'LLC'
        when clinic_name like '%Inc%' then 'Inc'
        when clinic_name like '%Group%' then 'Group'
        else 'Other'
    end as clinic_type
from {{ ref('stg_clinics') }}
