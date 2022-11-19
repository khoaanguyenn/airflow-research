from airflow.hooks.base import BaseHook
from aioredis.client import Redis

class RedisHookAsync(BaseHook):
  def __init__(self, redis_conn_id: str = 'le_redis_conn') -> None:
    self.redis_conn_id = redis_conn_id

  def get_client(self) -> Redis:
    conn = self.get_connection(self.redis_conn_id)

    self.host = conn.host
    self.port = conn.port
    self.password = None if str(conn.password).lower() in ['none', 'false', ''] else conn.password
    self.db = conn.extra_dejson.get('db')

    self.log.debug('Initalizing asynchronous Redis object for conn_id "%s" %s:%s:%s', self.redis_conn_id, self.host, self.port, self.db)

    return Redis(host=self.host, port=self.port, db=self.db, decode_responses=True)
