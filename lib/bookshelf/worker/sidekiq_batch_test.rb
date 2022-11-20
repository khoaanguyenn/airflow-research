module Bookshelf
  class SidekiqBatchTest
    include Sidekiq::Worker
    prepend Airflow::Batch

    def perform(names_array = [])
      # set_complete('type' => 'helloo', 'greetings' => 'yoyoyo')
      # set_success('type' => 'batch is success', 'greetings' => 'printing successful signal', SidekiqBatchTest)
      # set_death('type' => 'batch is death', 'greetings' => 'printing death signal', SidekiqBatchTest)
      sleep(5)

      batch_jobs do |job|
        job.add('Bookshelf::SidekiqDummyJob', names_array)
      end
    end

    def on_complete(_status, options)
      puts "Options: #{options}"
      # return @task.success!({"remark" => "No need to continue"})
      puts "Hey, I'm completed"
    end

    def on_success(_status, options)
      puts "Options: #{options}"
      @task.log('This is from SidekiqBatchTest success callback method')
      puts "Hey, I'm success"
    end

    def on_death(_status, options)
      puts "Options: #{options}"
      puts "Hey, I'm death"
    end
  end
end

module Bookshelf
  class SidekiqDummyJob
    include Sidekiq::Worker

    sidekiq_options retry: 3

    sidekiq_retry_in { 10 }

    def perform(name, title)
      # raise StandardError, 'No Khoa' if name == 'Khoa'

      puts "Name: #{name}, title: #{title}"
    end
  end
end

module Bookshelf
  class SidekiqAlwaysFailedJob
    include Sidekiq::Worker
    prepend Airflow::Job

    sidekiq_options retry: 3
    sidekiq_retry_in { 10 }

    def perform
      return @task.success!('Hurray, success temporary for nowwww, stop, and not emitting any signal after this')
      raise StandardError, "I'm always failed!"
    end
  end
end

module Bookshelf
  # This uses auto-mode to watch Sidekiq job status
  class SidekiqAlwaysHappyJob
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    def perform
      puts "Hey guys, I'm happy!"
    end
  end
end

module Bookshelf
  # This allows to manually set Sidekiq job status
  class SidekiqAirflowManualTest
    include Sidekiq::Worker
    prepend Airflow::Job

    def perform(test_word = 'fail')
      sleep(8)
      if test_word == 'success'
        @task.success!('Hey Airflow, I have successfully executed the Worker')
      else
        @task.fail!('Unfortunately, something went wrong')
      end
    end
  end
end

module Bookshelf
  class SidekiqPrintingToday
    include Sidekiq::Worker
    prepend Airflow::Job

    def perform(today)
      sleep(3)
      puts "Heyyy, today is #{today}"
    end
  end
end
