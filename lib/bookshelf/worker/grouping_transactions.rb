require 'daru'

module Bookshelf
  class GroupingTransactions
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    def initialize
      @redis = Redis.new(url: ENV['REDIS_URL'])
    end

    def perform
      data = @redis.get(parse_key)
      parsed_data = JSON.parse(data)
      aggregated_data = to_sum(parsed_data)
      store_to_redis(aggregated_data)
    end

    private

    def to_sum(data)
      df = Daru::DataFrame.rows(data[1..], order: data[0])
      grouped_accounts = df.group_by(['id'])
      group_sums = grouped_accounts.sum.to_a
      to_record(group_sums)
    end

    def to_record(groups)
      groups.last.zip(groups.first).map do |id, h|
        h.merge(id: id)
      end
    end

    def store_to_redis(data)
      @redis.setex(transform_key, 2.hours.to_i, data.to_json)
    end

    def transform_key
      "#{Date.today}_transform"
    end

    def parse_key
      "#{Date.today}_parse"
    end
  end
end
