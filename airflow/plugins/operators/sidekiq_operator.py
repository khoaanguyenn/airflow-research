from hooks.loyalty_engine import LoyaltyEngineHook
from airflow.models import BaseOperator

class SidekiqOperator(BaseOperator):
  def __init__(self, configuration: dict, asynchronous: bool = False, retries: int = 3, **kwargs) -> None:
    super().__init__(**kwargs)
    self.configuration = configuration
    self.asynchronous = asynchronous
    self.retries = retries

  def execute(self, context: 'Context') -> None:
    self.hook = LoyaltyEngineHook(le_conn_id="le_default")

    job_object = self.hook.submit_job(
      queue=self.configuration["queue"],
      worker_class=self.configuration["worker_class"],
      args=self.configuration["args"]
    )

    self.jid = job_object.json()["job"]["jid"]

    if not self.asynchronous:
      self.hook.wait_job(
        jid=self.jid,
        retries=self.retries
      )

    return self.jid
