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

select e.first_name || ' ' || coalesce(e.middle_initial || ' ', '') || e.last_name as seller,
	   -- учитываем случаи, когда middle_initial имеет значение NULL 
	   count(*) as operations,
	   floor(sum(p.price * s.quantity)) as income
from sales s
join products p using (product_id)
join employees e on s.sales_person_id = e.employee_id
group by seller
order by income desc
limit 10;

/*
Выводим информацию о продавцах,
чья выручка за сделку меньше
средней выручки за сделку
по всем продавцам
*/

with average_incomes as (
    select e.first_name || ' ' || coalesce(e.middle_initial || ' ', '') || e.last_name as seller,
           -- учитываем случаи, когда middle_initial имеет значение NULL
		   coalesce(avg(p.price * s.quantity), 0) as average_income
		   -- учитываем случаи, когда продавец не совершил ни одной сделки
    from employees e
    left join sales s on s.sales_person_id = e.employee_id
    left join products p on s.product_id = p.product_id
    group by e.first_name, e.middle_initial, e.last_name
)
select seller,
       floor(average_income) as average_income
from average_incomes
where average_income < (select avg(average_income) from average_incomes)
order by average_income;
