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
class StatisticItem
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include Mongoid::Enum
  include Mongoid::FullTextSearch

  field :timestamp, type: Integer
  field :data, type: Hash
  field :customers, type: Array
  field :users, type: Array
  field :text_marker

  validates :timestamp, presence: true
  validates :data, presence: true

  index({ timestamp: 'text' })

  fulltext_search_in :text_marker, :index_customers => 'broadly_search',
    :filters => {
      :customers => lambda { |event| event.customer }
    }

  scope :active, -> { where(timestamp: StatisticItem.max(:timestamp)) }
  enum :status, %i[ empty fill ]
end
Thread.new do
  p 'run items generator'
  loop do
    events_item = StatisticItem.create({timestamp: Time.now.to_i, data: {'data' => nil}})
    if StatisticItem.first
      StatisticItem.offset[-2].delete if StatisticItem.offset[-2].empty?
    end
    events_item.timestamp = Time.now.to_i
    sleep 60
  end
end
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
      events_item = StatisticItem.active.last
      p events_item.timestamp
      events_item.fill!
      events_item.text_marker = timestamp.to_s
      events_item.data[timestamp.to_s] = JSON.parse(params[:events])
      events_item.data.delete('data')
      customers = []
      customers << events_item.data.map{|event|customer = event[1]['customers']; {customer.keys[0] => {event[0] => customer.values[0]['status']}}}
      p 'customers', customers
      events_item.customers = customers.flatten if customers
      users = []
      users << events_item.data.map{|event|users = event[1]['users']}
      p 'users', users
      events_item.users = users if users
      begin
        events_item.save
      rescue StandardError => e
        p 'error', e, events_item.data[timestamp.to_s]
      end
    end
  end
end

namespace '/api/v2' do
  before do
    content_type 'application/json'
  end

  # Serializers
  class StatisticSerializer
    def initialize(user, customer)
      @user, @customer = user, customer
    end

    def as_json(*)
      data = {
        id:@customer.id.to_s,
        title:@customer.title,
        author:@customer.author,
        isbn:@customer.isbn
      }
      data[:errors] = @book.errors if@book.errors.any?
      data
    end
  end

  post '/get_data' do
    Thread.new do
      user = params[:user]
      customers = params[:customers]
      earliest_date = params[:earliest_date]
      latest_date = params[:latest_date]

      customers = customers||StatisticItem.where({:timestamp.gte => earliest_date.to_i, :timestamp.lte => latest_date.to_i})
      begin
        events_item.save!
      rescue StandardError => e
        p 'error', e, events_item.data[timestamp.to_s]
      end
    end
  end


end
# end

#params = { :events => { :customers => { }, :users => [] } }; rand(1..6).times{ cust = customers.sample; params[:events][:customers][cust['id'].to_s] = cust;  params[:events][:users] << cust['user_id'].to_s }