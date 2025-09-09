/*
Считаем общее количество покупателей
из таблицы customers
*/

select COUNT(*) as customers_count
from customers;

/*
 Считаем 10 лучших продавцов
 по суммарной выручке
*/

select e.first_name || ' ' || coalesce(e.middle_initial || ' ', '') || e.last_name as seller, -- учитываем случаи, когда middle_initial имеет значение NULL 
	   count(*) as operations,
	   floor(sum(p.price * s.quantity)) as income
from sales s
join products p using (product_id)
join employees e on s.sales_person_id = e.employee_id
group by seller
order by income desc
limit 10;
