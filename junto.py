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
    "confirmed": "confirmed",
    "death": "death",
    "recovered": "recovered"
}

DATE_COLUMNS = ["ORDERDATE"]

dag = DAG('Junto', description='Dag to Unite Data into Junto',
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
    filepath = f"{FSHook('fs_default').get_path()}/time_series_covid19_confirmed_global.csv"
    source = MySqlHook('mydb').get_sqlalchemy_engine()
    df_c = (pd.read_csv(filepath)
          #.rename(columns=COLUMNS)
          )
    nombres = list(df_c.columns)
    fechas = nombres[5:len(nombres)]
    df_c = pd.melt(df_c, id_vars=nombres[0:4], value_vars=fechas, var_name="fecha")
    df_c.columns = ['province', 'country', 'lat', 'lng', 'fecha', 'valor']
    df_c['fecha'] = pd.to_datetime(df_c['fecha'])


    filepath = f"{FSHook('fs_default').get_path()}/time_series_covid19_deaths_global.csv"
    source = MySqlHook('mydb').get_sqlalchemy_engine()
    df_d = (pd.read_csv(filepath)
            # .rename(columns=COLUMNS)
            )
    nombres = list(df_d.columns)
    fechas = nombres[5:len(nombres)]
    df_d = pd.melt(df_d, id_vars=nombres[0:4], value_vars=fechas, var_name="fecha")
    df_d.columns = ['province', 'country', 'lat', 'lng', 'fecha', 'valor']
    df_d['fecha'] = pd.to_datetime(df_d['fecha'])


    filepath = f"{FSHook('fs_default').get_path()}/time_series_covid19_recovered_global.csv"
    source = MySqlHook('mydb').get_sqlalchemy_engine()
    df_r = (pd.read_csv(filepath)
            # .rename(columns=COLUMNS)
            )
    nombres = list(df_r.columns)
    fechas = nombres[5:len(nombres)]
    df_r = pd.melt(df_r, id_vars=nombres[0:4], value_vars=fechas, var_name="fecha")
    df_r.columns = ['province', 'country', 'lat', 'lng', 'fecha', 'valor']
    df_r['fecha'] = pd.to_datetime(df_r['fecha'])


    junto = pd.concat([df_c, df_d["valor"], df_r["valor"]], axis=1)
    junto.columns = ['province', 'country', 'lat', 'long', 'fecha', 'confirmed', 'deaths', 'recovered']
    junto


    with source.begin() as connection:
        junto.to_sql('junto', schema='test', con=connection, if_exists='append',chunksize=2500, index=False)


f4 = PythonOperator(
    task_id='inicio_dag',
    dag=dag,
    python_callable=process_func,
    provide_context=True,
    op_kwargs={
    }
)

sensor_task4 = FileSensor(task_id="check_junto_file",
                         dag=dag,
                         poke_interval=10,
                         fs_conn_id="fs_default",
                         filepath="time_series_covid19_confirmed_global.csv",
                         timeout=100)

process_file_operator4 = PythonOperator(
    task_id='process_file_operator',
    dag=dag,
    python_callable=process_file,
    provide_context=True,
    op_kwargs={
    }
)

f4 >> sensor_task4 >> process_file_operator4
