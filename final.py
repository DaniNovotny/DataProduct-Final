import pandas as pd
from airflow import DAG
from airflow.contrib.hooks.fs_hook import FSHook
from airflow.contrib.sensors.file_sensor import FileSensor
from airflow.hooks.mysql_hook import MySqlHook
from airflow.operators.python_operator import PythonOperator
from airflow.utils.dates import days_ago

COLUMNS = {
    "ORDERNUMBER": "order_number",
    "QUANTITYORDERED": "quantity_ordered",
    "PRICEEACH": "price_each",
    "ORDERLINENUMBER": "order_line_number",
    "SALES": "sales",
    "ORDERDATE": "order_date",
    "STATUS": "status",
    "QTR_ID": "qtr_id",
    "MONTH_ID": "month_id",
    "YEAR_ID": "year_id",
    "PRODUCTLINE": "product_line",
    "MSRP": "msrp",
    "PRODUCTCODE": "product_code",
    "CUSTOMERNAME": "customer_name",
    "PHONE": "phone",
    "ADDRESSLINE1": "address_line_1",
    "ADDRESSLINE2": "address_line_2",
    "CITY": "city",
    "STATE": "state",
    "POSTALCODE": "postal_code",
    "COUNTRY": "country",
    "TERRITORY": "territory",
    "CONTACTLASTNAME": "contact_last_name",
    "CONTACTFIRSTNAME": "contact_first_name",
    "DEALSIZE": "deal_size"
}



DATE_COLUMNS = ["ORDERDATE"]

dag = DAG('FinalDagsSales', description='Dag to Ingest Sales',
          default_args={
              'owner': 'obed.espinoza',
              'depends_on_past': False,
              'max_active_runs': 1,
              'start_date': days_ago(5)
          },
          schedule_interval='0 1 * * *',
          catchup=False)


def process_func(**kwargs):
    execution_date = kwargs['execution_date']
    print(execution_date)

def process_file(**kwargs):
    filepath = f"{FSHook('fs_default').get_path()}/sales.csv"
    source = MySqlHook('mydb').get_sqlalchemy_engine()
    df = (pd.read_csv(filepath, encoding = "ISO-8859-1", usecols=COLUMNS.keys(), parse_dates=DATE_COLUMNS)
          .rename(columns=COLUMNS)
          )
    with source.begin() as connection:
        df.to_sql('sales', schema='test', con=connection, if_exists='append',chunksize=2500, index=False)

t1 = PythonOperator(
    task_id='inicio_dag',
    dag=dag,
    python_callable=process_func,
    provide_context=True,
    op_kwargs={
    }
)

sensor_task = FileSensor(task_id="check_sales_file",
                         dag=dag,
                         poke_interval=10,
                         fs_conn_id="fs_default",
                         filepath="sales.csv",
                         timeout=100)

process_file_operator = PythonOperator(
    task_id='process_file_operator',
    dag=dag,
    python_callable=process_file,
    provide_context=True,
    op_kwargs={
    }
)

t1 >> sensor_task >> process_file_operator