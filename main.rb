require 'pp'
require 'pocket'
require 'open-uri'
require 'yaml'
require 'active_support'
require 'active_support/core_ext'

require 'bundler/setup'
Bundler.require

def get_archive(client)
  items = []
  offset = 0
  count = 200

  begin
    loop do
      info = client.retrieve(:detailType => :complete, :state => 'archive', :offset => offset, :count => count)

      break if info["list"].empty?
      items += info["list"].values

      # info["list"].values.each do |e|
      #   puts "#{e['item_id']}, #{e['given_title']}, #{e['resolved_title']}, #{e['resolved_url']}"
      # end

      offset += count

      sleep 1
    end
  ensure
    puts items.to_yaml
  end
end

def archive_old(client)
  items = []
  offset = 0
  count = 200

  loop do
    info = client.retrieve(
      :detailType => :simple,
      :state => 'unread',
      :sort => 'oldest',
      :offset => offset,
      :count => count
      )

    break if info["list"].empty?

    items = info["list"].values.select do |e|
      e['time_added'].to_i < (Time.now - 1.months).to_i
    end

    break if items.empty?
    
    # items.each do |e|
    #   puts "#{e['item_id']}, #{e['given_title']}, #{e['resolved_title']}, #{e['resolved_url']}, #{Time.at(e['time_added'].to_i)}"
    # end

    ids = items.map { |e| e['item_id'] }
    actions = ids.map do |e|
      { action: 'archive', item_id: e }
    end

    client.modify(actions)

    offset += count

    sleep 1
  end
end

yaml = YAML.load_file('config.yaml')
consumer_key = yaml['pocket']['consumer_key']
access_token = yaml['pocket']['access_token']

Pocket.configure do |config|
  config.consumer_key = consumer_key
end

client = Pocket.client(:access_token => access_token)

# get_archive(client)
# archive_old(client)
