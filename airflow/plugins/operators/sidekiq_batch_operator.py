import secrets
from typing import Dict
from airflow.utils.context import Context
from airflow.sensors.base import BaseSensorOperator
from airflow.exceptions import AirflowException
from hooks.sidekiq_waiter import BatchWaiter

from triggers.sidekiq_batch_trigger import SidekiqBatchTrigger

class SidekiqBatchOperator(BaseSensorOperator):
  def __init__(
    self,
    config: Dict = {},
    http_conn_id: str = "le_default",
    redis_conn_id: str = "le_redis_conn",
    **kwargs
  ) -> None:
    super().__init__(**kwargs)
    self.config = config
    self.http_conn_id = http_conn_id
    self.redis_conn_id = redis_conn_id
    self.jid = secrets.token_hex(12) # Pre-generate Sidekiq job's ID

  def execute(self, context: Context):
    self.defer(
      trigger=SidekiqBatchTrigger(
        jid=self.jid,
        http_conn_id=self.http_conn_id,
        redis_conn_id=self.redis_conn_id,
        job_params=self._build_job_params()
        ),
      method_name="execute_complete"
      )

  def execute_complete(self, context: Context, event=None) -> None:
    # Raise error if batch is failed
    if "status" in event and event["status"] == BatchWaiter.DEATH_STATE:
      raise AirflowException(event)

    self.log.info(event)

  def _build_job_params(self) -> Dict[str, str]:
    return {
      "jid": self.jid,
      "queue": self.config["queue"],
      "worker_class": self.config["worker_class"],
      "args": self.config["args"]
    }
