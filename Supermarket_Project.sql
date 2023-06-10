CREATE DATABASE supermarket;

USE supermarket;

CREATE TABLE aisles(
id INT,
aisle VARCHAR(100) NOT NULL,
PRIMARY KEY(id)
);

CREATE TABLE departments(
id int,
department VARCHAR(30) NOT NULL,
PRIMARY KEY(id)
);

CREATE TABLE product(
id INT,
name VARCHAR(200) NOT NULL,
aisle_id INT NOT NULL,
department_id INT NOT NULL,
PRIMARY KEY(id),
FOREIGN KEY(aisle_id)
REFERENCES aisles(id)
ON DELETE NO ACTION
ON UPDATE CASCADE,    
FOREIGN KEY(department_id)
REFERENCES departments(id)
ON DELETE NO ACTION
ON UPDATE CASCADE
);

CREATE TABLE orders(
id INT,
user_id INT NOT NULL,
eval_set VARCHAR(10) NOT NULL,
order_number INT NOT NULL,
order_dow INT,
order_hour_of_day INT,
days_since_prior_order INT,
PRIMARY KEY(id)
);

CREATE TABLE order_product(
order_id INT NOT NULL,
product_id INT NOT NULL,
add_to_cart_order INT NOT NULL,
reordered INT NOT NULL,
FOREIGN KEY(order_id)
REFERENCES orders(id)
ON DELETE NO ACTION
ON UPDATE CASCADE,    
FOREIGN KEY(product_id)
REFERENCES product(id)
ON DELETE NO ACTION
ON UPDATE CASCADE
);


BULK INSERT [aisles]
FROM 'C:\Users\ektaj\Downloads\aisles.csv'
WITH (
    FIELDTERMINATOR = ',',
    FIRSTROW = 0,
    ROWTERMINATOR = '\n')
	
GO


BULK INSERT [departments]
FROM 'C:\Users\ektaj\Downloads\departments.csv'
WITH (
    FIELDTERMINATOR = ',',
    FIRSTROW = 0,
    ROWTERMINATOR = '\n')
	
GO


BULK INSERT [orders]
FROM 'C:\Users\ektaj\Downloads\orders_small_version.csv'
WITH (
    FIELDTERMINATOR = ',',
    FIRSTROW = 0,
    ROWTERMINATOR = '\n')
	
GO


BULK INSERT [product]
FROM 'C:\Users\ektaj\Downloads\products.csv'
WITH (
    FIELDTERMINATOR = ',',
    FIRSTROW = 0,
    ROWTERMINATOR = '\n')
	
GO


BULK INSERT [order_product]
FROM 'C:\Users\ektaj\Downloads\order_products.csv'
WITH (
    FIELDTERMINATOR = ',',
    FIRSTROW = 0,
    ROWTERMINATOR = '\n')
	
GO


select * from aisles
select * from departments
select * from order_product
select * from orders
select * from product


### Top 10 Products Sales For Each Day of the Week

with ranked_data AS (
    SELECT day, id, name, total_amount,
        ROW_NUMBER() OVER (PARTITION BY day ORDER BY total_amount DESC) AS rank1
    FROM (
        SELECT p.id, p.name, COUNT(*) AS total_amount, o.order_dow AS day
        FROM product AS p
        INNER JOIN order_product AS op ON op.product_id = p.id
        INNER JOIN orders AS o ON op.order_id = o.id
        WHERE o.order_dow BETWEEN 1 AND 5
        GROUP BY p.id, p.name, o.order_dow
    ) AS t1
)
SELECT day, id, name, total_amount
FROM ranked_data
WHERE rank1 <= 10;

### 5 most popular products in each aisle from Monday to Friday

WITH ranked_data AS (
    SELECT aisle, day, id AS product_id,
        ROW_NUMBER() OVER (PARTITION BY aisle, day ORDER BY total_amount DESC) AS rank1
    FROM (
        SELECT p.id, a.aisle, COUNT(*) AS total_amount, o.order_dow AS day
        FROM product AS p
        INNER JOIN order_product AS op ON op.product_id = p.id
        INNER JOIN orders AS o ON op.order_id = o.id
        INNER JOIN aisles AS a ON p.aisle_id = a.id
        WHERE o.order_dow BETWEEN 1 AND 5
        GROUP BY p.id, a.aisle, o.order_dow
    ) AS t1
)
SELECT aisle, day, product_id
FROM ranked_data
WHERE rank1 <= 5


### top 10 products that the users have the most frequent reorder rate

SELECT product_id
FROM order_product
GROUP BY product_id
ORDER BY sum(reordered)/count(*) DESC
LIMIT 10;


### shopper’s aisle list for each order

SELECT op.order_id, a.id as aisle_id
FROM order_product AS op
INNER JOIN aisles AS a ON op.product_id=a.id
GROUP BY op.order_id, a.id;


### most popular shopping path

WITH aisle_counts AS (
    SELECT order_id, GROUP_CONCAT(DISTINCT a.id ORDER BY a.id SEPARATOR ' ') AS aisles
    FROM order_product AS op
    INNER JOIN product AS p ON op.product_id = p.id
    INNER JOIN aisles AS a ON p.aisle_id = a.id
    GROUP BY order_id
    HAVING COUNT(DISTINCT a.id) >= 2
)
SELECT aisles, COUNT(*) AS count
FROM aisle_counts
GROUP BY aisles
ORDER BY count DESC;


###  top pairwise associations in products


WITH product_counts AS (
    SELECT op1.product_id AS product1, op2.product_id AS product2, COUNT(*) AS count
    FROM order_product AS op1
    INNER JOIN order_product AS op2 ON op1.order_id = op2.order_id
    WHERE op1.product_id < op2.product_id
    GROUP BY op1.product_id, op2.product_id
    ORDER BY count DESC
    LIMIT 100
)
SELECT p1.name AS product1, p2.name AS product2
FROM product_counts
INNER JOIN product AS p1 ON product_counts.product1 = p1.id
INNER JOIN product AS p2 ON product_counts.product2 = p2.id;


