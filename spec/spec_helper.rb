require 'rubygems'
require 'bundler'
Bundler.setup :default, :development, :test

RSpec.configure do |c|
  c.mock_with :rspec
  c.formatter = "progress"
end

$:.push File.expand_path('..', File.dirname(__FILE__))
$:.push File.expand_path('../lib', File.dirname(__FILE__))
require "httparrot"
