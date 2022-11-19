from datetime import datetime, date, timedelta
# The DAG object; we'll need this to instantiate a DAG
from airflow import DAG

# Operators; we need this to operate!
from airflow.operators.bash import BashOperator
from operators.sidekiq_operator import SidekiqOperator
from operators.sidekiq_batch_operator import SidekiqBatchOperator
from airflow.providers.sftp.sensors.sftp import SFTPSensor
from operators.sidekiq_job_operator import SidekiqJobOperator

def task_failure_alert(context):
    print(f"Task has failed, task_instance_key_str: {context['task_instance_key_str']}")

def taks_retry_alert(context):
    print(f"Task has failed, retrying in next 5 seconds")

with DAG(
    'mini_loyalty_engine',
    # These args will get passed on to each operator
    # You can override them on a per-task basis during operator initialization
    default_args={
        'depends_on_past': False,
        'email': ['khoa.nguyen@kaligo.com'],
        'email_on_failure': False,
        'email_on_retry': False,
        'retries': 1,
        'retry_delay': timedelta(minutes=5),
    },
    description='Khoa is following Airflow tutorial',
    schedule_interval=None,
    start_date=datetime(2021, 1, 1),
    catchup=False,
    on_failure_callback=task_failure_alert,
    tags=['example'],
) as dag:

    check_accounts_file = SFTPSensor(
        task_id='check_accounts_file',
        path='upload/accounts_file.csv',
        sftp_conn_id='minile_sftp',
        poke_interval=5,
        mode='reschedule'
    )

    check_transactions_file = SFTPSensor(
        task_id='check_transactions_file',
        path='upload/transactions_file.csv',
        sftp_conn_id='minile_sftp',
        poke_interval=5,
        mode='reschedule'
    )

    extract_accounts_file = SidekiqJobOperator(
        task_id='extract_accounts_file',
        config={
            "queue": "airflow",
            "worker_class": "MiniLoyaltyEngine::FileProcessing::ExtractAccountFileWorker",
            "args": ["accounts_file.csv"]
        },
        retries=0,
        retry_delay=timedelta(seconds=5)
    )

    extract_transactions_file = SidekiqJobOperator(
        task_id='extract_transactions_file',
        config={
            "queue": "airflow",
            "worker_class": "MiniLoyaltyEngine::FileProcessing::ExtractTransactionFileWorker",
            "args": ["transactions_file.csv"]
        },
        retries=0,
        retry_delay=timedelta(seconds=5)
    )


    enroll_users = SidekiqJobOperator(
        task_id='enroll_user',
        config={
            "queue": "airflow",
            "worker_class": "MiniLoyaltyEngine::Enrollment::EnrollUserWorker",
            "args": []
        },
        retries=0,
        retry_delay=timedelta(seconds=5)
    )

    transform_points = SidekiqJobOperator(
        task_id='transform_points',
        config={
            "queue": "airflow",
            "worker_class": "MiniLoyaltyEngine::PointCalculation::TransformPointsWorker",
            "args": []
        },
        retries=0,
        retry_delay=timedelta(seconds=5)
    )

    wrap_up = BashOperator(
        task_id='wrap_up',
        bash_command='sleep 5',
        retries=3
    )

    [
      check_accounts_file >> extract_accounts_file,
      check_transactions_file >> extract_transactions_file
    ] >> enroll_users >> transform_points >> wrap_up
