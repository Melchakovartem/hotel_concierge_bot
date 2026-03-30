require "rails_helper"

RSpec.describe "Health check" do
  describe "GET /up" do
    it "returns a successful response" do
      get rails_health_check_path

      expect(response).to have_http_status(:ok)
    end
  end
end
