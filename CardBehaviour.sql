-- How many cards of each type (classic/junior/gold) exist? What % of all accounts have a card?
SELECT
	type,
	COUNT(*) as card_cnt,
    CONCAT(ROUND(COUNT(*)/(SELECT COUNT(*) FROM card),2),'%') AS card_perc
    FROM card 
    GROUP BY type;

-- Card issuance trend over time — how many cards were issued per year? (parse issued date)
SELECT
	YEAR(issued) as year,
	COUNT(*) as num_cards
	FROM card
	GROUP BY year;

-- Join card → disposition → client: what is the age and gender profile of gold card holders vs classic card holders?
SELECT 
    cd.type AS card_type,
    cl.gender,
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, cl.dateofbirth, CURDATE()) < 30 THEN '<30'
        WHEN TIMESTAMPDIFF(YEAR, cl.dateofbirth, CURDATE()) < 45 THEN '30-45'
        WHEN TIMESTAMPDIFF(YEAR, cl.dateofbirth, CURDATE()) < 60 THEN '45-60'
        ELSE '60+'
    END AS age_group,
    COUNT(*) AS total,
    ROUND(AVG(TIMESTAMPDIFF(YEAR, cl.dateofbirth, CURDATE())), 0) AS avg_age
FROM card cd 
JOIN disp d ON cd.disp_id = d.disp_id 
JOIN client cl ON cl.client_id = d.client_id
GROUP BY cd.type, cl.gender, age_group
HAVING type='gold' OR type='classic'
ORDER BY cd.type, cl.gender, age_group;

