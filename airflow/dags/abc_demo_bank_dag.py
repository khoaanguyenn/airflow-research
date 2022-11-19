from datetime import datetime
from airflow import DAG

from airflow.providers.sftp.sensors.sftp import SFTPSensor
from operators.sidekiq_job_operator import SidekiqJobOperator
from operators.sidekiq_batch_operator import SidekiqBatchOperator

with DAG(
  "abc_bank_batch",
  description="A daily run batch for ABC bank",
  schedule_interval=None,
  start_date=datetime(2022, 10, 12, 0, 0, 0),
  catchup=False,
  tags=['ABC bank']
) as dag:

  # Extract steps
  check_transaction_file = SFTPSensor(
    task_id='check_transaction_file',
    sftp_conn_id='book_sftp',
    path='upload/transactions.csv',
    poke_interval=5,
    mode="reschedule"
  )

  extract_transaction_file = SidekiqJobOperator(
    task_id='extract_sftp_file',
    config={
      "queue": "airflow",
      "worker_class": "Bookshelf::FetchSFTPFileWorker",
      "args": ["upload/transactions.csv"]
    },
    retries=0
  )

  # Transformation steps
  parse_transactions = SidekiqJobOperator(
    task_id='parse_transactions',
    config={
      "queue": "airflow",
      "worker_class": "Bookshelf::ParseTransactionFile",
      "args": []
    },
    retries=0
  )

  grouping_transactions = SidekiqJobOperator(
    task_id='group_transactions',
    config={
      "queue": "airflow",
      "worker_class": "Bookshelf::GroupingTransactions",
      "args": []
    },
    retries=0
  )

  # Load steps
  load_transactions = SidekiqBatchOperator(
    task_id='load_all_transactions',
    config={
      "queue": "airflow",
      "worker_class": "Bookshelf::LoadDataWorker",
      "args": []
    },
    retries=0
  )

  check_transaction_file >> extract_transaction_file >> parse_transactions >> grouping_transactions >> load_transactions