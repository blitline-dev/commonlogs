module Api
  # -------------------------------
  # API for Notifications
  # -------------------------------
  class SettingsController < CommonLogsBase

    post '' do
      data = map_settings
      Settings.set("autodelete", data[:autodelete]) unless data[:autodelete].nil?
      Settings.set("selflog", data[:selflog]) unless data[:selflog].nil?
      Settings.save
      data.to_json
    end

    post 'aws' do
      Settings.set("iam_key", data[:iam_key]) if data[:iam_key]
      Settings.set("iam_secret", data[:iam_secret]) if data[:iam_secret]
      Settings.set("bucket", data[:bucket]) if data[:bucket]
      Settings.set("location", data[:location]) 
      Settings.set("key_prefix", data[:key_prefix])
    end

    delete 'aws' do
      Settings.set("iam_key", nil)
      Settings.set("iam_secret", nil) 
      Settings.set("bucket", nil)
      Settings.set("location", nil)
      Settings.set("key_prefix", nil)
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