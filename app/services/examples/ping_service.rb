module Examples
  class PingService
    extend Dry::Initializer

    option :message, default: proc { "pong" }

    def call
      message
    end
  end
end
