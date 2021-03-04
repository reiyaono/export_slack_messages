require 'faraday'
require "json"
require 'time'
require 'csv'

BASE_URL = 'https://slack.com'
END_POINT = 'api/conversations.history'
USER = { }
AUTH_KEY = ''
CHANNEL_ID = ''
HEADERS = ['time', 'user', 'text']


def connection
  Faraday.new(url: BASE_URL) do |faraday|
    faraday.adapter Faraday.default_adapter
    faraday.options[:open_timeout] = 10
    faraday.options[:timeout] = 10
  end
end

def call_api
  connection.post do |request|
    request.url END_POINT
    request.params['channel'] = CHANNEL_ID
    request.params['cursor'] = @has_more
    request.headers['Authorization'] = "Bearer #{AUTH_KEY}"
  end
end

def messages
  messages_body = JSON.parse(call_api.body, symbolize_names: true)
  @has_more = messages_body[:response_metadata] && messages_body[:response_metadata][:next_cursor]
  messages_arr = []
  messages_body[:messages].each do |message|
    time =  Time.at(message[:ts].to_i).strftime('%Y-%m-%d %H:%M:%S')
    user = USER[message[:user].to_sym]
    text = message[:text]
    messages_arr << [time, user, text]
  end
  export_to_csv(messages_arr)
  messages unless @has_more.nil?
end

def export_to_csv(messages_arr)
  file_path = 'messages.csv'
  create_csv(file_path) unless File.exists?(file_path)
  CSV.open(file_path, 'a', headers: HEADERS, write_headers: true, force_quotes: true, encoding: 'utf-8') do |csv|
    messages_arr.each do |message|
      csv << message
    end
  end
end

def create_csv(file_path)
  first_row = CSV.generate_line([Time.now.strftime('%F %T'), 'test'], force_quotes: true)
  File.write(file_path, first_row, mode: 'wb')
end

messages