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
      validate_notification
      data = {
        name: params['name'],
        event_name: params['event'],
        notify_max: params['notifyMax'],
        notify_after: params['notifyAfter'],
        type: "webhook",
        type_data: {
          webhook: params['webhookUrl'],
          context: params['context']
        }
      }

      notification = Notification.new(params['name'], params['event'])
      results = notification.create_file(data)
      results.to_json
    end

    private

    def validate_notification
      raise "Invalid data" unless params['webhookUrl'] && params['name'] && params['event'] && params['notifyMax'] && params['notifyAfter']
    end

  end
end