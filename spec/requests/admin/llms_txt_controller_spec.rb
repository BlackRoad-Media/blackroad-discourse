# frozen_string_literal: true

RSpec.describe Admin::LlmsTxtController do
  fab!(:admin)
  fab!(:user)

  describe "#show" do
    it "returns content for admins" do
      sign_in(admin)
      LlmsTxt.content = "# Test"

      get "/admin/customize/llms.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["llms_txt"]).to eq("# Test")
    end

    it "returns 404 for non-admins" do
      sign_in(user)
      get "/admin/customize/llms.json"
      expect(response.status).to eq(404)
    end
  end

  describe "#update" do
    it "saves content for admins" do
      sign_in(admin)

      put "/admin/customize/llms.json", params: { llms_txt: "# New" }

      expect(response.status).to eq(200)
      expect(LlmsTxt.content).to eq("# New")
    end

    it "requires llms_txt param" do
      sign_in(admin)
      put "/admin/customize/llms.json", params: {}
      expect(response.status).to eq(400)
    end

    it "returns 404 for non-admins" do
      sign_in(user)
      put "/admin/customize/llms.json", params: { llms_txt: "# Content" }
      expect(response.status).to eq(404)
    end
  end

  describe "#reset" do
    it "clears content for admins" do
      sign_in(admin)
      LlmsTxt.content = "# Test"

      delete "/admin/customize/llms.json"

      expect(response.status).to eq(200)
      expect(LlmsTxt.content).to be_blank
    end

    it "returns 404 for non-admins" do
      sign_in(user)
      delete "/admin/customize/llms.json"
      expect(response.status).to eq(404)
    end
  end
end
