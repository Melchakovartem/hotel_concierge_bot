redis_url = Rails.application.config_for(:redis).deep_symbolize_keys.fetch(:url)

Rails.application.config.x.redis_url = redis_url
Rails.application.config.x.redis = Redis.new(url: redis_url)
