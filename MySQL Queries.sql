-- Walmart Project Business Questions & Solutions (MySQL)

-- Q1: Analyze Payment Methods and Sales
-- What are the different payment methods, and how many transactions and items were sold with each method?
SELECT 
    payment_method,
    COUNT(*) AS no_payments,
    SUM(quantity) AS no_qty_sold
FROM walmart
GROUP BY payment_method;

-- Q2: Identify the Highest-Rated Category in Each Branch
-- Which category received the highest average rating in each branch?
SELECT branch, category, avg_rating
FROM (
    SELECT 
        branch,
        category,
        AVG(rating) AS avg_rating,
        RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) AS rank
    FROM walmart
    GROUP BY branch, category
) AS ranked
WHERE rank = 1;

-- Q3: Determine the Busiest Day for Each Branch
-- What is the busiest day of the week for each branch based on transaction volume?
SELECT branch, day_name, no_transactions
FROM (
    SELECT 
        branch,
        DAYNAME(STR_TO_DATE(date, '%d/%m/%Y')) AS day_name,
        COUNT(*) AS no_transactions,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
    FROM walmart
    GROUP BY branch, day_name
) AS ranked
WHERE rank = 1;

-- Q4: Calculate Total Quantity Sold by Payment Method
-- How many items were sold through each payment method?
SELECT 
    payment_method,
    SUM(quantity) AS no_qty_sold
FROM walmart
GROUP BY payment_method;

-- Q5: Analyze Category Ratings by City
-- What are the average, minimum, and maximum ratings for each category in each city?
SELECT 
    city,
    category,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    AVG(rating) AS avg_rating
FROM walmart
GROUP BY city, category;

-- Q6: Calculate Total Profit by Category
-- What is the total profit for each category, ranked from highest to lowest?
SELECT 
    category,
    SUM(unit_price * quantity * profit_margin) AS total_profit
FROM walmart
GROUP BY category
ORDER BY total_profit DESC;

-- Q7: Determine the Most Common Payment Method per Branch
-- What is the most frequently used payment method in each branch?
WITH cte AS (
    SELECT 
        branch,
        payment_method,
        COUNT(*) AS total_trans,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
    FROM walmart
    GROUP BY branch, payment_method
)
SELECT branch, payment_method AS preferred_payment_method
FROM cte
WHERE rank = 1;

-- Q8: Analyze Sales Shifts Throughout the Day
-- How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
SELECT
    branch,
    CASE 
        WHEN HOUR(TIME(time)) < 12 THEN 'Morning'
        WHEN HOUR(TIME(time)) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    COUNT(*) AS num_invoices
FROM walmart
GROUP BY branch, shift
ORDER BY branch, num_invoices DESC;

-- Q9: Identify Branches with Highest Revenue Decline Year-Over-Year
-- Which branches experienced the largest decrease in revenue compared to the previous year?
-- Note: Robust version that handles missing 'branch' column and date format variations
SELECT 
    location,
    last_year_revenue,
    current_year_revenue,
    ROUND(((last_year_revenue - current_year_revenue) / last_year_revenue) * 100, 2) AS revenue_decrease_ratio
FROM (
    SELECT 
        r2022.location_id AS location,
        r2022.revenue AS last_year_revenue,
        r2023.revenue AS current_year_revenue
    FROM (
        SELECT 
            COALESCE(branch, city, 'Unknown') AS location_id,
            SUM(total) AS revenue
        FROM walmart
        WHERE date REGEXP '2022|/22$'
        GROUP BY COALESCE(branch, city, 'Unknown')
        HAVING SUM(total) > 0
    ) r2022
    INNER JOIN (
        SELECT 
            COALESCE(branch, city, 'Unknown') AS location_id,
            SUM(total) AS revenue
        FROM walmart
        WHERE date REGEXP '2023|/23$'
        GROUP BY COALESCE(branch, city, 'Unknown')
        HAVING SUM(total) > 0
    ) r2023 ON r2022.location_id = r2023.location_id
    WHERE r2022.revenue > r2023.revenue
) decline_analysis
ORDER BY revenue_decrease_ratio DESC
LIMIT 5;

-- End of Business Questions & Solutions
