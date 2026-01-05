# frozen_string_literal: true

class Admin::LlmsTxtController < Admin::AdminController
  def show
    render json: { llms_txt: LlmsTxt.content || "" }
  end

  def update
    params.require(:llms_txt)
    LlmsTxt.content = params[:llms_txt]
    render json: { llms_txt: LlmsTxt.content || "" }
  end

  def reset
    LlmsTxt.content = ""
    render json: { llms_txt: "" }
  end
end
