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

