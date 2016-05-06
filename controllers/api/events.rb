module Api
  # -------------------------------
  # API for Events
  # -------------------------------
  class EventController < CommonLogsBase
    get '/event_counts' do
      event = Event.new(params['name'])
      events = nil
      time = Util.measure_delta do
        start_timestamp = params['st']
        end_timestamp = params['et']
        hours = params['hours']

        start_timestamp = start_timestamp.to_i if start_timestamp
        end_timestamp = end_timestamp.to_i if end_timestamp

        start_timestamp = Time.now.to_i - (3600 * hours.to_i) if hours

        events = event.event_and_counts(start_timestamp, end_timestamp)
      end
      puts "Delta events = #{time}"
      events.to_json
    end

    get '/event_list' do
      event = Event.new(params['name'])
      start_timestamp = params['st']
      end_timestamp = params['et']
      hours = params['hours']
      page = params['page']

      fail "Page required" unless page

      start_timestamp = start_timestamp.to_i if start_timestamp
      end_timestamp = end_timestamp.to_i if end_timestamp

      start_timestamp = Time.now.to_i - (3600 * hours.to_i) if hours

      events = event.event_list_console(params['event_name'], start_timestamp, end_timestamp, page)

      if events[:data] && !events[:data].empty?
        syslog_format(events[:data], nil)
      else
        events[:data] = []
      end
      events[:data].to_json
    end

    get '' do
      event_manager = EventConfigManager.new(params['name'])
      data = event_manager.get_event_preference(params['name'], params['event'])
      data.to_json
    end

  end
end