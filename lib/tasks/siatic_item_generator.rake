require 'mongoid'
require "mongoid/enum"

task :static_item_generator do
    Mongoid.load! "config/mongoid.yml"
    events_item = StatisticItem.create({timestamp: Time.now.to_i, data: {data: nil}})
    StatisticItem.offset[-2].delete if StatisticItem.offset[-2].empty?
    events_item.timestamp = Time.now.to_i
    sleep 60
end