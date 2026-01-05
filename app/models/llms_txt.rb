# frozen_string_literal: true

class LlmsTxt < ActiveRecord::Base
  MAX_CONTENT_LENGTH = 100_000

  validates :content, length: { maximum: MAX_CONTENT_LENGTH }

  def self.content
    first&.content.presence
  end

  def self.content=(value)
    record = first_or_initialize
    record.update!(content: value.to_s)
  end
end

# == Schema Information
#
# Table name: llms_txts
#
#  id         :bigint           not null, primary key
#  content    :text             default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
