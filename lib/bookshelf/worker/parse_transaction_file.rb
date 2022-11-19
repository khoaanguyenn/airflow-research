require 'fastcsv'
require 'daru'

module Bookshelf
  # Load downloaded transactions file
  class ParseTransactionFile
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    def initialize
      @redis_client = Redis.new(url: ENV['REDIS_URL'])
    end

    def perform
      file_path = @redis_client.get(file_signature)

      all = []
      File.open(file_path) do |file|
        FastCSV.raw_parse(file) do |row|
          all.push(parse_row(row))
        end
      end

      # Store loaded result to Redis
      @redis_client.setex(parse_data, 2.hours.to_i, all.to_json)
    ensure
      File.delete(file_path)
    end

    private

    INT_PATTERN = /^[-+]?\d+$/.freeze
    FLOAT_PATTERN = /^[-+]?\d+[,.]?\d*(e-?\d+)?$/.freeze

    def parse_row(row)
      row.to_a.map do |c|
        if c.empty?
          nil
        else
          try_string_to_number(c)
        end
      end
    end

    def try_string_to_number(str)
      case str
      when INT_PATTERN
        str.to_i
      when FLOAT_PATTERN
        str.tr(',', '.').to_f
      else
        str
      end
    end

    def file_signature
      "#{Date.today}_transactions"
    end

    def parse_data
      "#{Date.today}_parse"
    end
  end
end
