require 'open3'
require 'ansi-to-html'

# Extender for running shell commands
module Sheller
  MAX_LIST_SIZE = 50_000

  def raw_shell(cmd_string)
    output = ""
    Open3.popen3(cmd_string) do |_stdin, stdout, _stderr, _wait_thr|
      output = stdout.read
    end
    return output
  end

  def execute_shell_command(cmd_string)
    results = nil
    start_time = Time.now.to_f
    LOGGER.log "Start cmd '#{cmd_string}'"
    Open3.popen3(cmd_string) do |_stdin, stdout, stderr, _wait_thr|
      output = stdout.read
      output_error = stderr.read
      handle_output_error(output_error)
      results = parse_results(output)
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

  def handle_escape(s)
    as = Ansi::To::Html.new(s)
    return as.to_html(:tango)
  end

  def parse_results(results)
    rows = []
    begin
      results = handle_escape(results)
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

# Override Ansi styles, we need to add iterim 'tags' to replace later
# in javascript on the client.
module Ansi
  module To
    class Html
      def push_tag(tag, style = nil)
        style = STYLES[style] || PALLETE[@pallete || :linux][style] if style && !style.include?(':')
        @stack.push tag
        "[[[#{tag}:#{style}]]]"
      end

      def reset_styles
        stack, @stack = @stack, []
        stack.reverse.map { |tag| "[[[#{tag}]]]" }.join
      end
    end
  end
end