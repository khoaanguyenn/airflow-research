from typing import Any, Dict, Tuple
from airflow.triggers.base import BaseTrigger, TriggerEvent
from hooks.sidekiq_hook_async import SidekiqHookAsync
from hooks.redis_hook_async import RedisHookAsync
from hooks.sidekiq_waiter import BatchInitWaiter, BatchStatusWaiter

class SidekiqBatchTrigger(BaseTrigger):
  def __init__(
    self,
    jid: str,
    job_params: Dict[str, str] = {},
    http_conn_id: str = "le_default",
    redis_conn_id: str = "le_redis_conn"
  ) -> None:
    super().__init__()
    self.jid = jid
    self.job_params = job_params
    self.http_conn_id = http_conn_id
    self.redis_conn_id = redis_conn_id

  def serialize(self) -> Tuple[str, Dict[str, Any]]:
    return (
      "triggers.sidekiq_batch_trigger.SidekiqBatchTrigger",
      {
        "jid": self.jid,
        "job_params": self.job_params,
        "http_conn_id": self.http_conn_id,
        "redis_conn_id": self.redis_conn_id
      }
    )

  async def run(self) -> None:
    # Subscribe to `sidekiq:job:{self.jid}` channel, then close connection after use
    async with RedisHookAsync(redis_conn_id=self.redis_conn_id).get_client() as client:
      channel = client.pubsub()
      await channel.subscribe(f"sidekiq:batch:{self.jid}")
      self.log.info(f'Subscribed to channel "sidekiq:batch:{self.jid}"')

      # Submit job
      hook = SidekiqHookAsync(http_conn_id=self.http_conn_id)
      await hook.submit_job(**self.job_params)
      self.log.info(f'Sidekiq job "{self.jid}" is submitted successfully!')

      # Waiting for a batch to be initilized inside a Sidekiq Job
      init_waiter = BatchInitWaiter(sub=channel)
      bid = await init_waiter.wait()
      self.log.info(f'Sidekiq batch "b-{bid}" has been initialized!')

      # Waiting for batch status gets updated to Redis channel
      status_waiter = BatchStatusWaiter(sub=channel)
      response = await status_waiter.wait()
      await channel.unsubscribe() # Unsubscribe channel
      yield TriggerEvent(response)
