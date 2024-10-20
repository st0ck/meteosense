redis_config = Rails.application.config_for(:redis)

# Use a different Redis database for each test process
db_number = ENV["PARALLEL_WORKERS"] ? ENV["PARALLEL_WORKERS"].to_i + 1 : redis_config["db"]
redis_url = "#{redis_config["url"]}/#{db_number}"

Rails.application.config.redis_pool = ConnectionPool.new(size: redis_config["pool_size"], timeout: redis_config["timeout"]) do
  Redis.new(url: redis_url)
end
