import pandas as pd
from airflow.providers.mysql.hooks.mysql import MySqlHook
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
import subprocess


default_args = {'owner': 'sofiia',
                'start_date': datetime(2025, 4, 18)}


def extract_mysql_table_to_duckdb(table_name):
    def _inner(**kwargs):

        hook = MySqlHook(mysql_conn_id='mysql_default')
        df = hook.get_pandas_df(f"SELECT * FROM raw.{table_name}")

        con = duckdb.connect(database='/usr/local/airflow/data/warehouse.duckdb')
        con.execute(f"CREATE OR REPLACE TABLE {table_name} AS SELECT * FROM df")
        con.close()
    return _inner



with DAG('etl_to_duckdb', schedule_interval=None, default_args=default_args, catchup=False) as dag:

    extract_payments = PythonOperator(
        task_id='extract_payments',
        python_callable=extract_mysql_table_to_duckdb('payments')
    )

    extract_orders = PythonOperator(
        task_id='extract_orders',
        python_callable=extract_mysql_table_to_duckdb('orders')
    )

    extract_order_items = PythonOperator(
        task_id='extract_order_items',
        python_callable=extract_mysql_table_to_duckdb('order_items')
    )

    # Optional: load seeds that remain static like 'products'
    load_products_seed = PythonOperator(
        task_id='load_products_seed',
        python_callable=lambda **kwargs: pd.read_csv(
            '/usr/local/airflow/include/products.csv'
        ).to_sql(
            'products', duckdb.connect('/usr/local/airflow/data/warehouse.duckdb'),
            if_exists='replace', index=False
        )
    )

    run_dbt = PythonOperator(
        task_id='run_dbt',
        python_callable=lambda: subprocess.run(['dbt', 'build'], cwd='/usr/local/airflow/dbt/jaffle_shop', check=True)
    )

    [extract_payments, extract_orders, extract_order_items, load_products_seed] >> run_dbt




