require_relative 'cron_service'
# Class for stand-alone self monitoring service
# WARNING: BLOCKING!
# Class must be overridden with activity check...
class CronActivity
  def initialize(args)
    @name = args[:name]
    @max_count = args[:max_count]
    @period = args[:period]
    @function = args[:function]
    @service = CronService.new(args)
    @sample_time = args[:sample]
    raise "Must supply all CronActivity params" unless @name && @max_count && @period && @function && @sample_time
  end

  def check_for_activity
    fail NotImplementedError, "You must override this method in your implementation class"
  end

  def perform!
    while true
      begin
        p "Polled #{@name} at @#{Time.now}"
        result = check_for_activity
        @service.notify(result) if result
      rescue => ex
        puts "EX : --- Cronner Failed! ---"
        puts "EX : #{ex.message} #{ex.backtrace.join('\n\t     ')}"
      end
      sleep(@sample_time)
    end
  end
end
