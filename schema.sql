CREATE TABLE test.confirmed(
    province varchar(60),
    country varchar(60),
    lat float ,
    lng float ,
    fecha date,
    valor int
);

CREATE TABLE test.deaths(
    province varchar(60),
    country varchar(60),
    lat float ,
    lng float ,
    fecha date,
    valor int
);

CREATE TABLE test.consolidate_sales(
id int primary key auto_increment,
year_id int,
month_id int,
sales_amount decimal(20,2)
);