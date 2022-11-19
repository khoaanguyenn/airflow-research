import time
from typing import Optional

from airflow.providers.http.hooks.http import HttpHook
from airflow.exceptions import AirflowException, AirflowFailException

class LoyaltyEngineHook(HttpHook):
  QUEUED = 'queued'
  WORKING = 'working'
  COMPLETE = 'complete'
  FAILED = 'failed'
  INTERRUPTED = 'interrupted'
  RETRYING = 'retrying'
  """
  Hook for LoyaltyEngine API
  :param airbyte_conn_id: Required. LoyaltyEngine connection ID
  """

  conn_name_attr = 'loyaltyengine_conn_id'
  default_conn_name = 'loyaltyengine_default'
  conn_type = 'loyaltyengine'
  hook_name = 'Loyalty Engine'

  def __init__(self, le_conn_id: str = 'le_default') -> None:
    super().__init__(http_conn_id = le_conn_id)

  def submit_job(self, jid: Optional[str], worker_class: str, args: list, at: Optional[float], queue: str = 'airflow', retry: Optional[bool] = False) -> None:
    """
    Push a Sidekiq job to the queue
    """
    return self.run(
      endpoint=f"airflow/schedule",
      headers={"accept": "application/json"},
      json={
        "jid": jid,
        "queue": queue,
        "worker_class": worker_class,
        "args": args,
        "at": at,
        "retry": retry # Use Airflow retry mechanism by default
      }
    )

  def get_job(self, jid: str):
    """
    Check status of the job
    """
    return self.run(
      endpoint=f"airflow/check",
      headers={"accept": "application/json"},
      json={"jid": jid}
    )

  def wait_job(self, jid: str, interval: float = 5, timeout: Optional[float] = 3600, retries: int = 3) -> None:
    """
    Periodically checking the given job's ID
    """
    status = None
    start = time.monotonic()
    while True:
      # Check connection timeout
      if start + timeout < time.monotonic():
        raise AirflowException(f"Timeout: No response from Sidekiq job {jid}")
      time.sleep(interval)

      # Get job status
      try:
        job = self.get_job(jid).json()["job"]
        status = job["status"]
        attempts = int(job["retry"] or 0)
      except AirflowException as err:
        self.log.info("Retrying, LoyaltyEngine API server error")
        continue

      #Check jos status
      if status in (self.QUEUED, self.WORKING, self.RETRYING):
        continue
      elif status == self.COMPLETE:
        break
      elif status == self.FAILED:
        raise AirflowException(f"Job {jid} has failed, rescheduling...")
      elif status == self.INTERRUPTED:
        raise AirflowFailException(f"Job {jid} has been interrupted")

  def wait_batch(self, jid: str, interval: float = 5, timeout: Optional[float] = 3600, retries: int = 3) -> None:
    """
    Periodically checking given batch's ID
    """
    start = time.monotonic()
    while True:
      # Check connection timeout
      if start + timeout < time.monotonic():
        raise AirflowException(f"Timeout: No response from Sidekiq batch {jid}")
      time.sleep(interval)

      # Get all jobs status
      job = self.get_job(jid).json()["job"]
      self.log.info(f"Job information: \n {job}")
      batch = job["batch"]
      fail_jobs = batch["failure_info"]

      # Breaks if there are no failure jobs
      if len(fail_jobs) == 0:
        break
