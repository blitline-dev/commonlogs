
require 'bundler/setup'
require_relative 'app'
require_relative 'protected_paths'

use Rack::Deflater

run Rack::URLMap.new({
  "/" => App,
  "/p" => ProtectedPaths
})