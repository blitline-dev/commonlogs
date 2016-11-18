
require 'bundler/setup'
require 'time'
require_relative 'app'
require_relative 'protected_paths'
require_relative 'controllers/api/notifications'
require_relative 'controllers/api/events'
require_relative 'controllers/api/features'
require_relative 'controllers/api/settings'
require_relative 'lib/services/notifier_service'
require_relative 'lib/services/cleaner_service'
require_relative 'lib/services/aws_service'
require_relative 'lib/settings'
require_relative 'lib/cl_logger'

use Rack::Deflater

LOGGER.log("Starting App #{Time.now.utc.to_s}")

LOGGER.log("Starting memcached")
begin
  `service memcached start`
rescue => ex
  LOGGER.log("Skipping memcached")
end

Thread.new do
  begin
    CleanerService.start
  rescue => ex
    LOGGER.log ex
  end
end

Thread.new do
  begin
    NotifierService.start
  rescue => ex
    LOGGER.log ex
  end
end

Thread.new do
  begin
    AwsService.start
  rescue => ex
    LOGGER.log ex
  end
end

run Rack::URLMap.new({
  "/" => App,
  "/p" => ProtectedPaths,
  "/settings" => Api::SettingsController,
  "/notifications" => Api::NotificationController,
  "/features" => Api::FeatureController,
  "/events" => Api::EventController
})

ap Settings.all_settings