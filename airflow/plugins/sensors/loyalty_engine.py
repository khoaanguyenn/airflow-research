from typing import Sequence
from airflow.sensors.base import BaseSensorOperator
from hooks.loyalty_engine import LoyaltyEngineHook
from airflow.exceptions import AirflowException

class LoyaltyEngineSensor(BaseSensorOperator):
  template_fields: Sequence[str] = ('jid',)
  """
  Loyalty hook
  """
  QUEUED = 'queued'
  WORKING = 'working'
  COMPLETE = 'complete'
  RETRYING = 'retrying'
  FAILED = 'failed'
  INTERRUPTED = 'interrupted'

  def __init__(self, jid: str, **kwargs) -> None:
    super().__init__(**kwargs)
    self.jid = jid

  def poke(self, context: 'Context') -> bool:
    hook = LoyaltyEngineHook(le_conn_id = 'le_default')
    jod_id = self.jid
    print(f"Job ID: {jod_id}")
    print(f"Type: {type(self.jid)}")
    job_object = hook.get_job(jid=self.jid)
    status =  job_object.json()["job"]["status"]

    if status == self.FAILED:
      raise AirflowException(f"Job {self.jid} has failed")
    elif status == self.INTERRUPTED:
      return AirflowException(f"Job {self.jid} has been interrupted")
    elif status == self.COMPLETE:
      return True

    self.log.info(f"Waiting for job {self.jid} to complete !")
    return False