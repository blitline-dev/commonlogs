module Api
  # -------------------------------
  # API for Notifications
  # -------------------------------
  class NotificationController < CommonLogsBase

    delete ':name' do
      event_name = params['name']
      Notification.delete_by_name(event_name)
      results = { success: true }
      results.to_json
    end

    get '' do
      name = params['name']
      event = params['event']
      raise "must have name and event params" unless name && event
      notification_data = Notification.new(name, event).read_file_data
      notification_data.to_json
    end

    post '' do
      assure_base_params
      data = validate_notification
      notification = Notification.new(params['name'], params['event'])
      results = notification.create_file(data)
      results.to_json
    end

    private

    def assure_base_params
      raise "Must have name, event, and ntype" unless params['name'] && params['event'] && params['ntype']
    end

    def validate_notification
      data = {}
      data[:name] = params['name']
      data[:event_name] = params['event']
      data[:notify_max] = (params['notifyMax'] || 1).to_i
      data[:notify_after] = (params['notifyAfter'] || 1).to_i
      data[:ntype] = params['ntype']
      derive_type_data(data)

      return data
    end

    def derive_type_data(data)
      if params['ntype'] == 'webhook'
        webhook_data(data)
      elsif params['ntype'] == 'slack'
        slack_data(data)
      end
    end

    def slack_data(data)
      raise "Slack missing params" unless params['sw']
      data[:type_data] = {
        slack_webhook: params['sw']
      }
      data[:type_data][:context] = params['context']
    end

    def webhook_data(data)
      raise "Invalid data" unless params['webhookUrl']
      data[:type_data] = {
        webhook: params['webhookUrl']
      }
      data[:type_data][:context] = params['context']
    end

  end
end