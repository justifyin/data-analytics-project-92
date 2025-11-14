/* Общее количество покупателей */
SELECT COUNT(*) AS customers_count
FROM customers;

/* 10 лучших продавцов по суммарной выручке */
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    COUNT(*) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income  -- сумма продаж без дробной части
FROM sales AS s
INNER JOIN products AS p
    ON s.product_id = p.product_id
INNER JOIN employees AS e
    ON s.sales_person_id = e.employee_id
GROUP BY e.first_name, e.last_name
ORDER BY income DESC
LIMIT 10;


/* Продавцы с выручкой ниже средней */
SELECT
    seller,
    FLOOR(avg_income) AS average_income
FROM (
    SELECT
        e.first_name || ' ' || e.last_name AS seller,
        AVG(p.price * s.quantity) AS avg_income,
        AVG(AVG(p.price * s.quantity)) OVER () AS global_avg -- среднее по всем продавцам
    FROM
        employees AS e
    INNER JOIN sales AS s
        ON e.employee_id = s.sales_person_id
    INNER JOIN products AS p
        ON s.product_id = p.product_id
    GROUP BY
        e.employee_id,
        e.first_name,
        e.last_name
) AS t
WHERE
    avg_income < global_avg
ORDER BY
    avg_income;

/* Выручка по дням недели для каждого продавца */
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    TO_CHAR(s.sale_date, 'FMday') AS day_of_week,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM employees AS e
INNER JOIN sales AS s
    ON e.employee_id = s.sales_person_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    e.first_name, e.middle_initial, e.last_name,
    TO_CHAR(s.sale_date, 'FMday'),
    EXTRACT(ISODOW FROM s.sale_date) -- день недели для правильного порядка
ORDER BY
    EXTRACT(ISODOW FROM s.sale_date),
    seller;

/* Количество покупателей по возрастным категориям */
SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_category,
    COUNT(*) AS age_count
FROM customers
GROUP BY age_category
ORDER BY age_category;

/* Количество уникальных покупателей и выручка по месяцам */
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY selling_month
ORDER BY selling_month;

/* Покупатели, чья первая покупка была акционной (цена = 0) */
WITH ranked_sales AS (
    SELECT
        s.customer_id,
        s.product_id,
        s.sale_date,
        s.sales_person_id,
        c.first_name || ' ' || c.last_name AS customer,
        e.first_name || ' ' || e.last_name AS seller,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.sale_date
        ) AS rn -- нумерация покупок для каждого клиента
    FROM sales AS s
    INNER JOIN customers AS c
        ON s.customer_id = c.customer_id
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
)

SELECT
    rs.customer,
    rs.sale_date,
    rs.seller
FROM ranked_sales AS rs
INNER JOIN products AS p
    ON rs.product_id = p.product_id
WHERE
    rs.rn = 1  -- только первая покупка
    AND p.price = 0  -- только акционные товары
ORDER BY rs.customer_id;
