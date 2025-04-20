import subprocess
from datetime import datetime
import pandas as pd
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.mysql.hooks.mysql import MySqlHook
from airflow.hooks.base import BaseHook
from sqlalchemy import create_engine

default_args = {
    'owner': 'sofiia',
    'start_date': datetime(2025, 4, 18)
}



def extract_mysql_table_to_duckdb(table_name):
    def _inner(**kwargs):

        mysql_hook = MySqlHook(mysql_conn_id='localhost')
        df = mysql_hook.get_pandas_df(f"SELECT * FROM raw.{table_name}")

        duck_conn = BaseHook.get_connection('warehouse_duckdb')
        engine = create_engine(duck_conn.get_uri())
        df.to_sql(name=table_name, con=engine, if_exists='replace', index=False)

    return _inner


def load_seed(table_name: str, file_path: str, **kwargs):
    df = pd.read_csv(file_path)
    df.dropna(how='all', inplace=True)
    num_cols = df.select_dtypes(include='number').columns
    df[num_cols] = df[num_cols].fillna(0)
    str_cols = df.select_dtypes(include='object').columns
    df[str_cols] = df[str_cols].apply(lambda x: x.str.strip())
    for col in df.columns:
        if 'date' in col.lower():
            df[col] = pd.to_datetime(df[col], errors='coerce')
    df.drop_duplicates(inplace=True)
    df['ingested_at'] = datetime.utcnow()

    conn = BaseHook.get_connection('warehouse_duckdb')
    engine = create_engine(conn.get_uri())

    df.to_sql(
        name=table_name,
        con=engine,
        if_exists='replace',
        index=False
    )

def run_dbt_build():
    subprocess.run(
        ['dbt', 'build'],
        cwd='/usr/local/airflow/dbt_venv/bin/dbt',
        check=True
    )

with DAG(
    dag_id='etl_to_duckdb',
    schedule_interval=None,
    default_args=default_args,
    catchup=False
) as dag:

    extract_payments = PythonOperator(
        task_id='extract_payments',
        python_callable=extract_mysql_table_to_duckdb('payments')
    )
    extract_stock = PythonOperator(
        task_id='extract_stock',
        python_callable=extract_mysql_table_to_duckdb('stock')
    )

    load_products_seed = PythonOperator(
        task_id='load_products_seed',
        python_callable=load_seed,
        op_kwargs={
            'table_name': 'raw_products',
            'file_path': '/usr/local/airflow/include/raw_products.csv'
        }
    )

    load_customers_seed = PythonOperator(
        task_id='load_cusrtomers_seed',
        python_callable=load_seed,
        op_kwargs={
            'table_name': 'raw_customers',
            'file_path': '/usr/local/airflow/include/raw_customers.csv'
        }
    )

    load_orders_seed = PythonOperator(
        task_id='load_orders_seed',
        python_callable=load_seed,
        op_kwargs={
            'table_name': 'raw_orders',
            'file_path': '/usr/local/airflow/include/raw_orders.csv'
        }
    )

    run_dbt = PythonOperator(
        task_id='run_dbt',
        python_callable=run_dbt_build
    )

    extract_payments >> extract_stock >> [load_products_seed, load_customers_seed, load_orders_seed] >> run_dbt