ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'capybara/rspec'
require './app'

Capybara.app = App
Capybara.app_host = 'http://127.0.0.1:9292'

RSpec.configure do |config|
  config.include Capybara::DSL
end

