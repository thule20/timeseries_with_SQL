----------- SQL PRACTICE WITH DATE functions & WINDOW FUNCTIONs -----------

--==================================================================================--
-- Case study: TIME SERIES ANALYSIS applying to Paytm database
-- Credit to: @Mazhocdata https://madzynguyen.com/khoa-hoc-practical-sql-for-data-analytics/ for Database provider & How to apply SQL in real problems
--==================================================================================--

/* Database explaination
Paytm is an Indian multinational financial technology company. It specializes in digital payment systems, e-commerce and financial services.
Paytm wallet is a secure and RBI (Reserve Bank of India)-approved digital/mobile wallet that provides a myriad of financial features to fulfill every consumer’s payment needs.
Paytm wallet can be topped up through UPI (Unified Payments Interface), internet banking, or credit/debit cards.
Users can also transfer money from a Paytm wallet to the recipient's bank account or their own Paytm wallet. 
I have practiced on a small database of payment transactions from 2019 to 2020 of Paytm Wallet. The database includes 6 tables: 
●	fact_transaction: Store information of all types of transactions: Payments, Top-up, Transfers, Withdrawals, with the list of columns: transaction_id, customer_id, scenario_id, payment_channel_id, promotion_id
, platform_id, status_id, original_price, discount_value, charged_amount, transaction_time
●	dim_scenario: Detailed description of transaction types, with columns: scenario_id, transaction_type, sub_category, category
●	dim_payment_channel: Detailed description of payment methods, including columns: payment_channel_id, payment_method
●	dim_platform: Detailed description of payment devices, with columns: playform_id, payment_platform
●	dim_status: Detailed description of the results of the transaction: status_id, status_description
*/

/* The visualisation dashboard of below SQL queries is published here: https://community.fabric.microsoft.com/t5/Data-Stories-Gallery/Paytm-Practice-Time-Series-Analysis-with-SQL-amp-Power-BI/td-p/3693063 */


------==== Page 1: OVERVIEW TRENDs ====------

/*
Calculate the number of successful transactions of each month in 2019 and 2020 and the successful transaction rate (success_rate) of each month comparing to its year.
*/
SELECT DISTINCT YEAR(fact_table.transaction_time) AS [year]
    , MONTH(fact_table.transaction_time) AS [month]
    , COUNT(transaction_id) OVER(PARTITION BY YEAR(transaction_time), MONTH(transaction_time)) as monthly_trans
    , COUNT(transaction_id) OVER(PARTITION BY YEAR(transaction_time)) as yearly_trans
    , CAST(ROUND((COUNT(transaction_id) OVER(PARTITION BY YEAR(transaction_time), MONTH(transaction_time))) *1.0 / 
        (COUNT(transaction_id) OVER(PARTITION BY YEAR(transaction_time))),3) AS DECIMAL(18,3)) AS success_rate
FROM (
    SELECT *
    FROM fact_transaction_2019
    UNION
    SELECT *
    FROM fact_transaction_2020
) as fact_table
JOIN dim_status AS stt
    ON fact_table.status_id = stt.status_id
WHERE stt.status_description = 'Success'
ORDER BY [year], [month]
;

-->> It can be seen that the number of transactions is increased in quarter 4 of each year, and especially surged in Q4 of 2020.

/* TOP 3 months with the most failed transactions rate of each year */
WITH count_table AS (
    SELECT DISTINCT YEAR(fact_table.transaction_time) AS [year]
        , MONTH(fact_table.transaction_time) AS [month]
        , COUNT(transaction_id) OVER(PARTITION BY YEAR(transaction_time), MONTH(transaction_time)) as monthly_trans
        , COUNT(transaction_id) OVER(PARTITION BY YEAR(transaction_time)) as yearly_trans
        , CAST(ROUND((COUNT(transaction_id) OVER(PARTITION BY YEAR(transaction_time), MONTH(transaction_time))) *1.0 / 
            (COUNT(transaction_id) OVER(PARTITION BY YEAR(transaction_time))),3) AS DECIMAL(18,3)) AS failed_rate
    FROM (
        SELECT *
        FROM fact_transaction_2019
        UNION
        SELECT *
        FROM fact_transaction_2020
    ) as fact_table
    JOIN dim_status AS stt
        ON fact_table.status_id = stt.status_id
    WHERE stt.status_description <> 'Success'
)
, rank_table AS (
    SELECT *
        , RANK() OVER(PARTITION BY [year] ORDER BY failed_rate DESC) as ranking
    FROM count_table
)
SELECT *
FROM rank_table
WHERE ranking <= 3
ORDER BY [year], ranking
;

-->> It is clear to understand that the failure rate is high in months 10, 11, and 12.
--   However, the number of failed transactions in October 2020 is not among the top three, whereas the number of successful transactions ranks third.
-->> We have to check the proportion of success and failure of each month

/* The proportion of success and failture rate each month */
WITH count_table AS (
    SELECT transaction_id
        , YEAR(fact_table.transaction_time) AS [year]
        , MONTH(fact_table.transaction_time) AS [month]
        , IIF(stt.status_description = 'Success', transaction_id, NULL) as success_trans_id
        , IIF(stt.status_description <> 'Success', transaction_id, NULL) as failed_trans_id
    FROM (
        SELECT *
        FROM fact_transaction_2019
        UNION
        SELECT *
        FROM fact_transaction_2020
    ) as fact_table
    JOIN dim_status AS stt
        ON fact_table.status_id = stt.status_id
)
SELECT [year]
    , [month]
    , COUNT(success_trans_id) AS num_of_success_trans
    , COUNT(failed_trans_id) AS num_of_failed_trans
FROM count_table
GROUP BY [year], [month]
ORDER BY [year], [month]
;

-->> It can be seen that the failure rate has been decreased after 2 years while the total transactions has been increased.


------==== Page 12: OVERVIEW TRENDs ====------

/* How did the number of success transactions break down for each category, which one contributed most? */
SELECT DISTINCT sce.category
    , YEAR(transaction_time) AS [year]
    , MONTH(transaction_time) AS [month]
    , COUNT(transaction_id) OVER (PARTITION BY YEAR(transaction_time), MONTH(transaction_time), sce.category) as num_trans_by_cat
FROM (
    SELECT * FROM fact_transaction_2019
    UNION
    SELECT * FROM fact_transaction_2020
) as fact_table
JOIN dim_scenario AS sce 
    ON fact_table.scenario_id = sce.scenario_id
JOIN dim_status AS stt 
    ON fact_table.status_id = stt.status_id
WHERE stt.status_description = 'Success'
ORDER BY sce.category, [year], [month]
;

-->> After visualizing the results, we can see that the category 'Shopping' surged strongly for 2 years. Therefore, we will analyze its details.
--  There are many subcategories within the 'Shopping' group. After reviewing the above results, I will break down the trend into each subcategory.

/* Break down the above result of Shopping category into sub-categories */
WITH count_table_shopping AS (
    SELECT DISTINCT sce.sub_category
        , YEAR(transaction_time) AS [year]
        , MONTH(transaction_time) AS [month]
        , COUNT(transaction_id) OVER (PARTITION BY YEAR(transaction_time), MONTH(transaction_time), sce.sub_category) AS num_trans_by_subcat
        , COUNT(transaction_id) OVER (PARTITION BY YEAR(transaction_time), MONTH(transaction_time)) AS monthly_trans_of_shopping
    FROM (
        SELECT * FROM fact_transaction_2019
        UNION
        SELECT * FROM fact_transaction_2020
    ) as fact_table
    JOIN dim_scenario AS sce 
        ON fact_table.scenario_id = sce.scenario_id
    JOIN dim_status AS stt 
        ON fact_table.status_id = stt.status_id
    WHERE stt.status_description = 'Success' AND sce.category = 'Shopping'
)
SELECT * 
    , FORMAT(num_trans_by_subcat * 1.0 / monthly_trans_of_shopping, 'p') as proportion_pct
FROM count_table_shopping
ORDER BY sub_category, [year], [month]
;

-->> We can see that Shopping Stores contributed the most (over 99%).
--  However, when the Convenience Store started accepting Paytm from December 2019, its contribution became the second highest (around 7-10%).
--  This suggests that the Convenience Store category has the potential for further growth as it has shown a continuous increase.

/* Analyse trend Convenience Store every week to see whether it has been continuously increased */
WITH count_table_convenience AS (
    SELECT DISTINCT DATEPART(week, transaction_time) AS [week]
        , YEAR(transaction_time) AS [year]
        , COUNT(transaction_id) OVER (PARTITION BY YEAR(transaction_time), DATEPART(week, transaction_time)) AS weekly_trans
    FROM (
        SELECT * FROM fact_transaction_2019
        UNION
        SELECT * FROM fact_transaction_2020
    ) as fact_table
    JOIN dim_scenario AS sce 
        ON fact_table.scenario_id = sce.scenario_id
    JOIN dim_status AS stt 
        ON fact_table.status_id = stt.status_id
    WHERE stt.status_description = 'Success' AND sce.sub_category = 'Convenience Store'
)
SELECT *
, AVG (weekly_trans) OVER ( ORDER BY [year], [week] ROWS BETWEEN 3 PRECEDING AND CURRENT ROW ) AS avg_last_4_weeks
FROM count_table_convenience
ORDER BY [year], [week]
;

-->> Overall, the trend has been increasing. However, the trend fluctuates every 4 weeks.
--  Therefore, we need to check the gap between successful payments of customers in this subcategory and other promotional campaign periods during this time.

/* Calculate the average gap between 2 successful payments of customers */
WITH customer_table AS (
    SELECT customer_id
        , transaction_id
        , transaction_time
        , LAG (transaction_time, 1) OVER ( PARTITION BY customer_id ORDER BY transaction_time) AS previous_time
    FROM (
        SELECT * FROM fact_transaction_2019
        UNION
        SELECT * FROM fact_transaction_2020
    ) AS fact_table
    JOIN dim_scenario sce
        ON fact_table.scenario_id = sce.scenario_id
    JOIN dim_status stt 
        ON fact_table.status_id = stt.status_id
    WHERE sce.sub_category = 'Convenience Store' AND stt.status_description = 'Success'
)
, count_gap AS (
    SELECT customer_id
    , transaction_id
    , transaction_time
    , DATEDIFF (day, previous_time, transaction_time ) AS gap_day
    FROM customer_table
)
SELECT customer_id
    , AVG(gap_day) as avg_gap
FROM count_gap
WHERE DATEPART(week, transaction_time) >= 31 and YEAR(transaction_time) = 2020
GROUP BY customer_id
ORDER BY avg_gap DESC
;

-->> We can see that the majority of customers have a gap of 0 to 50 days, which does not seem to correlate significantly with the fluctuating trend mentioned above.
-- Therefore, we need to collect more data to discover the reason.



