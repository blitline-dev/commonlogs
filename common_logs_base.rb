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
require 'sinatra/cookies'

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
  set :show_exceptions, false
  # Listen to all non-localhost requests
  set :timeout, 60
  configure { set :server, :puma }

  error do
    LOGGER.log "Sinatra Error: " + env['sinatra.error'].message
  end

  LAST_NAME_COOKIE = "last_saved_name".freeze

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

  def wrap_query_term_with_spans(text, query)
    if query && query.start_with?("/") && query.end_with?("/")
      query[0] = ""
      query[-1] = ""
    end

    return text.gsub(/(#{query})/i, "<span class='fructy'>\\1</span>") if text

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
        if row.start_with?(CommonLog::Config.destination_folder)
          recursize_grep_row(row)
        else
          simple_grep_row(row, file)
        end
      end
    end
    LOGGER.log "SYSLOG FORMAT delta = #{time}"
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

  def save_name_cookie(name)
    response.set_cookie(LAST_NAME_COOKIE, value: name, expires: Time.now + 31_557_600)
  end

  def name_cookie
    request.cookies[LAST_NAME_COOKIE]
  end

end

