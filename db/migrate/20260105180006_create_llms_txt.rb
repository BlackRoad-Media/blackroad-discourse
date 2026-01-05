# frozen_string_literal: true

class CreateLlmsTxt < ActiveRecord::Migration[8.0]
  def change
    create_table :llms_txts do |t|
      t.text :content, null: false, default: ""
      t.timestamps
    end
  end
end
