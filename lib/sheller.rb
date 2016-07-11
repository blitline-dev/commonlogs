require 'open3'

# Extender for running shell commands
module Sheller
  MAX_LIST_SIZE = 50_000

  def execute_shell_command(cmd_string, with_context = false)
    results = nil
    start_time = Time.now.to_f
    LOGGER.log "Start cmd '#{cmd_string}'"
    Open3.popen3(cmd_string) do |_stdin, stdout, stderr, _wait_thr|
      output = stdout.read
      output_error = stderr.read
      handle_output_error(output_error)
      results = parse_results(output, with_context)
    end
    end_time = Time.now.to_f
    LOGGER.log "Finished after: #{end_time - start_time} seconds"

    return results
  end

  def handle_output_error(output_error)
    if output_error && !output_error.empty?
      LOGGER.log(output_error)
      fail output_error
    end
  end

  def parse_results(results, _wait_thrh_context)
    rows = []
    begin
      rows = results.gsub("\n--\n", "").split(/\r?\n|\r/)
    rescue
      results = results.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      rows = results.gsub("\n--\n", "").split(/\r?\n|\r/)
    end

    if rows.length >= MAX_LIST_SIZE
      rows << "\r\n WARNING: List truncated at #{MAX_LIST_SIZE} lines..."
    end

    return rows
  end
end
