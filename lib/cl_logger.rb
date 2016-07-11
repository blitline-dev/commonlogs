# ------------------
# Custom Logger
# ------------------
class CLLogger
  # --------------
  # Custom Logger
  # This isn't meant to meaningfully handle STDOUT,
  # but rather track 'important' items. Avoids problems
  # with outputting to STDOUT AND differing log files,
  # as well as issues with attaching/detaching STDOUT
  # which can cause problems with servers like PUMA/PASSENGER.
  # ---------------
  def initialize
    @counter = 0
    @ip = 'localhost'
    @name = 'commonlogs'
    @folder_name = 'cl_web_logs'
  end

  def log(object, prefix = nil)
    if object.is_a? Exception
      backtrace_array = object.backtrace
      backtrace_array.reject! { |x| x =~ /\.rvm/ }
      backtrace_array.unshift(object.message.to_s)
      write_to_destination(backtrace_array.inspect, "Exception: ")
    elsif object.is_a?(Hash) || object.is_a?(Array)
      write_to_destination(object.inspect, prefix)
    elsif object.is_a?(String)
      write_to_destination(object, prefix)
    end
  end

  def error(object)
    log(object, "Error: ")
  end

  private

  def write_to_destination(output_string, prefix)
    prefix ||= ""
    unless Settings.get('selflog').to_s.casecmp("false") == 0
      dirname = CommonLog::Config.destination_folder + "/#{@folder_name}"
      assure_folder_exists(dirname)
      file_path = "#{dirname}/" + Util.filename_from_time(Time.now)
      format_output_as_syslog(file_path, prefix + output_string)
      prefix = "Logged: "
    end
    puts prefix + output_string unless ENV['CL_SUPPRESS_OUTPUT'].to_s == "true"
  end

  def format_output_as_syslog(file_path, output_string)
    @counter += 1
    @counter = 0 if @counter > 999_999_999
    output_string.gsub!('\n', ' ')
    final_string = [Time.now.to_i.to_s, @counter, @ip, @name, output_string].join(" ")
    open(file_path, 'a') do |f|
      f.puts final_string
    end
  end

  def assure_folder_exists(dirname)
    Util.cl_mkdir_p(dirname) unless File.directory?(dirname)
  end
end

LOGGER = CLLogger.new
