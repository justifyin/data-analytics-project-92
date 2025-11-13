/* Считаем общее количество покупателей из таблицы customers */
SELECT COUNT(*) AS customers_count
FROM customers;

/* Считаем 10 лучших продавцов по суммарной выручке */
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    COUNT(*) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income  -- отбрасываем дробную часть
FROM sales AS s
JOIN products AS p
    ON s.product_id = p.product_id
JOIN employees AS e
    ON s.sales_person_id = e.employee_id
GROUP BY e.first_name, e.last_name
ORDER BY income DESC
LIMIT 10;


/*
Выводим информацию о продавцах, чья выручка за сделку
меньше средней выручки по всем продавцам
*/
WITH average_incomes AS (
    SELECT
        e.first_name || ' ' || e.last_name AS seller,
        AVG(p.price * s.quantity) AS average_income
    FROM employees AS e
    JOIN sales AS s
        ON s.sales_person_id = e.employee_id
    JOIN products AS p
        ON s.product_id = p.product_id
    GROUP BY e.first_name, e.middle_initial, e.last_name
)

SELECT
    seller,
    FLOOR(average_income) AS average_income  -- отбрасываем дробную часть
FROM average_incomes
WHERE average_income < (SELECT AVG(average_income) FROM average_incomes)
ORDER BY average_income;

/* Выводим информацию о выручке по дням недели. */
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    TO_CHAR(s.sale_date, 'FMday') AS day_of_week,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM employees AS e
JOIN sales AS s
    ON s.sales_person_id = e.employee_id
JOIN products AS p
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
WITH customers_age AS (
    SELECT DISTINCT ON (c.customer_id)
        c.customer_id,
        c.age
    FROM customers AS c
)

SELECT
    CASE
        WHEN c.age BETWEEN 16 AND 25 THEN '16-25'
        WHEN c.age BETWEEN 26 AND 40 THEN '26-40'
        WHEN c.age > 40 THEN '40+'
    END AS age_category,
    COUNT(*) AS age_count
FROM customers_age AS c
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
JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY selling_month
ORDER BY selling_month;

/*
Выводим покупателей, первая покупка которых
была в ходе проведения акций
(акционные товары отпускали со стоимостью равной 0).
*/

WITH first_purchase_discounted AS (
    SELECT DISTINCT ON (s.customer_id)
        s.customer_id,
        s.sale_date,
        s.sales_person_id
    FROM sales AS s
    JOIN products AS p
        ON s.product_id = p.product_id
    WHERE p.price = 0
    ORDER BY s.customer_id, s.sale_date
)

SELECT
    c.first_name || ' ' || c.last_name AS customer,
    fpd.sale_date,
    e.first_name || ' ' || e.last_name AS seller
FROM first_purchase_discounted AS fpd
JOIN customers AS c
    ON c.customer_id = fpd.customer_id
JOIN employees AS e
    ON e.employee_id = fpd.sales_person_id
ORDER BY fpd.customer_id;
