-- Count total number of clients in the bank
SELECT COUNT(DISTINCT client_id) FROM client;

-- Count clients per district — which district has the most clients?
SELECT d.district_id,d.district_name,COUNT(c.client_id) as client_cnt FROM district d INNER JOIN client c ON d.district_id=c.district_id GROUP BY d.district_id,d.district_name ORDER BY client_cnt DESC;

-- How many accounts exist per frequency type (POPLATEK MESICNE etc)?
SELECT frequency,COUNT(account_id) as acc_cnt FROM account GROUP BY frequency ORDER BY acc_cnt DESC;

-- How many accounts were opened each year? (parse date YYMMDD format)
SELECT YEAR(date),COUNT(account_id) as acc_cnt FROM account GROUP BY YEAR(date);

-- List all clients with their birth year extracted from birth_number
select client_id,year(dateofbirth) from client;

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

-- 