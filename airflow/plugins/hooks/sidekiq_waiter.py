import json
import re
from typing import Optional
from aioredis.client import PubSub
from airflow.utils.log.logging_mixin import LoggingMixin

class WaiterError(Exception):
  def __init__(self, status: str, details: Optional[str] = "") -> None:
    self.status = status
    self.details = details
    super().__init__(self.details)

class JobWaiter(LoggingMixin):
  QUEUED_JOB = "queued"
  COMPLETE_JOB = "complete" # This also mean success
  RETRYING_JOB = "retrying"
  FAILED_JOB = "failed"
  WORKING_JOB = "working"
  INTERRUPTED_JOB = "interrupted"
  UNKNOWN_STATE = "unknown"
  ERROR_STATES = [FAILED_JOB, INTERRUPTED_JOB, UNKNOWN_STATE]

class JobStatusWaiter(JobWaiter):
  def __init__(self, sub: PubSub) -> None:
    self.sub = sub

  async def wait(self) -> None:
    self.log.info("[Waiter] - Enter waiting loop")
    while True:
      message = await self.sub.get_message(ignore_subscribe_messages=True)
      if message is not None:
        self.log.info(f"[Waiter] - Message received: {message}")

        data = json.loads(message["data"])
        status = data["status"]
        details = data["details"]

        if status == JobWaiter.COMPLETE_JOB:
          self.log.info("[Waiter] - Job is completed without error, exiting the loop...")
          return {"status": self.COMPLETE_JOB, "details": details}

        elif status in (JobWaiter.QUEUED_JOB, JobWaiter.WORKING_JOB, JobWaiter.RETRYING_JOB):
          self.log.info(f"[Waiter] - Job is {status}, listening...")
          pass

        elif status in JobWaiter.ERROR_STATES:
          self.log.info("[Waiter] - Job is failed, exiting the loop...")
          return {"status": status, "details": details}

        else:
          self.log.info(f"[Waiter] - Received unknown status {status}")
          return {"status": self.UNKNOWN_STATE, "details": details}

class BatchWaiter(LoggingMixin):
  SUCCESS_STATE = "success"
  COMPLETED_STATE = "complete"
  DEATH_STATE = "death"
  BATCH_SIGNALS = [SUCCESS_STATE, COMPLETED_STATE, DEATH_STATE]

class BatchInitWaiter(BatchWaiter):
  BID_PATTERN = r"(\w|=|-){14}"

  def __init__(self, sub: PubSub) -> None:
    self.sub = sub

  async def wait(self) -> str:
    self.log.info("[BatchInitWaiter] - Enter waiting loop")
    while True:
      message = await self.sub.get_message(ignore_subscribe_messages=True)
      if message is not None:
        self.log.info(f"[BatchInitWaiter] - Message received: {message}")

        data = json.loads(message["data"])
        bid = data["bid"]
        status = data["status"]
        details = data["details"]

        if self._is_bid(bid):
          self.log.info(f'[BatchInitWaiter] - Successfully received bid "b-{bid}", existing loop...')
          return bid

        elif status == BatchWaiter.SUCCESS_STATE:
          self.log.info("[BatchStatusWaiter] - Batch is success, existing loop...")
          return {"status": BatchWaiter.SUCCESS_STATE, "details": details}

        elif status == BatchWaiter.DEATH_STATE:
          self.log.info("[BatchStatusWaiter] - Batch is failed, existing loop...")
          return {"status": BatchWaiter.DEATH_STATE, "details": details}


  def _is_bid(self, data) -> bool:
    return re.fullmatch(self.BID_PATTERN, data) is not None

class BatchStatusWaiter(BatchWaiter):
  def __init__(self, sub: PubSub) -> None:
    self.sub = sub

  async def wait(self) -> None:
    self.log.info("[BatchStatusWaiter] - Enter waiting loop")
    while True:
      message = await self.sub.get_message(ignore_subscribe_messages=True)
      if message is not None:
        self.log.info(f"[BatchStatusWaiter - Message received: {message}")
        data = json.loads(message["data"])
        status = data["status"]
        details = data["details"]

        if status == BatchWaiter.COMPLETED_STATE:
          self.log.info("[BatchStatusWaiter] - Batch is completed, continue to listening...")
          pass

        elif status == BatchWaiter.SUCCESS_STATE:
          self.log.info("[BatchStatusWaiter] - Batch is success, existing loop...")
          return {"status": BatchWaiter.SUCCESS_STATE, "details": details}

        elif status == BatchWaiter.DEATH_STATE:
          self.log.info("[BatchStatusWaiter] - Batch is failed, existing loop...")
          return {"status": BatchWaiter.DEATH_STATE, "details": details}

        elif status not in self.BATCH_SIGNALS:
          self.log.debug("[BatchInitWaiter] - Unexpected behavior, might cause intermittent result as it should receive batch initialization signal first")
          return {"status": BatchWaiter.DEATH_STATE, "details": details}
