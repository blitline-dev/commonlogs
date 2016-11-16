module Api
  # -------------------------------
  # API for Features
  # -------------------------------
  class FeatureController < CommonLogsBase

    get '/tail' do
      content_type :json
      line_prefix = params['last_prefix']

      search = Search.new(params['name'])
      results = search.latest(line_prefix)
      latest = results[:data]
      file = results[:file]

      syslog_format(latest, file)
      latest.to_json
    end

    get '/context_data' do
      content_type :json

      name = params['name'].strip
      seq = params['seq'].strip
      server = params['server'].strip
      file = params['file'].to_s.strip
      time = params['time'].to_s.strip

      search_text = [time, seq, server, name].join(" ")
      search = Search.new(name, true)
      latest = search.context(file, search_text)

      syslog_format(latest, file)
      latest.to_json
    end

    get '/search' do
      request.env['HTTP_ACCEPT_ENCODING'] = 'gzip'
      count = 0
      hours = params['hours']
      query = params["q"]

      search = Search.new(params['name'])
      p = params["p"] || 0
      latest = []
      results = {}

      _time = Util.measure_delta do
        results = search.search(query, hours, p.to_i)
        latest = results[:data]
        syslog_format(latest, nil)
      end

      _time = Util.measure_delta do
        latest.each do |row|
          count += row[3].scan(query).count(query)
          row[3] = wrap_query_term_with_spans(row[3], query)
        end
      end

      results[:data] = latest
      results[:count] = count
      results.to_json
    end
  end
end