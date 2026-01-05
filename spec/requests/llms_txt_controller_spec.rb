# frozen_string_literal: true

RSpec.describe LlmsTxtController do
  describe "#index" do
    it "returns 404 when empty" do
      get "/llms.txt"
      expect(response.status).to eq(404)
    end

    it "returns content as plain text" do
      LlmsTxt.content = "# Test"

      get "/llms.txt"

      expect(response.status).to eq(200)
      expect(response.content_type).to start_with("text/plain")
      expect(response.body).to eq("# Test")
    end
  end
end
