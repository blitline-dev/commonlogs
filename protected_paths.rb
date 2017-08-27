require_relative 'common_logs_base'

# Basic paths with Auth support
class ProtectedPaths < CommonLogsBase
  register SinatraMore::MarkupPlugin

  get '/stats' do
    tags = Tags.list
    stats = Tags.file_stats
    drives = Tags.drive_space
    host_data = Hosts.recent_data
    has_collectd = host_data.any? { |h| !h.cpu.nil? }
    variables = { tags: tags, event_name: params['event_name'], stats: stats, drives: drives, host_data: host_data, has_collectd: has_collectd }.merge(display_variables)
    slim :stats, locals: variables
  end

  get '/settings' do
    tags = Tags.list
    settings = Settings.all_settings["settings"]
    log_life = settings["log_life"] || 168
    puts "Settings = #{log_life.to_i}"
    variables = {  tags: tags, event_name: params['event_name'], settings: settings, log_life: log_life.to_i }.merge(display_variables)
    slim :settings, locals: variables
  end

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
      tag = (name_cookie && !name_cookie.empty?) ? name_cookie : tags.first
      redirect "/p/li_home?name=#{tag}"
      return
    end
    save_name_cookie(params['name'])
    variables = { tags: tags }.merge(display_variables)
    slim :li_home, locals: variables
  end

  get '/events' do
    tags = Tags.list
    unless params['name']
      tag = name_cookie ? name_cookie : tags.first
      redirect "/p/events?name=#{tag}"
      return
    end

    save_name_cookie(params['name'])
    variables = { tags: tags, count: 0 }.merge(display_variables)
    slim :events, locals: variables
  end

  get '/event_manager' do
    tags = Tags.list
    unless params['name']
      tag = name_cookie ? name_cookie : tags.first
      redirect "/p/event_manager?name=#{tag}"
      return
    end
    event = EventConfigManager.new(params['name'])
    data = event.get_events_preferences(params['name'])
    save_name_cookie(params['name'])
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

  post '/tag_delete' do
    puts params.inspect
    sleep 3
    tag_name = params['tag']
    Tags.delete(tag_name)
    redirect "/p/settings"
  end

  post '/events' do
    event_name = params['event_name']
    search = params['search']
    color = params['color']
    description = params['description']
    log_group = params['name']

    event_manager = EventConfigManager.new(log_group)
    event_manager.create!(
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


