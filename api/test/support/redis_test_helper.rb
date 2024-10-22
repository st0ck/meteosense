module RedisTestHelper
  def setup_redis
    flush_redis
  end

  def teardown_redis
    flush_redis
  end

  def flush_redis
    redis_pool.with(&:flushdb)
  end

  def redis_pool
    @redis_pool ||= Rails.application.config.redis_pool
  end
end
