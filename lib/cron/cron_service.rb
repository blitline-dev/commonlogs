# Class for managing notifications with max counts/time period
class CronService

  def initialize(args)
    @notifications = []
    @name = args[:name]
    @max_count = args[:max_count]
    @max_count = @max_count.to_i if @max_count
    @period = args[:period]
    @period = @period.to_i if @period
    @function = args[:function]
    raise "Must supply all CronService params" unless @name && @max_count && @period && @function
  end

  def notify(data)
    prune_old
    if @notifications.length < @max_count
      @notifications << Time.now.to_i
      @function.call(data)
    end
  end

  private

  def prune_old
    @notifications.delete_if { |notification| (Time.now.to_i - notification) > @period }
  end

end
