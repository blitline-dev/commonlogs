require_relative 'tags'
require_relative 'util'
require_relative 'sheller'
require_relative 'notifier'
require 'time'
require 'thread'

class Notification
  include Sheller

  def initialize(tag, event)
    raise "Must have a tag and event for Notification" unless tag && event
    @tag = tag
    @event = event
  end

  def create_file(data)
    filepath = Tags.event_folder(@tag, @event.strip) + "/notification.json"
    File.open(filepath, "w") do |f|
      f.write(data.to_json)
    end
    return { success: true }
  end

  def read_file_data
    filepath = Tags.event_folder(@tag, @event.strip) + "/notification.json"
    return {} unless File.exist?(filepath)
    JSON.parse(IO.read(filepath))
  end

  def self.run_all_notifications
    log_groups = Tags.list
    log_groups.each do |log_group|
      ecm = EventConfigManager.new(log_group)
      events = ecm.events
      events.each do |event|
        base_event_folder = Tags.event_folder(log_group, event.strip)
        filepath = base_event_folder + "/notification.json"
        if File.exist?(filepath)
          #Thread.new do
            p "New Thread > Running Notifier.new(#{[log_group, event, base_event_folder]})"
            notifier = Notifier.new(log_group, event, base_event_folder)
            notifier.run
          #end
        end
      end
    end
  end

end

