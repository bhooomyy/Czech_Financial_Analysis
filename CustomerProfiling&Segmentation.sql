-- Count total number of clients in the bank
SELECT 
    COUNT(DISTINCT client_id) 
    FROM client;

-- Count clients per district — which district has the most clients?
SELECT 
    d.district_id,
    d.district_name,
    COUNT(c.client_id) as client_cnt 
    FROM district d INNER JOIN client c ON d.district_id=c.district_id 
    GROUP BY d.district_id,d.district_name 
    ORDER BY client_cnt DESC;

-- How many accounts exist per frequency type (POPLATEK MESICNE etc)?
SELECT 
    frequency,
    COUNT(account_id) as acc_cnt 
    FROM account 
    GROUP BY frequency 
    ORDER BY acc_cnt DESC;

-- How many accounts were opened each year? (parse date YYMMDD format)
SELECT 
    YEAR(date),
    COUNT(account_id) as acc_cnt 
    FROM account 
    GROUP BY YEAR(date);

-- List all clients with their birth year extracted from birth_number
SELECT 
    client_id,
    YEAR(dateofbirth) 
    FROM client;

-- Join client + disposition + account: list every client with their account_id and role (OWNER vs DISPONENT)
SELECT c.client_id,a.account_id,a.date,d.type 
FROM client c 
INNER JOIN disp d ON c.client_id=d.client_id
INNER JOIN account a ON a.account_id=d.account_id
ORDER BY c.client_id;

-- How many clients are OWNER vs DISPONENT? Show percentage split
-- select count(*) from disp;
SELECT 
    CONCAT(ROUND(COUNT(client_id)*100.0/(SELECT COUNT(*) FROM disp),2),'%') AS client_cnt_by_disptype,
    type 
    FROM disp 
    GROUP BY type;

-- Find accounts that have both an OWNER and a DISPONENT (shared accounts)
/*SELECT 
    distinct d1.account_id 
    FROM disp d1 inner join disp d2 on d1.account_id=d2.account_id 
    where d1.type!=d2.type;*/
SELECT account_id
	FROM disp
    GROUP BY account_id
    HAVING COUNT(type)=2;

-- Count male vs female clients per district
SELECT 
	district_id,
	gender,
	CONCAT(ROUND(COUNT(client_id)*100.0/(SELECT COUNT(*) FROM client),2),'%') as percentage_clients_by_gender
    FROM client
    GROUP BY gender,district_id
    ORDER BY district_id;

-- Calculate each client's age as of 1998-12-31. Bin into age groups: <30, 30-45, 45-60, 60+
WITH A as (
	SELECT 
    TIMESTAMPDIFF(YEAR,dateofbirth,'1998-12-31') AS age 
    FROM client)
SELECT CASE 
	WHEN age<30 THEN "<30" 
    WHEN age>=30 AND age<45 THEN "30-45"
    WHEN age>=45 AND age<60 THEN "45-60"
    ELSE "60+"
    END as bins,
    COUNT(*) as cnt
    FROM A
    GROUP BY bins
    ORDER BY bins;

-- Find clients who own MORE than one account (using disposition type = OWNER)
SELECT 
	client_id, 
    COUNT(account_id) AS cnt 
	FROM disp 
	WHERE type = 'OWNER' 
	GROUP BY client_id 
	HAVING COUNT(account_id) > 1;

SELECT 
    client_id, 
    COUNT(account_id) AS cnt 
    FROM disp 
    WHERE type = 'OWNER' 
    GROUP BY client_id 
    ORDER BY cnt DESC; -- all client has at most 1 account with type OWNER

-- Which district has the highest ratio of female clients to total clients?
SELECT 
	district_id,
    CONCAT(ROUND(SUM(gender='F')*100.0/COUNT(*),2),'%') as female_ratio
    FROM client
    GROUP BY district_id
    ORDER BY SUM(gender='F')/COUNT(*) DESC
    LIMIT 1;

-- Using RANK(), rank districts by number of clients. Show top 10 and bottom 10 in one query using UNION ALL
WITH TOP10 as (SELECT
	district_id,
    COUNT(*) as client_cnt,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rnk
    FROM client
    GROUP BY district_id
    LIMIT 10),
    BOTTOM10 AS (
    SELECT
	district_id,
    COUNT(*) as client_cnt,
    RANK() OVER(ORDER BY COUNT(*) ASC) AS rnk
    FROM client
    GROUP BY district_id
    LIMIT 10)
    SELECT * FROM TOP10
    UNION ALL
    SELECT * FROM BOTTOM10;


-- For each district, calculate the % of accounts opened in the first half vs second half of the dataset's date range (CTE + window)
WITH first_half AS(SELECT 
	district_id, 
    COUNT(DISTINCT account_id) AS first_half_client_cnt
    FROM account 
    WHERE date<(SELECT ADDDATE(min(date),DATEDIFF(MAX(date),MIN(date))/2) FROM account)
    GROUP BY district_id),
    second_half as(SELECT 
    district_id, 
    COUNT(DISTINCT account_id) AS second_half_client_cnt
    FROM account 
    WHERE date>(SELECT ADDDATE(min(date),DATEDIFF(MAX(date),MIN(date))/2) FROM account)
    GROUP BY district_id)
SELECT 
	f.district_id,
	first_half_client_cnt,
    second_half_client_cnt,
    CONCAT(ROUND(first_half_client_cnt*100.0/(SELECT COUNT(*) FROM account),2),'%') as first_half_client_percentage,
    CONCAT(ROUND(second_half_client_cnt*100.0/(SELECT COUNT(*) FROM account),2),'%') as second_half_client_percentage
    FROM first_half f join second_half s ON f.district_id=s.district_id
    ORDER BY f.district_id;

-- Build a client lifetime value proxy: for each OWNER client, sum their total transaction amount across all accounts using a CTE chain
SELECT 
	client_id,
    ROUND(SUM(amount),2) AS total_amount,
    COUNT(trans_id) AS total_transactions,
    MIN(date) AS first_transaction,
    MAX(date) AS last_transaction,
    DATEDIFF(MAX(date),MIN(date)) AS active_days,
    RANK() OVER(ORDER BY SUM(amount) DESC) AS value_rnk
    FROM disp d INNER JOIN trans t ON d.account_id=t.account_id
    WHERE d.type='OWNER'
    GROUP BY client_id
    ORDER BY value_rnk ASC;

-- Using NTILE(4), segment clients into quartiles by their account balance (latest balance from trans). Label each quartile
WITH latest_balance AS(
	SELECT 
    account_id,
    balance,
    ROW_NUMBER() OVER(PARTITION BY account_id ORDER BY date DESC) AS rn
    FROM trans),
	filtered AS(
    SELECT 
    account_id,
    balance
    FROM latest_balance
    WHERE rn=1
    ),
    segment AS(
    SELECT 
    account_id,
    balance,
    NTILE(4) OVER(ORDER BY balance ASC) as quartile
    FROM filtered)
    SELECT
    account_id,
    balance,
    quartile,
    CASE quartile
    WHEN 1 THEN "BRONZE"
    WHEN 2 THEN "SILVER"
    WHEN 3 THEN "GOLDEN"
    WHEN 4 THEN "PLATINUM"
    END as segmen_name
    FROM segment
    ORDER BY quartile;

-- Find the top 5% of clients by total inflow (PRIJEM transactions). Use PERCENT_RANK() or NTILE
WITH ranked AS(
	SELECT 
		d.client_id,
		ROUND(SUM(amount),2) as total_inflow,
		ROUND(PERCENT_RANK() OVER(ORDER BY SUM(amount) ASC),2) as rnk
		FROM trans t INNER JOIN disp d ON d.account_id=t.account_id
		WHERE t.type='PRIJEM'
		GROUP by d.client_id)
SELECT * 
	FROM ranked 	
    WHERE rnk>=0.95
    ORDER BY total_inflow DESC;

 /*Build a full customer 360 view — for each OWNER client: age, gender, district name, account count, total lifetime inflow, 
total outflow, net balance, loan status (if any), card type (if any). Use 5+ CTEs, 4+ JOINs, CASE for decoding, and window RANK to score each client overall.*/
WITH client_info AS(SELECT 
	client_id,
	TIMESTAMPDIFF(YEAR,c.dateofbirth,CURDATE()) AS age, 
    c.gender,
    dist.district_name
	FROM client c INNER JOIN district dist on dist.district_id=c.district_id),
owner_acc AS(
	SELECT 
    client_id,
    account_id
    FROM disp
    WHERE type='OWNER'),
account_summary AS(
    SELECT 
    o.client_id,
    COUNT(distinct o.account_id) as account_cnt,
    ROUND(SUM(CASE WHEN type='PRIJEM' THEN t.amount ELSE 0 END),2) as total_inflow,
    ROUND(SUM(CASE WHEN type='VYDAJ' THEN t.amount ELSE 0 END),2) as total_outflow,
    ROUND(SUM(CASE WHEN type='VYDAJ' THEN -t.amount ELSE t.amount END),2) as net_balance
    FROM owner_acc o JOIN trans t ON t.account_id=o.account_id
    GROUP BY o.client_id),
loan_summary AS(
	SELECT
    o.client_id,
    l.amount as loan_amount,
    CASE l.status
    WHEN 'A' THEN 'Finished - No problem'
    WHEN 'B' THEN 'Finished - Not paid'
    WHEN 'C' THEN 'Running - OK'
    WHEN 'D' THEN 'Running - In debt'
    ELSE 'Not loan'
    END AS loan_status
    FROM owner_acc o LEFT JOIN loan l ON o.account_id=l.account_id),
card_info AS(
	SELECT 
    o.client_id,
    COALESCE(c.type,'No Card') AS card_type
    FROM owner_acc o LEFT JOIN card c on o.client_id=c.disp_id)
SELECT 
	ci.age,
    ci.gender,
    ci.district_name,
    acs.account_cnt,
    acs.total_inflow,
    acs.total_outflow,
    acs.net_balance,
    COALESCE(ls.loan_amount,0) as loan_amount,
    COALESCE(ls.loan_status,'No Loan') as loan_status,
    ROUND((RANK() OVER(ORDER BY acs.total_inflow DESC) + RANK() OVER (ORDER BY acs.total_outflow DESC) + RANK() OVER(ORDER BY acs.net_balance DESC))/3.0,2) as rnk,
    cai.card_type
	FROM client_info ci JOIN account_summary acs ON ci.client_id=acs.client_id
    LEFT JOIN loan_summary ls ON ls.client_id=ci.client_id
    LEFT JOIN card_info cai on cai.client_id=ci.client_id
    ORDER BY rnk
    LIMIT 20;
