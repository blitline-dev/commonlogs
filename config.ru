
require 'bundler/setup'
require_relative 'app'
require_relative 'protected_paths'
require_relative 'controllers/api/notifications'
require_relative 'controllers/api/events'
require_relative 'controllers/api/features'
require_relative 'lib/notifier_service'

use Rack::Deflater

t = Thread.new {
  NotifierService.start!
}

run Rack::URLMap.new({
  "/" => App,
  "/p" => ProtectedPaths,
  "/notifications" => Api::NotificationController,
  "/features" => Api::FeatureController,
  "/events" => Api::EventController
})
