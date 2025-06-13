--sql analysis 

-------------------------------------------1
-- יצירת טבלה זמנית עם מספר השירים הייחודיים לכל פלייליסט
with cte_track_count as (
    select 
        playlistid, 
        count(distinct trackid) as track_count -- מספר השירים הייחודיים בכל פלייליסט
    from dwh.dim_playlist
    group by playlistid
),
-- טבלה זמנית למציאת הפלייליסט עם הכי הרבה שירים
max_playlist as (
    select 
        'max' as category, 
        playlistid, 
        track_count -- המספר המקסימלי של שירים
    from cte_track_count
    where track_count = (select max(track_count) from cte_track_count)
),
-- טבלה זמנית למציאת הפלייליסט עם הכי מעט שירים
min_playlist as (
    select 
        'min' as category, 
        playlistid, 
        track_count -- המספר המינימלי של שירים
    from cte_track_count
    where track_count = (select min(track_count) from cte_track_count)
),
-- חיבור תוצאות הפלייליסטים עם הכי הרבה והכי מעט שירים
combined_results as (
    select * from max_playlist
    union all
    select * from min_playlist
)
-- שליפה סופית עם ממוצע השירים לכל הפלייליסטים
select 
    category, -- קטגוריה: מקסימום או מינימום
    playlistid, -- מזהה הפלייליסט
    track_count, -- מספר השירים
    (select avg(track_count) from cte_track_count) as avg_track_count -- ממוצע מספר השירים
from combined_results;


-------------------------------------------2

-- תחילה, נאסוף את כמות המכירות לכל שיר.
-- אנו מחברים את הטבלאות fact_invoice ו-fact_invoiceline כדי להתאים בין מכירות לחשבוניות.
select 
    il.trackid, -- מזהה ייחודי של השיר
    count(il.invoicelineid) as total_sales -- סך המכירות (מספר פעמים שהשיר נמכר)
from 
    dwh.fact_invoiceline il -- טבלת השורות בחשבונית
join 
    dwh.fact_invoice i -- טבלת החשבוניות הראשית
on 
    il.invoiceid = i.invoiceid -- התאמת כל שורת מכירה לחשבונית הראשית
group by 
    il.trackid; -- קיבוץ לפי מזהה השיר לקבלת סך המכירות.
-- כעת נעטוף את השאילתה הפנימית ונחלק את השירים לקבוצות בהתאם לכמות המכירות.
select 
    trackid, -- מזהה ייחודי של השיר
    total_sales, -- סך המכירות לשיר
    -- חלוקת השירים לקבוצות לפי CASE בהתאם לכמות המכירות
    case 
        when total_sales = 0 then '0' -- קבוצה: לא נמכר כלל
        when total_sales between 1 and 5 then '1-5' -- קבוצה: 1 עד 5 מכירות
        when total_sales between 6 and 10 then '5-10' -- קבוצה: 6 עד 10 מכירות
        else '10<' -- קבוצה: מעל 10 מכירות
    end as sales_group -- קבוצה אליה השיר משתייך
from (
    -- שאילתה פנימית לאיסוף נתוני המכירות
    select 
        il.trackid, -- מזהה ייחודי של השיר
        count(il.invoicelineid) as total_sales -- סך המכירות
    from 
        dwh.fact_invoiceline il 
    join 
        dwh.fact_invoice i 
    on 
        il.invoiceid = i.invoiceid 
    group by 
        il.trackid
) as sales_data -- שם זמני לשאילתה הפנימית
order by 
    total_sales desc; -- סדר התוצאות מהשיר עם הכי הרבה מכירות להכי מעט.

-------------------------------------------3
----A   
-- חישוב סך המכירות לכל מדינה
with country_sales as (
    select 
        c.country,
        sum(i.total) as total_sales
    from 
        dwh.fact_invoice i
    join 
        dwh.dim_customer c
    on 
        i.customerid = c.customerid
    group by 
        c.country
),
-- בחירת 5 המדינות עם המכירות הגבוהות ביותר
top_5_countries as (
    select 
        country, 
        total_sales
    from 
        country_sales
    order by 
        total_sales desc
    limit 5
),
-- בחירת 5 המדינות עם המכירות הנמוכות ביותר
bottom_5_countries as (
    select 
        country, 
        total_sales
    from 
        country_sales
    order by 
        total_sales asc
    limit 5
)
-- שילוב והצגת התוצאה הסופית
select 
    country,
    total_sales,
    'Top 5' as category
from 
    top_5_countries

union all

select 
    country, 
    total_sales, 
    'Bottom 5' as category
from 
    bottom_5_countries

order by 
    category,
    total_sales desc;

----b
 -- חישוב סך המכירות של כל ז'אנר בכל מדינה
with genre_sales as (
    select 
        c.country,
        t.genre_name,
        sum(il.quantity * il.unitprice) as genre_sales
    from 
        dwh.fact_invoice i
    join 
        dwh.fact_invoiceline il
    on 
        i.invoiceid = il.invoiceid
    join 
        dwh.dim_customer c
    on 
        i.customerid = c.customerid
    join 
        dwh.dim_track t
    on 
        il.trackid = t.track_id
    group by 
        c.country, t.genre_name
),
-- חישוב סך המכירות הכולל בכל מדינה
total_country_sales as (
    select 
        c.country,
        sum(i.total) as total_sales
    from 
        dwh.fact_invoice i
    join 
        dwh.dim_customer c
    on 
        i.customerid = c.customerid
    group by 
        c.country
)
-- חישוב אחוזי המכירות לכל ז'אנר ודירוג גלובלי
select 
    gs.country,
    gs.genre_name,
    gs.genre_sales || ' $' as genre_sales,
    round(gs.genre_sales * 100.0 / tcs.total_sales, 2) || '%' as sales_percentage,
    rank() over (partition by gs.country order by gs.genre_sales desc) as country_sales_rank
from 
    genre_sales gs
join 
    total_country_sales tcs
on 
    gs.country = tcs.country
order by 
    country_sales_rank;

 -------------------------------------------4    
-- יצירת טבלה זמנית לספירת לקוחות ותיוג מדינות
with customer_count_per_country as (
    select 
        country,
        count(customerid) as customer_count, -- ספירת הלקוחות בכל מדינה
        case 
            when count(customerid) = 1 then 'other' -- מדינה עם לקוח יחיד מתויגת כ-'other'
            else country -- שמירת שם המדינה המקורי
        end as country_label -- עמודת תיוג חדשה למדינה
    from dwh.dim_customer
    group by country
),
-- טבלה זמנית שמכילה מידע מסוכם על לקוחות
customer_aggregates as (
    select 
        customerid,
        count(invoiceid) as order_count, -- מספר ההזמנות ללקוח
        avg(total) as avg_total_per_customer -- ממוצע סכום ההזמנות ללקוח
    from dwh.fact_invoice
    group by customerid
),
-- טבלה זמנית שמסכמת נתונים לפי מדינות
country_aggregates as (
    select 
        ccp.country_label as country, -- שם המדינה או התיוג 'other'
        count(c.customerid) as customer_count, -- מספר הלקוחות במדינה
        coalesce(avg(ca.order_count), 0) as avg_orders_per_customer, -- ממוצע ההזמנות ללקוח
        coalesce(avg(ca.avg_total_per_customer), 0) as avg_total_per_customer -- ממוצע הסכום הכולל ללקוח
    from customer_count_per_country ccp
    left join dwh.dim_customer c on ccp.country_label = c.country -- חיבור למדינות בטבלת הלקוחות
    left join customer_aggregates ca on c.customerid = ca.customerid -- חיבור להזמנות הלקוחות
    group by ccp.country_label
)
-- שליפה מסכמת עם מיון לפי מדינה
select 
    country,
    customer_count,
    avg_orders_per_customer,
    avg_total_per_customer
from country_aggregates 
order by country;

 -------------------------------------------5
-- טבלה זמנית לחישוב הכנסות שנתיות לכל עובד
with revenue_per_employee as (
    select 
        e.employeeid,
        e.hire_length1,
        count(c.customerid) as customer_count,
        extract(year from f.invoicedate) as _year, -- חילוץ השנה מתאריך החשבונית
        sum(f.total) as year_total -- סיכום ההכנסות השנתיות
    from dwh.dim_employee e
    join dwh.dim_customer c on c.supportrepid = e.employeeid -- חיבור עובדים ללקוחותיהם
    join dwh.fact_invoice f on c.customerid = f.customerid
    group by e.employeeid, e.hire_length1, extract(year from f.invoicedate)
),
-- חישוב הכנסות השנה הקודמת לכל עובד
yoy_cal as (
    select 
        employeeid,
        hire_length1,
        customer_count,
        _year,
        year_total,
        lag(year_total) over (partition by employeeid order by _year asc) as previous_year_total -- פונקציית lag להשגת ערך השנה הקודמת
    from revenue_per_employee
),
-- חישוב אחוז השינוי משנה לשנה
percentage_growth as (
    select 
        employeeid,
        hire_length1,
        _year,
        customer_count,
        year_total,
        previous_year_total,
        case 
            when previous_year_total is not null and previous_year_total != 0 then 
                (year_total - previous_year_total) * 100.0 / previous_year_total -- חישוב אחוז הצמיחה
            else 
                null
        end as yoy_growth_percentage
    from yoy_cal
)
-- שליפה סופית ומיון לפי עובד ושנה
select 
    employeeid as employee_id,
    hire_length1 as hire_length,
    _year as year,
    customer_count,
    year_total,
    previous_year_total,
    yoy_growth_percentage
from percentage_growth
order by employeeid, _year;


 -------------------------------------------6
-- יצירת חלוקה לעונות והוספת עמודות עבור מכירות ונתוני לקוחות
with seasonal_sales as (
    select 
        dt.genre_name,
        extract(month from fi.invoicedate) as month,
        case 
            when extract(month from fi.invoicedate) in (12, 1, 2) then 'winter'
            when extract(month from fi.invoicedate) in (3, 4, 5) then 'spring'
            when extract(month from fi.invoicedate) in (6, 7, 8) then 'summer'
            when extract(month from fi.invoicedate) in (9, 10, 11) then 'fall'
        end as season,
        fil.unitprice * fil.quantity as sale_amount,
        fi.customerid
    from 
        dwh.dim_track dt
    join 
        dwh.fact_invoiceline fil on dt.track_id = fil.trackid
    join 
        dwh.fact_invoice fi on fil.invoiceid = fi.invoiceid
)

-- חישוב סיכומי מכירות ומספר לקוחות ייחודיים לפי ז'אנר ועונה
, genre_summary as (
    select 
        genre_name,
        season,
        sum(sale_amount) as total_revenue,
        count(distinct customerid) as unique_customers
    from 
        seasonal_sales
    group by 
        genre_name, season
)

-- דירוג ז'אנרים בעונות לפי סך הרווחים
, top_genres as (
    select 
        genre_name,
        season,
        total_revenue,
        unique_customers,
        rank() over (partition by season order by total_revenue desc) as rank
    from 
        genre_summary
)

-- סינון ל-3 הז'אנרים המובילים בכל עונה והצגת התוצאות
select 
    genre_name,
    season,
    total_revenue,
    unique_customers
from 
    top_genres
where rank <= 3
order by 
    season, total_revenue desc; 