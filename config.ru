
require 'bundler/setup'
require_relative 'app'

use Rack::Deflater
run Sinatra::Application

