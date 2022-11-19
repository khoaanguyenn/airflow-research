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
    'khoa_learn_dag',
    # These args will get passed on to each operator
    # You can override them on a per-task basis during operator initialization
    default_args={
        'depends_on_past': False,
        'email': ['airflow@example.com'],
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

    s1 = SFTPSensor(
        task_id='check_book_file',
        path='upload/book.csv',
        sftp_conn_id='book_sftp',
        poke_interval=5,
        mode="reschedule"
    )

    s2 = SFTPSensor(
        task_id='check_bank_file',
        path='upload/bank.csv',
        sftp_conn_id='book_sftp',
        poke_interval=5,
        mode='reschedule'
    )

    # sidekiq_async = SidekiqJobOperator(
    #     task_id='test_deferable_operator',
    #     config={
    #         "queue": "airflow",
    #         "worker_class": "Bookshelf::SidekiqBatchTest",
    #         "args": ["failed"]
    #     },
    #     retries=0,
    #     retry_delay=timedelta(seconds=5)
    # )

    sidekiq_async = SidekiqBatchOperator(
        task_id='test_deferable_sidekiq_batch',
        config={
            "queue": "airflow",
            "worker_class": "Bookshelf::SidekiqBatchTest",
            "args": [[["Khoa", "Junior"], ["Huiming", "Director"], ["Shinn", "Senior"], ["Hon", "Mid"]]]
        },
        retries=0,
        retry_delay=timedelta(seconds=5)
    )

    t1 = BashOperator(
        task_id='wait_5_secs',
        bash_command='sleep 5',
        retries=3
    )

    # l1 = LoyaltyEngineSensor(
    #     task_id='wait_for_fetching',
    #     poke_interval=10,
    #     mode="reschedule",
    #     jid=t2.output
    # )

    # t3 = LoyaltyEngineOperator(
    #     task_id='add_many_books',
    #     configuration = {
    #         "queue": "airflow",
    #         "worker_class": "Bookshelf::AddManyBooksWorker",
    #         "args": []
    #     },
    #     retries=3
    # )

    t4 = BashOperator(
        task_id='wrap_up',
        bash_command='sleep 5',
        retries=3
    )


    [s1, s2] >> sidekiq_async >> t1 >> t4