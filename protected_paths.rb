require_relative 'common_logs_base'


# Basic paths with Auth support
class ProtectedPaths < CommonLogsBase

  get '/notification' do
    tags = Tags.list
    unless params['name'] && params['event_name']
      tag = tags.first
      redirect "/p/li_home?name=#{tag}"
      return
    end
    variables = { tags: tags, event_name: params['event_name'] }.merge(display_variables)
    slim :notification, locals: variables
  end

  get '/context' do
    tags = Tags.list
    unless params['name']
      tag = tags.first
      redirect "/p/li_home?name=#{tag}"
      return
    end
    name = params['name'].strip
    time = params['time'].strip
    seq = params['seq'].strip
    server = params['server'].strip
    file = params['file'].to_s.strip

    variables = { count: 0, tags: tags, name: name, seq: seq, file: file, server: server, time: time }.merge(display_variables)
    slim :context, locals: variables
  end

  get '/li_home' do
    tags = Tags.list
    unless params['name']
      tag = tags.first
      redirect "/p/li_home?name=#{tag}"
      return
    end
    variables = { tags: tags }.merge(display_variables)
    slim :li_home, locals: variables
  end

  get '/events' do
    tags = Tags.list
    unless params['name']
      tag = tags.first
      redirect "/p/events?name=#{tag}"
      return
    end

    variables = { tags: tags, count: 0 }.merge(display_variables)
    slim :events, locals: variables
  end

  get '/event_manager' do
    tags = Tags.list
    unless params['name']
      tag = tags.first
      redirect "/p/event_manager?name=#{tag}"
      return
    end
    event = EventConfigManager.new(params['name'])

    data = event.get_events_preferences(params['name'])
    variables = { name: params['name'], tags: tags, events: data }.merge(display_variables)
    slim :event_manager, locals: variables
  end

  post '/event_delete' do
    event_name = params['event_name']
    log_group = params['name']
    event_manager = EventConfigManager.new(log_group)
    event_manager.delete!(event_name)
    redirect "/p/event_manager?name=#{log_group}"
  end

  post '/notification_delete' do
    event_name = params['event_name']
    name = params['name']
    notification = Notification.new(name, event_name)
    notification.delete
    redirect "/p/event_manager?name=#{name}"
  end

  post '/events' do
      event_name = params['event_name']
      search = params['search']
      color = params['color']
      description = params['description']
      log_group = params['name']

      event_manager = EventConfigManager.new(log_group)
      event_manager.create!(
        event_name.strip,
        "event_name"  => event_name.strip,
        "color"       => color.strip,
        "search"      => search.strip,
        "description" => description.strip
      )

      redirect "/p/event_manager?name=#{log_group}"
    end

  error 403 do
    redirect to('/pages/403.html')
  end

end

