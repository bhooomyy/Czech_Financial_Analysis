-- Rank districts by total loan amount disbursed. Overlay with district population to get loans-per-capita
SELECT 
d.district_id,
d.population,
Round(SUM(l.amount)/d.population,2) AS loan_per_capita,
SUM(amount) as total_fund_by_dist,
RANK() OVER(ORDER BY SUM(amount) DESC) AS rnk
FROM district d JOIN account a ON d.district_id=a.district_id JOIN loan l ON a.account_id=l.account_id
GROUP BY district_id,d.population;

-- Which districts have the highest average salary (A11) AND lowest default rates? (intersection of prosperity + repayment)
SELECT
	d.district_id,
    d.district_name,
    d.avg_salary,
    COUNT(l.loan_id) as total_loan_cnt,
	SUM(CASE WHEN l.status IN ('B','D') THEN 1 ELSE 0 END) as default_status_cnt,
    SUM(CASE WHEN l.status IN ('B','D') THEN 1 ELSE 0 END)*100.0/COUNT(*) as default_rate,
    RANK() OVER(ORDER BY avg_salary DESC) as rnk_salary,
    RANK() OVER(ORDER BY SUM(CASE WHEN l.status IN ('B','D') THEN 1 ELSE 0 END)*100.0/COUNT(*) ASC) rnk_default_rate
    FROM district d JOIN account a ON d.district_id=a.district_id JOIN loan l ON a.account_id=l.account_id
	GROUP BY d.district_id,d.district_name,d.avg_salary
    ORDER BY avg_salary DESC,default_rate ASC;

-- Correlation proxy: group districts into high/low unemployment (median split) and compare default rates between groups
WITH dist_defaults AS(SELECT
	d.district_id,
    unemployment_rate_96,
    COUNT(*) AS total_loan,
    COUNT(*) OVER() tot_dist,
	RANK() OVER(ORDER BY unemployment_rate_96) as rnk,
    SUM(CASE WHEN l.status IN ('B','D') THEN 1 ELSE 0 END) as default_cnt,
    CONCAT(ROUND(SUM(CASE WHEN l.status IN ('B','D') THEN 1 ELSE 0 END)*100.0/COUNT(*),2),'%') AS default_rate
	FROM  district d JOIN account a ON d.district_id=a.district_id JOIN loan l ON a.account_id=l.account_id
    GROUP BY d.district_id,unemployment_rate_96),
median_salary AS(
    SELECT 
    AVG(unemployment_rate_96) as median_sal
    FROM dist_defaults
    WHERE rnk IN (FLOOR(tot_dist+1)/2,CEIL(tot_dist+1)/2))
SELECT
    dd.district_id,
    dd.unemployment_rate_96,
    dd.total_loan,
    dd.default_rate,
    CASE WHEN unemployment_rate_96>ms.median_sal THEN 'High_unemplyment' ELSE 'Low_unemployment' END as emp_split
    FROM dist_defaults dd CROSS JOIN median_salary ms;

-- Build a district scorecard: for each district calculate total_clients, total_loan_amount, default_rate, avg_account_balance, avg_client_age. Use RANK() on each metric
WITH scorecard AS (
    SELECT
        d.district_id,
        d.district_name,
        COUNT(DISTINCT c.client_id) AS tot_clients,
        ROUND(SUM(l.amount), 2) AS tot_loan_amt,
        ROUND(SUM(CASE WHEN l.status IN ('B','D') THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT l.loan_id), 2) AS default_rate,
        ROUND(AVG(t.balance), 2) AS avg_acc_balance,
        ROUND(AVG(TIMESTAMPDIFF(YEAR, c.dateofbirth, CURDATE())), 2) AS avg_client_age
    FROM district d
    JOIN client c ON d.district_id = c.district_id
    JOIN disp dp ON c.client_id = dp.client_id AND dp.`type` = 'OWNER'
    JOIN account a ON dp.account_id = a.account_id
    JOIN loan l ON a.account_id = l.account_id
    JOIN trans t ON a.account_id = t.account_id
    GROUP BY d.district_id, d.district_name
)
SELECT
    district_id,
    district_name,
    tot_clients,
    tot_loan_amt,
    CONCAT(default_rate, '%') AS default_rate,
    avg_acc_balance,
    avg_client_age,
    RANK() OVER(ORDER BY tot_clients DESC) AS client_rank,
    RANK() OVER(ORDER BY tot_loan_amt DESC) AS loan_rank,
    RANK() OVER(ORDER BY default_rate ASC) AS default_rank,
    RANK() OVER(ORDER BY avg_acc_balance DESC) AS balance_rank,
    RANK() OVER(ORDER BY avg_client_age ASC) AS age_rank
FROM scorecard
ORDER BY client_rank;


-- Year-over-year account opening growth rate by district — which districts are growing fastest? Use LAG on yearly counts
WITH tot_data AS(SELECT
	d.district_id,
    d.district_name,
    YEAR(a.date) as year,
    COUNT(DISTINCT a.account_id) as tot_acc
	FROM account a JOIN district d ON a.district_id=d.district_id
    GROUP BY d.district_id,year,d.district_name),
prev_yr_data AS(SELECT 
    district_id,
    district_name,
    year,
    tot_acc,
    LAG(tot_acc) OVER(PARTITION BY district_id ORDER BY year) as prev_year_tot_acc
    FROM tot_data)
SELECT 
    district_id,
    district_name,
    year,
    tot_acc,
    ROUND((tot_acc-prev_year_tot_acc)*1.0/prev_year_tot_acc,2) as growth_rate,
    RANK() OVER(ORDER BY ROUND((tot_acc-prev_year_tot_acc)*100.0/prev_year_tot_acc,2) DESC) as growth_rnk
    FROM prev_yr_data
    WHERE prev_year_tot_acc IS NOT NULL
    ORDER BY growth_rnk,year;