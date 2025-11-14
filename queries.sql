/* Считаем общее количество покупателей из таблицы customers */
SELECT COUNT(*) AS customers_count
FROM customers;

/* Считаем 10 лучших продавцов по суммарной выручке */
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    COUNT(*) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income  -- отбрасываем дробную часть
FROM sales AS s
INNER JOIN products AS p
    ON s.product_id = p.product_id
INNER JOIN employees AS e
    ON s.sales_person_id = e.employee_id
GROUP BY e.first_name, e.last_name
ORDER BY income DESC
LIMIT 10;


/*
Выводим информацию о продавцах, чья выручка за сделку
меньше средней выручки по всем продавцам
*/
SELECT
    seller,
    FLOOR(avg_income) AS average_income
FROM (
    SELECT
        e.first_name || ' ' || e.last_name AS seller,
        AVG(p.price * s.quantity) AS avg_income,
        AVG(AVG(p.price * s.quantity)) OVER () AS global_avg
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

/* Выводим информацию о выручке по дням недели. */
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
    EXTRACT(ISODOW FROM s.sale_date)
ORDER BY
    EXTRACT(ISODOW FROM s.sale_date),  -- monday = 1, sunday = 7
    seller;

/*
Выводим количество покупателей в разных
возрастных группах: 16-25, 26-40 и 40+.
*/
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

/*
Выводим данные по количеству уникальных
покупателей и выручке, которую они принесли.
*/
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY selling_month
ORDER BY selling_month;

/*
Выводим покупателей, первая покупка которых
была в ходе проведения акций
(акционные товары отпускали со стоимостью равной 0).
*/
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
        ) AS rn
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
    rs.rn = 1
    AND p.price = 0
ORDER BY rs.customer_id;
