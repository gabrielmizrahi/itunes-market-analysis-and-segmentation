

-----------------------------------------
--#1

create schema if not exists dwh;-- יצירת סכמה במידה ולא קיימת

-----------------------------------------
--#2
--DIM_CURRENCY

create table if not exists dwh.dim_currency as (
select *
from stg.exchange_rates
);

--הצגת הטבלה 
select *
from dwh.dim_currency


-----------------------------------------
--#3
--DIM_PLAYLIST

create table if not exists dwh.dim_playlist as (
select distinct playlisttrack.*,
                playlist.name
from stg.playlisttrack
join stg.playlist
on playlisttrack.playlistid = playlist.playlistid
);

--הצגת הטבלה 
select *
from dwh.dim_playlist


-----------------------------------------
--#4
--DIM_CUSTOMER


create table if not exists dwh.dim_customer as (
with cte_right_name_v_domain as ( 
select customerid,
	   firstname,
       concat(
       		upper(substring(firstname, 1, 1)), 
     		lower(substring(firstname, 2, length(firstname))) 
     		)as name_v,
       lastname,
       concat(
          upper(substring(lastname, 1, 1)), 
     	  lower(substring(lastname, 2, length(lastname))) 
     		)as lastname_v,
        email,
	    right(email, length(email) - position('@' in email)) as domain
from stg.customer 
)

select cte_right_name_v_domain.customerid,
       cte_right_name_v_domain.name_v as firstname,
       cte_right_name_v_domain.lastname_v as lastname,
       cte_right_name_v_domain.email,
       cte_right_name_v_domain.domain,
       stg.customer.company,
       stg.customer.address,
       stg.customer.city,
       stg.customer.state,
       stg.customer.country,
       stg.customer.postalcode,
       stg.customer.phone,
       stg.customer.fax,
       stg.customer.supportrepid,
       stg.customer.last_update
from cte_right_name_v_domain
join stg.customer 
on cte_right_name_v_domain.customerid = stg.customer.customerid 
);

--הצגת הטבלה 
select *
from dwh.dim_customer

-----------------------------------------
--#5
--DIM_EMPLOYEE

create table if not exists dwh.dim_employee as (
select distinct employee.*,
	   department_budget.department_name ,
	   department_budget.total_budget,
	   extract (year from age(current_date, employee.hiredate)) ||' '|| 'Years' as hire_length,
       right(employee.email, length(employee.email) - position('@' in employee.email)) as domain,
       case 
		   when employee.employeeid in (select distinct reportsto from stg.employee where reportsto is not null)	
    	   then '1'
           else '0'
       end as is_manager
from stg.employee
join stg.department_budget
on stg.employee.departmentid = stg.department_budget.department_id
);


select *
from dwh.dim_employee


-----------------------------------------

--#6
--DIM_TRACK

--הצגת כל העמודות לצורך השוואה ובדיקה לפני יצירת הטבלה

select table_name,
	   column_name,	
	   data_type
from information_schema.columns
where table_schema = 'stg'
  and table_name in ('track', 'album', 'artist', 'genre', 'mediatype')
order by table_name, ordinal_position;



--בניית הטבלה
create table if not exists dwh.dim_track as (
select 
    t.trackid as track_id,
    t.name as track_name,
    a.albumid as album_id,
    a.title as album_title,
    a.last_update as album_last_update,
    ar.artistid as artist_id,
    ar.name as artist_name,
    ar.last_update as artist_last_update,
    g.genreid as genre_id,
    g.name as genre_name,
    g.last_update as genre_last_update,
    mt.mediatypeid as mediatype_id,
    mt.name as mediatype_name,
    mt.last_update as mediatype_last_update,
    t.milliseconds as track_duration_milliseconds,
    round(t.milliseconds / 1000.0, 2) as track_duration_seconds,
    concat(
        floor(t.milliseconds / 60000)::text,
        ':', 
        lpad(floor((t.milliseconds % 60000) / 1000)::text, 2, '0')
    ) as track_duration_formatted,
    t.unitprice as track_unit_price,
    t.composer as track_composer,
    t.bytes as track_size_bytes,
    t.last_update as track_last_update
from stg.track t
    join stg.album a 
        on t.albumid = a.albumid
    join stg.artist ar 
        on a.artistid = ar.artistid
    join stg.genre g 
        on t.genreid = g.genreid
    join stg.mediatype mt 
        on t.mediatypeid = mt.mediatypeid
);
 
--הצגת הטבלה
select *
from dwh.dim_track dt 

-----------------------------------------
--#7
--FACT_INVOICE

select *
from stg.invoice

-- בדיקה האם הטבלה fact_invoice כבר קיימת. אם לא - יצירה שלה.
create table if not exists dwh.fact_invoice as (

    -- שליפת הנתונים הנדרשים מתוך טבלת המקור stg.invoice
select invoiceid,       -- מזהה ייחודי של כל חשבונית
        customerid,      -- מזהה הלקוח של החשבונית
        invoicedate,     -- תאריך יצירת החשבונית
        total            -- הסכום הכולל של החשבונית
from stg.invoice     -- מקור המידע הוא טבלת  stg 
);

-- הצגת כל הנתונים מתוך הטבלה החדשה 
select * 
from dwh.fact_invoice;

-----------------------------------------
--#8

select *
from stg.invoiceline

-- FACT_INVOICELINE: 
--יצירת טבלה עם עמודות נבחרות בלבד
create table if not exists dwh.fact_invoiceline as (
    select 
        invoicelineid,  -- מזהה ייחודי לכל שורת חשבונית
        invoiceid,      -- מזהה החשבונית שאליה השורה שייכת
        trackid,        -- מזהה השיר שנרכש
        unitprice,      -- מחיר ליחידה עבור המוצר בשורה זו
        quantity,       -- מספר היחידות שנרכשו
        last_update     -- תאריך העדכון האחרון של הרשומה
    from stg.invoiceline
);

-- הצגת הנתונים מהטבלה החדשה
select *
from dwh.fact_invoiceline;

-----------------------------------------

