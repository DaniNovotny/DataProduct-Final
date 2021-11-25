import pandas as pd
from airflow import DAG
from airflow.contrib.hooks.fs_hook import FSHook
from airflow.contrib.sensors.file_sensor import FileSensor
from airflow.hooks.mysql_hook import MySqlHook
from airflow.operators.python_operator import PythonOperator
from airflow.utils.dates import days_ago

COLUMNS = {
    "province": "province",
    "country": "country",
    "lat": "lat",
    "lng": "lng",
    "fecha": "fecha",
    "valor": "valor"
}

DATE_COLUMNS = ["ORDERDATE"]

dag = DAG('Deaths', description='Dag to Ingest Confirmed',
          default_args={
              'owner': 'LPLJDD',
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
    filepath = f"{FSHook('fs_default').get_path()}/time_series_covid19_deaths_global.csv"
    source = MySqlHook('mydb').get_sqlalchemy_engine()
    df = (pd.read_csv(filepath)
          #.rename(columns=COLUMNS)
          )
    nombres = list(df.columns)
    fechas = nombres[5:len(nombres)]
    df = pd.melt(df, id_vars=nombres[0:4], value_vars=fechas, var_name="fecha")
    df.columns = ['province', 'country', 'lat', 'lng', 'fecha', 'valor']
    df['fecha'] = pd.to_datetime(df['fecha'])

    with source.begin() as connection:
        df.to_sql('deaths', schema='test', con=connection, if_exists='append',chunksize=2500, index=False)


f2 = PythonOperator(
    task_id='inicio_dag',
    dag=dag,
    python_callable=process_func,
    provide_context=True,
    op_kwargs={
    }
)

sensor_task2 = FileSensor(task_id="check_deaths_file",
                         dag=dag,
                         poke_interval=10,
                         fs_conn_id="fs_default",
                         filepath="time_series_covid19_deaths_global.csv",
                         timeout=100)

process_file_operator2 = PythonOperator(
    task_id='process_file_operator',
    dag=dag,
    python_callable=process_file,
    provide_context=True,
    op_kwargs={
    }
)

f2 >> sensor_task2 >> process_file_operator2
