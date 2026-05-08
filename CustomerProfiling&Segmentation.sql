-- Count total number of clients in the bank
SELECT COUNT(DISTINCT client_id) FROM client;

-- Count clients per district — which district has the most clients?
SELECT d.district_id,d.district_name,COUNT(c.client_id) as client_cnt FROM district d INNER JOIN client c ON d.district_id=c.district_id GROUP BY d.district_id,d.district_name ORDER BY client_cnt DESC;

-- How many accounts exist per frequency type (POPLATEK MESICNE etc)?
SELECT frequency,COUNT(account_id) as acc_cnt FROM account GROUP BY frequency ORDER BY acc_cnt DESC;
