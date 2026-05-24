-- Find accounts with more than 5 transactions on a single day (velocity check)
SELECT
	account_id,
    COUNT(DISTINCT trans_id) AS num_trans,
    DATE(date) AS per_day
	FROM trans
    GROUP BY account_id,per_day
    HAVING num_trans>5;

-- Identify round-number transactions (amount divisible by 1000) — these are often suspicious. What % of all transactions are round numbers? 
SELECT * FROM(SELECT
	trans_id,
    account_id,
    amount,
	(CASE WHEN amount%1000=0 THEN 'Suspicious' 
		 ELSE 'Normal' 
         END) AS flag_trans,
    CONCAT(ROUND(SUM(CASE WHEN amount%1000=0 THEN 1 ELSE 0 END) OVER()*100.0/COUNT(*) OVER(),2),'%') AS flag_cnt
	FROM trans) finding_flag 
    WHERE flag_trans='Suspicious';