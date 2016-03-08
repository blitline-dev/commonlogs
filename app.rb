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

# Listen to all non-localhost requests
set :bind, '0.0.0.0'
set :timeout, 2

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

get '/li_home' do
  tags = Tags.list
  unless params['name']
    tag = tags.first
    redirect "/li_home?name=#{tag}"
    return
  end

  search = Search.new(params['name'])

  if params["q"]
    hours = params['hours'] || 2
    variables = handle_search_results(tags, search, hours)
  else
    variables = handle_latest_results(tags, search)
  end

  slim :li_home, locals: variables
end

get '/events' do
  tags = Tags.list
  unless params['name']
    tag = tags.first
    redirect "/li_home?name=#{tag}"
    return
  end

  variables = { tags: tags, count: 0 }.merge(display_variables)
  slim :events, locals: variables
end

get '/event_list' do
  search = Search.new(params['name'])
  events = search.events(params['hours'].to_i)
  events.to_json
end

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
  rows.map! do |row|
    if row.start_with?(RocketLog::Config::DEST_FOLDER)
      recursize_grep_row(row)
    else
      simple_grep_row(row, file)
    end
  end
end

def simple_grep_row(row, file)
    metadata = row[0..180]
    sub_elements = metadata.split(" ")
    date = sub_elements[0]
    seq = sub_elements[1]
    host = sub_elements[2]
    tag = sub_elements[3]

    meta_size = [date, seq, host, tag].join(" ").length
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
