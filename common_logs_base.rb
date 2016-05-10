require 'sinatra'
require 'sinatra/reloader' if development?
require 'time'
require 'base64'
require 'json'
require 'digest/sha1'
require 'oj'
require 'slim'
require 'awesome_print'
require 'sinatra/content_for'

require_relative 'lib/tags'
require_relative 'lib/search'
require_relative 'lib/event'
require_relative 'lib/sheller'
require_relative 'lib/util'
require_relative 'lib/notification'
require_relative 'lib/event_config_manager'

# ----------------------------------
# Root app class that all controller
# level classes dervice from
# ----------------------------------
class CommonLogsBase < Sinatra::Base
  helpers Sinatra::ContentFor

  configure { set :server, :puma }

  # Listen to all non-localhost requests
  #set :bind, '0.0.0.0'
  set :timeout, 60

  # HELPERS
  helpers do
    def protected!
      return true if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401
    end

    def authorized?
      return true if ENV["CL_BASIC_AUTH_BYPASS"].to_s.casecmp("true") == 0
      halt_if_no_env
      return check_auth
    end

    def halt_if_no_env
      halt 403 if ENV["CL_BASIC_AUTH_USERNAME"].to_s.empty? && ENV["CL_BASIC_AUTH_BYPASS"].to_s.empty?
    end

    def check_auth
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      return @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [ENV["CL_BASIC_AUTH_USERNAME"], ENV["CL_BASIC_AUTH_PASSWORD"]]
    end
  end

  # -------------------------------
  # ROUTES
  # -------------------------------

  before do
    protected!
    response.headers['X-Frame-Options'] = 'ALLOW-FROM http://localhost/'
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
        if row.start_with?(CommonLog::Config::DEST_FOLDER)
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
    tag = Util.clean_html(sub_elements[3])

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

end

