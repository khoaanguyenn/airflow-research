from typing import Optional
from astronomer.providers.http.hooks.http import HttpHookAsync

class SidekiqHookAsync(HttpHookAsync):
  def __init__(self, http_conn_id: str = 'le_default') -> None:
    super().__init__(http_conn_id=http_conn_id)

  async def submit_job(self, jid: Optional[str], worker_class: str, args: list, queue: str = 'airflow', retry: Optional[bool] = True) -> None:
    return await self.run(
      endpoint=f"airflow/schedule",
      headers={"accept": "application/json"},
      data={
        "jid": jid,
        "queue": queue,
        "worker_class": worker_class,
        "args": args,
        "retry": retry # Use Airflow retry mechanism by default
      }
    )
