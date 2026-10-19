ENV["RAILS_ENV"] = "test"
ENV["DATABASE_URL"] = "sqlite3::memory:"

require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"
require "devise"
require "devise_sms_activable"
require "active_support/test_case"
require "minitest/autorun"

class TestApp < Rails::Application
  config.eager_load = false
  config.secret_key_base = "x" * 64
  config.logger = Logger.new(nil)
end

class Devise::SmsSender
  def self.send_sms(phone, message)
    true
  end
end

Devise.setup do |config|
  require "devise/orm/active_record"
  config.mailer_sender = "noreply@example.com"
  config.sms_confirm_within = 5.minutes
end

TestApp.initialize!

ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :email, default: "", null: false
    t.string :encrypted_password, default: "", null: false
    t.string :phone
    t.string :sms_confirmation_token, limit: 5
    t.datetime :confirmation_sms_sent_at
    t.datetime :sms_confirmed_at
  end
end

class User < ActiveRecord::Base
  devise :database_authenticatable, :sms_activable
end
