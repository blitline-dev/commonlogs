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

  def delete
    filepath = Tags.event_folder(@tag, @event.strip) + "/notification.json"
    File.delete filepath
  end

end

