require "rails_helper"

RSpec.describe Examples::PingService do
  describe "#call" do
    it "returns the configured message" do
      service = described_class.new(message: "ready")

      expect(service.call).to eq("ready")
    end

    it "returns the default message" do
      expect(described_class.new.call).to eq("pong")
    end
  end
end
