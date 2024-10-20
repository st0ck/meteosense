ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require_relative "support/redis_test_helper"
require "rails/test_help"
require "active_support/all"
require "minitest/autorun"
require "mocha/minitest"
require "minitest/reporters"

Minitest::Reporters.use!

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
