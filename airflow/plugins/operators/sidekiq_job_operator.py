import secrets
from typing import Dict
from airflow.utils.context import Context
from airflow.exceptions import AirflowFailException, AirflowException
from airflow.sensors.base import BaseSensorOperator

from hooks.sidekiq_waiter import JobWaiter
from triggers.sidekiq_job_trigger import SidekiqJobTrigger

class SidekiqJobOperator(BaseSensorOperator):
  def __init__(self, config: Dict, redis_conn_id: str = "le_redis_conn", http_conn_id: str = "le_default", **kwargs) -> None:
    super().__init__(**kwargs)
    self.redis_conn_id = redis_conn_id
    self.http_conn_id = http_conn_id
    self.config = config
    self.jid = secrets.token_hex(12) # Pre-generate Sidekiq job's ID

  def execute(self, context: Context):
    self.defer(
      trigger=SidekiqJobTrigger(
        jid=self.jid,
        redis_conn_id=self.redis_conn_id,
        http_conn_id=self.http_conn_id,
        job_params=self._build_job_params()
      ),
      method_name="execute_complete"
    )

  def execute_complete(self, context: Context, event=None) -> None:
    # Interrupt DAG if the job get interrupted by Sidekiq
    if "status" in event and event["status"] in JobWaiter.ERROR_STATES:
      if event["status"] == JobWaiter.INTERRUPTED_JOB:
        raise AirflowFailException(event)
      raise AirflowException(event)

    self.log.info(event)
    # Send webhook to Ruby application here

  def _build_job_params(self) -> Dict[str, str]:
    return {
      "jid": self.jid,
      "queue": self.config["queue"],
      "worker_class": self.config["worker_class"],
      "args": self.config["args"]
    }
