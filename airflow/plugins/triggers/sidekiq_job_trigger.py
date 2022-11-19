from typing import Any, Dict, Tuple
from airflow.triggers.base import BaseTrigger, TriggerEvent

from hooks.redis_hook_async import RedisHookAsync
from hooks.sidekiq_hook_async import SidekiqHookAsync
from hooks.sidekiq_waiter import JobStatusWaiter

class SidekiqJobTrigger(BaseTrigger):
  def __init__(
    self,
    jid: str,
    http_conn_id: str = "le_default",
    redis_conn_id: str = "le_redis_conn",
    job_params: Dict[str, str] = {}
  ) -> None:
    super().__init__()
    self.jid = jid
    self.http_conn_id = http_conn_id
    self.redis_conn_id = redis_conn_id
    self.job_params = job_params

  def serialize(self) -> Tuple[str, Dict[str, Any]]:
    return (
      "triggers.sidekiq_job_trigger.SidekiqJobTrigger",
      {
        "jid": self.jid,
        "redis_conn_id": self.redis_conn_id,
        "http_conn_id": self.http_conn_id,
        "job_params": self.job_params
      }
    )

  async def run(self) -> None:
    # Subscribe to `sidekiq:job:{self.jid}` channel, then close connection after use
    async with RedisHookAsync(redis_conn_id=self.redis_conn_id).get_client() as client:
      channel = client.pubsub()
      await channel.subscribe(f"sidekiq:job:{self.jid}")
      self.log.info(f'Subscribed to channel "sidekiq:job:{self.jid}"')

      # Submit job
      hook = SidekiqHookAsync(http_conn_id=self.http_conn_id)
      await hook.submit_job(**self.job_params)
      self.log.info(f'Sidekiq job "{self.jid}" is submitted successfully !')

      # Wait for job status
      waiter = JobStatusWaiter(sub=channel)
      response = await waiter.wait()
      await channel.unsubscribe()
      yield TriggerEvent(response)
