module Bookshelf
  class LoadDataWorker
    include Sidekiq::Worker
    prepend Airflow::Batch

    def initialize
      @redis = Redis.new(url: ENV['REDIS_URL'])
    end

    def perform
      set_complete(LoadDataWorker, 'type' => 'batch', 'greetings' => 'printing name')
      set_success(LoadDataWorker, 'type' => 'batch is success', 'greetings' => 'printing successful signal')
      set_death(LoadDataWorker, 'type' => 'batch is death', 'greetings' => 'printing death signal')

      data = @redis.get(transform_label)
      parsed_date = JSON.parse(data)

      batch_jobs do
        setup_sub_worker_array(
          'Bookshelf::LoadRowWorker',
          parsed_date.map { |row| [row] }
        )
      end
    end

    def on_complete(options)
      puts "Options: #{options}"
      puts "Hey, I'm completed"
    end

    def on_success(options)
      puts "Options: #{options}"
      puts "Hey, I'm success"
    end

    def on_death(options)
      puts "Options: #{options}"
      puts "Hey, I'm death"
    end

    private

    def transform_label
      "#{Date.today}_transform"
    end
  end
end
