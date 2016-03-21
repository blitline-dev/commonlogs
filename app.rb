require 'sinatra'
require 'sinatra/reloader' if development?
configure { set :server, :puma }

require 'time'
require 'base64'
require 'json'
require 'digest/sha1'
require 'oj'
require 'slim'
require 'awesome_print'

require_relative 'lib/tags'
require_relative 'lib/search'
require_relative 'lib/event'
require_relative 'lib/sheller'
require_relative 'lib/util'
require_relative 'lib/event_config_manager'

# Listen to all non-localhost requests
set :bind, '0.0.0.0'
set :timeout, 2

before do
  response.headers['X-Frame-Options'] = 'ALLOW-FROM http://localhost/'
end

get '/' do
  variables = { foo: "bar" }
  variables.to_json
end

get '/context' do
  tags = Tags.list
  unless params['name']
    tag = tags.first
    redirect "/li_home?name=#{tag}"
    return
  end
  name = params['name'].strip
  time = params['time'].strip.tr!(" ", "+")
  seq = params['seq'].strip
  server = params['server'].strip
  file = params['file'].to_s.strip

  search_text = [time, seq, server, name].join(" ")
  search = Search.new(name)
  latest = search.context(file, search_text)
  syslog_format(latest, file)
  variables = { count: 0, tags: tags, name: name, seq: seq, latest: latest }.merge(display_variables)
  slim :context, locals: variables
end

get '/li_home' do
  tags = Tags.list
  unless params['name']
    tag = tags.first
    redirect "/li_home?name=#{tag}"
    return
  end
  variables = { tags: tags }.merge(display_variables)
  slim :li_home, locals: variables
end

get '/events' do
  tags = Tags.list
  unless params['name']
    tag = tags.first
    redirect "/events?name=#{tag}"
    return
  end

  variables = { tags: tags, count: 0 }.merge(display_variables)
  slim :events, locals: variables
end

# JSON API calls
get '/tail' do
  content_type :json
  line_prefix = params['last_prefix']

  search = Search.new(params['name'])
  results = search.latest(line_prefix)
  latest = results[:data]
  file = results[:file]

  syslog_format(latest, file)
  latest.to_json
end

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
  if events[:data] && events[:data].length > 0
    syslog_format(events[:data], nil)
  else
    events[:data] = []
  end
  events[:data].to_json
end

get '/search' do
  request.env['HTTP_ACCEPT_ENCODING'] = 'gzip'
  count = 0
  hours = params['hours']
  query = params["q"]
  search = Search.new(params['name'])
  p = params["p"] || 0
  latest = []
  results = {}

  time = Util.measure_delta do
    results = search.search(query, hours, p.to_i)
    latest = results[:data]
    syslog_format(latest, nil)
  end
  puts "Search events = #{time}"

  time = Util.measure_delta do
    latest.each do |row|
      count += row[3].scan(query).count(query)
      row[3] = wrap_query_term_with_spans(row[3], query)
    end
  end
  puts "Search latest events = #{time}"

  results[:data] = latest
  results[:count] = count

  puts "returning..."
  results.to_json
end

get '/event_manager' do
  tags = Tags.list
  unless params['name']
    tag = tags.first
    redirect "/event_manager?name=#{tag}"
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
  redirect "/event_manager?name=#{log_group}"
end

post '/events' do
  event_name = params['event_name']
  search = params['search']
  color = params['color']
  description = params['description']
  puts "dasjkfh dasfkadfsafksdhkj"
  log_group = params['name']

  event_manager = EventConfigManager.new(log_group)
  event_manager.create!(event_name.strip,
                        "event_name"  => event_name.strip,
                        "color"       => color.strip,
                        "search"      => search.strip,
                        "description" => description.strip)
  redirect "/event_manager?name=#{log_group}"
end

private

  def handle_latest_results(tags, search, line_prefix = nil)
    results = search.latest(line_prefix)
    latest = results[:data]
    file = results[:file]

    syslog_format(latest, file)

    { tags: tags, latest: latest, count: 0 }.merge(display_variables)
  end

  def handle_search_results(tags, search, hours)
      count = 0
      query = params["q"]
      results = search.search(query, hours)
      latest = results[:data]
      syslog_format(latest, nil)

      latest = []
      latest.each do |row|
        count += row[3].scan(query).count(query)
        row[3] = wrap_query_term_with_spans(row[3], query)
      end

      { tags: tags, latest: latest, count: count }.merge(display_variables)
  end

  def wrap_query_term_with_spans(text, query)
    return text.gsub(query, "<span class='fructy'>#{query}</span>") if text

    return text
  end

  def syslog_format(rows, file)
    # We only care about metadata. We have fixed length
    # for most of it, so lets trim whole line and just split
    # on spaces (we want to make sure we aren't splitting the raw msg)
    # text because that could be looong and resource
    # intensive).
    # Metadata should be time(26) + sequence (6) + host(max64) + tag(max64)
    time = Util.measure_delta do
      rows.map! do |row|
        if row.start_with?(RocketLog::Config::DEST_FOLDER)
          recursize_grep_row(row)
        else
          simple_grep_row(row, file)
        end
      end
    end
    puts "SYSLOG FORMAT delta = #{time}"
  end

  def simple_grep_row(row, file)
      metadata = row[0..180]
      sub_elements = metadata.split(" ")
      date = sub_elements[0]
      seq = sub_elements[1]
      host = sub_elements[2]
      tag = sub_elements[3]

      meta_size = [date, seq, host, tag].join(" ").length + 1
      rest = row[meta_size..-1]

      [date, seq, host, rest, file]
  end

  def recursize_grep_row(row)
      file = row[0..(row.index(":") - 1)]
      row[0..row.index(":")] = ""

      simple_grep_row(row, File.basename(file))
  end

  def display_variables
    {
      name: params['name'],
      hours: params['hours'] || 2,
      q: params["q"]
    }
  end