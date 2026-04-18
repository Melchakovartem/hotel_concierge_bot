class BaseService
  extend Dry::Initializer

  class << self
    def call(**args)
      new(**args).call
    end
  end

  private

  def success(result: nil)
    Result.new(success: true, result: result)
  end

  def failure(error_code:, messages:, result: nil)
    Result.new(success: false, error_code: error_code, messages: messages, result: result)
  end

  def raw_params(params)
    params_hash = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    params_hash.with_indifferent_access
  end
end
