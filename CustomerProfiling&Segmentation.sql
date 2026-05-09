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
-- 