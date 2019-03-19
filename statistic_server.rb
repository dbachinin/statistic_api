#!/usr/bin/env ruby
require 'sinatra'
require 'rubygems'
require 'mongoid'
require 'mongoid/enum'
require 'sinatra/namespace'
require 'mongoid_fulltext'

# before do
#   # request.body.rewind
#   p request.body.read
# end
# class HIFCStatistic < Sinatra::Base
# DB Setup
Mongoid.load! "config/mongoid.yml"

# Models
# class StatisticItem
#   include Mongoid::Document
#   include Mongoid::Timestamps
#   include Mongoid::Attributes::Dynamic
#   include Mongoid::Enum
#   include Mongoid::FullTextSearch

#   field :timestamp, type: Integer
#   # field :data, type: Hash
#   field :customers, type: Hash
#   field :leads, type: Hash
#   field :appointments, type: Hash
#   field :users, type: Hash
#   field :text_marker

#   has_many :events #, inverse_of: :statistic_item

#   validates :timestamp, presence: true
  

#   index({ timestamp: 'text' })

#   # fulltext_search_in :text_marker, :index_customers => 'broadly_search',
#   #   :filters => {
#   #     :customers => lambda { |event| event.customer }
#   #   }

#   scope :active, -> { where(timestamp: StatisticItem.max(:timestamp)) }
#   enum :status, %i[ empty fill ]
# end

class Event
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include Mongoid::FullTextSearch

  index({ created_at: 1 },{ background: true })

end
def manage_indexes(operation)
  if operation == 'created_at'
    Event.create_indexes
  elsif operation == 'dynamic_fields'
    Thread.new do
      client = Mongo::Client.new([ 'localhost:27017' ], :database => "hifc_statistic_dev", :server_selection_timeout => 5)
      events = client[:events]
      events_fields = events.find.map{|events|events.keys}.map{|k| k.select{|i|!i.match(/_id|updated_at|created_at|timestamp/)}}.flatten.uniq #get all dynamic fields
      nested_fields = events_fields.map{|field| events.find.map{|events|events[field] }.compact.flatten.map{|i| i.keys.select{|f|f.match(/status|_id|is_|_at/)}}.uniq.flatten.map{|f| field + '.' + f } }
      nested_fields.each{|a|
        a.each{|f|
          events.indexes.create_many([
            { key: {f.to_sym => 1 } }
          ])
        }
      }
      regexp = events_fields.join('|')
      relation_fields = nested_fields.map{|i|i.select{|s|s.split('.').last.match(/#{regexp}/)}}.flatten
      status_fields = nested_fields.map{|i|i.select{|s|s.split('.').last.match(/status/)}}.flatten
    end
  end
end
# get_mode = ENV.fetch("mode") == 'cli' rescue false
# p get_mode ? 'runing in cli' : 'runing in without cli'
# unless get_mode
#   Thread.new do
#     p 'run items generator'
#     loop do
#       events_item = StatisticItem.create({timestamp: Time.now.to_i})
#       p 'Generate StatisticItem' + events_item._id.to_s
#       if StatisticItem.offset[-2]
#         StatisticItem.offset[-2].delete unless StatisticItem.offset[-2].fill?
#       end
#       events_item.timestamp = Time.now.to_i
#       sleep 60
#     end
#   end
# end
# Endpoints
set :bind, '0.0.0.0'
get '/' do
  ""
end
namespace '/api/v1' do
  before do
    content_type 'application/json'
  end

  post '/pass_data' do
    Thread.new do
      timestamp = Time.now.to_i
      data = JSON.parse(params[:events])
      event = Event.create({timestamp: timestamp })
      event_models = data.keys.map{|k|{plural: k, singular: k.singularize} }
      event_models.each do |model|
        begin
          data_model = data[model[:plural]]
          data_model.map{|item| item['_id'] = item.delete('id') }
          event[model[:singular]] = data_model
          event.write_attribute(model[:singular], data_model)
          event.save
        rescue StandardError => e
          p 'error', e
        end
      end
    end
  end
end

namespace '/api/v2' do
  before do
    content_type 'application/json'
  end

  #plural to singular
  # Serializers
  class StatisticSerializer
    def initialize(user=nil, customer, date_start, data_end)
      @user, @customer, @date_start, @data_end = user, customer, date_start, data_end
    end

    def as_json(*)
      data = {
        id:@customer.id.to_s,
        title:@customer.title,
        author:@customer.author,
        isbn:@customer.isbn
      }
    end
  end

  class SerailisationActions
    
  end
  class PieSerializer
    def initialize(user=nil, customer, date_start, date_end, field)
      @user, @customer, @date_start, @date_end, @field = user, customer, date_start, date_end, field
    end

    def as_json(*)
      events = Event.where({:timestamp.gte => @date_start.to_i, :timestamp.lte => @date_end.to_i})
      variables = events.map{|i| i[@field]}.uniq.zip([nil]).to_h
      field_ratio = variables.each_with_object(Hash.new(0)) {|i, a| a[i.values[0]] += 1}

      data = {
        type: 'pie',
        data: field_ratio
      }
      data[:errors] = field_ratio.errors if field_ratio.errors.any?
      data
    end
  end

  post '/get_data' do
    Thread.new do
      user = params[:user]
      customers = params[:customers]
      earliest_date = params[:earliest_date]
      latest_date = params[:latest_date]
      type_request = params[:type_request]
      customers = customers||StatisticItem.where({:timestamp.gte => earliest_date.to_i, :timestamp.lte => latest_date.to_i})
      begin
        events_item.save!
      rescue StandardError => e
        p 'error', e, events_item.data[timestamp.to_s]
      end
    end
  end
end

#params = { :events => { :customers => { }, :users => [] } }; rand(1..6).times{ cust = customers.sample; params[:events][:customers][cust['id'].to_s] = cust;  params[:events][:users] << cust['user_id'].to_s }