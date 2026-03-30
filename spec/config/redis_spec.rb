require "rails_helper"

RSpec.describe "Redis configuration" do
  it "exposes a configured redis client" do
    expect(Rails.application.config.x.redis_url).to be_present
    expect(Rails.application.config.x.redis).to be_a(Redis)
  end
end
