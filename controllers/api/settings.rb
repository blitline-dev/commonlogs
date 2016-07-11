module Api
  # -------------------------------
  # API for Notifications
  # -------------------------------
  class SettingsController < CommonLogsBase

    post '' do
      data = map_settings
      Settings.set("autodelete", data[:autodelete])
      Settings.set("selflog", data[:selflog])
      Settings.set("iam_key", data[:iam_key]) if data[:iam_key]
      Settings.set("iam_secret", data[:iam_secret]) if data[:iam_secret]
      Settings.set("bucket", data[:bucket]) if data[:bucket]
      Settings.set("location", data[:location])
      Settings.set("key_prefix", data[:key_prefix])
      Settings.save
      data.to_json
    end

    private

    def map_settings
      data = {}
      data[:autodelete] = params[:autodelete]
      data[:iam_key] = params[:iam_key]
      data[:iam_secret] = params[:iam_secret]
      data[:bucket] = params[:bucket]
      data[:location] = params[:location]
      data[:selflog] = params[:selflog]
      data[:key_prefix] = params[:key_prefix]

      return data
    end

  end
end