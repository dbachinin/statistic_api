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


# class Event
#   include Mongoid::Document
#   include Mongoid::Timestamps
#   include Mongoid::Attributes::Dynamic
#   include Mongoid::FullTextSearch
#   include Mongoid::Enum
  
#   index({ created_at: 1 },{ background: true })
#   enum :status, %i[ empty fill ]
#   scope :customers, -> { all.map{ |event| event.customer } }
#   scope :active, -> { where(timestamp: StatisticItem.max(:timestamp)) }
#   scope :by_time, ->(earliest_date, latest_date, key1: nil, key1val: nil, key2: nil, key2val: nil, key3: nil, key3val: nil){
#     where({
#       :timestamp.gte => earliest_date.to_i, :timestamp.lte => latest_date.to_i,
#       key1 => key1val,
#       key2 => key2val,
#       key3 => key3val,
#       })
#     }
#   def self.create_indexes
#     super
#     Thread.new do
#       client = Mongo::Client.new([ 'localhost:27017' ], :database => "hifc_statistic_dev", :server_selection_timeout => 5)
#       collections = client.database.collection_names
#       collections.each do |collection|
#         DynamicCollection.init(collection.capitalize) unless eval("defined?(#{collection.capitalize})")
#         coll = client[collection]
#         coll_fields = coll.find.map{|coll|
#           coll.keys
#         }.map{|k| 
#           k.select{|i|!i.match(/_id|updated_at|created_at|timestamp/)}}.flatten.uniq #get all dynamic fields
#         nested_fields = coll_fields.map{|field| 
#           coll.find.map{|coll|
#             coll[field] 
#           }.compact.flatten.map{|i| 
#             i.keys.select{|f|
#               f.match(/status|_id|^id$|is_|_at|start/)
#               } if i.class.name == 'BSON::Document'}.uniq.flatten.map{|f| field + '.' + f if field && f} }
#         nested_fields.each{|a|
#           a.each{|f|
#             coll.indexes.create_many([
#               { key: {f.to_sym => 1 } }
#             ]) if f
#           }
#         }
#         # regexp = coll_fields.join('|')
#         # p nested_fields, coll_fields
#         # relation_fields = nested_fields.map{|i|i.select{|s|s.split('.').last.match(/#{regexp}/)}}.flatten if nested_fields.flatten.any?
#         # status_fields = nested_fields.map{|i|i.select{|s|s.split('.').last.match(/status/)}}.flatten if nested_fields.flatten.any?
#       end
#     end
#   end
# end

class String
  def ccap
    @i = 0;self.split(//).map{|i|@i +=1;@i == 1 ? i.upcase : i}.join
  end
end

class Event
  include Mongoid::Document
  field :name
  field :created, type: Mongoid::Boolean
end
class DynamicCollection
  @@client = Mongo::Client.new([ 'localhost:27017' ], :database => "hifc_statistic_dev", :server_selection_timeout => 5)
  @@collections = @@client.database.collection_names

  def self.get_all_collections
    @@collections.map(&:camelize)
  end

  def self.get_indexes(collection)
    eval("#{collection.camelize}").collection.indexes.to_a
  end

  def self.init_all
    @@collections.each do |collection|
      init(collection.camelize)
    end
  end

  def self.create_index(collection)
    collection = collection.gsub(/\//,'__').underscore
    DynamicCollection.init(collection.camelize) unless eval("defined?(#{collection.camelize})")
    coll = @@client[collection]
    coll_fields = coll.find.to_a[0..10].map{|coll|coll.keys.select{|i|i.match(/status|_id|^id$|is_|_at|start/)} }.flatten.uniq
    coll_fields.each{|f| coll.indexes.create_many([ { key: {f.to_sym => 1 } } ]) if f };
  end

  def self.create_indexes
    # super
    Thread.new do
      @@collections.each do |collection|
        DynamicCollection.init(collection.camelize) unless eval("defined?(#{collection.camelize})")
        coll = @@client[collection]
        coll_fields = coll.find.to_a[0..10].map{|coll|coll.keys.select{|i|i.match(/status|_id|^id$|is_|_at|start/)} }.flatten.uniq
        coll_fields.each{|f| coll.indexes.create_many([ { key: {f.to_sym => 1 } } ]) if f }
      end
    end
  end
  def self.get_exist(collection)
    @@collections.include?(collection)
  end
  def self.init(collection)
    klass = Class.new do
      include Mongoid::Document
      include Mongoid::Timestamps
      include Mongoid::Attributes::Dynamic
      store_in collection: collection.underscore
      coll = @@client[collection.underscore.to_sym]
      fields = coll.aggregate([
        { "$limit": 10 },
        {
          "$project":{
            "arrayofkeyvalue":{
              "$objectToArray":"$$ROOT"
            }
          }
        },
        {
        "$unwind":"$arrayofkeyvalue"
        },
        {
        "$project": {
          "_id": "$_id",
          "fieldKey": "$arrayofkeyvalue.k",
          "fieldType": {  "$type": "$arrayofkeyvalue.v"  }
          }
        },
        {"$match": {}},
        {"$group": {
          "_id": "$_id",
          "fields": {
            "$addToSet": {
              "$concat": ["$fieldKey",'%',"$fieldType"]
              }
            }
          }
        }], :allow_disk_use => true).to_a[-1]['fields'].map{|i|i.split('%')}.to_h
        store_in collection: collection.underscore
        # fields.merge(event_id: String)
        types = {
          array: Array,
          big_decimal: BigDecimal,
          binary: BSON::Binary,
          bool: Mongoid::Boolean,
          date: Date,
          float: Float,
          hash: Hash,
          int: Integer,
          objectId: BSON::ObjectId,
          range: Range,
          regexp: Regexp,
          set: Set,
          string: String,
          symbol: Symbol,
          time: Time
        }.with_indifferent_access
        fields.each do |k,v|
          field k, type: types[v]
        end
    end
    Object.const_set(collection, klass)
  end
  def self.create(collection, fields)
    klass = Class.new do
      include Mongoid::Document
      include Mongoid::Timestamps
      include Mongoid::Attributes::Dynamic
      store_in collection: collection.underscore
      fields.each do |item|
        field item[:name], type: item[:type]
      end
    end
    Object.const_set(collection, klass)
    Event.create!({name: collection, created: true})
  end
end
DynamicCollection.init_all
# get_mode = ENV.fetch("mode") == 'cli' rescue false
# p get_mode ? 'runing in cli' : 'runing in without cli'
# unless get_mode
#   Thread.new do
#     p 'run items generator'
#     loop do
#       events_item = Event.create({timestamp: Time.now.to_i})
#       p 'Event' + events_item._id.to_s
#       if Event.offset[-2]
#         Event.offset[-2].delete unless Event.offset[-2].fill?
#       end
#       events_item.timestamp = Time.now.to_i
#       sleep 60
#     end
#   end
# end
# Endpoints
# set :bind, '0.0.0.0'
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
      event_models = data.keys.reject{|i|i == 'nil_classes' }.map{|k|{plural: k, singular: k.gsub(/\//,'__').camelize.singularize} }
      event_models.each do |model|
        begin
          data_model = data[model[:plural]]
          if data_model.any?
            data_model = data_model.first.class.name == 'Array' ? data_model : [data_model]
            data_model.each{|i|i.map{|item| 
            item["self_#{model[:singular].underscore}_id"] = item.delete('id')
            item["self_#{model[:singular].underscore}_created_at"] = item.delete('created_at')
            item["self_#{model[:singular].underscore}_updated_at"] = item.delete('updated_at') }}
            created = Event.where(name: model[:singular]).first.try(:created)
            loaded = eval(model[:singular]) rescue false
            item_hash = {}
            data_model.flatten.each do |item|
              item_hash = item.map{|i|[i[0],[i[1].to_s,i[1].class.name]]}.to_h
              item_hash.each do |k,v|
                case v
                when ->(n){n[1] == "Fixnum" || (n[1] == "String" && n[0].include?('_id'))}
                  item_hash[k] = 'int'
                when ->(n){n[1] == 'Float'}
                  item_hash[k] = 'float'
                when ->(n){n[1] == "String" && Date.parse([n][0][0]) rescue false}
                  item_hash[k] = 'date'
                when ->(n){n[1] == "FalseClass" || n[1] == "TrueClass"}
                  item_hash[k] = 'boolean'
                when ->(n){n[1] == "Array"}
                  item_hash[k] = 'array'
                else
                  item_hash[k] = 'string'
                end
              end
            end
            unless created
              DynamicCollection.create(model[:singular], item_hash.map{|k,v|{:name => k, :type => v}})
              DynamicCollection.create_index(model[:singular])
            end
            DynamicCollection.init(model[:singular]) if created && !loaded
            klass = eval(model[:singular])
            data_model.flatten.each do |model_item|
              klass.create!(model_item)
            end
            # event.write_attribute(model[:singular], data_model.flatten)
            # event.save
          end
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
    def initialize(user=nil, klass=nil, date_start=nil, date_end=nil, querry, type)
      @user, @klass, @date_start, @date_end, @querry, @type = user, klass, date_start, date_end, querry, type
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


  class DataSerializer
    def initialize(data)
      @data = data
    end

    def as_json(*)
      data = []
      @data.flatten.each{|i|i.delete('_id') if i['_id'] == 'null'; data << i}
      data
    end
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
  class Integer
    def more_on_one(max_val)
      value = self != 0 ? ((self - 1) - (( (self - 1)/ max_val) * max_val)) : self 
      return value
    end
  end
  class Array
    def filling_data
      req = []
      self.each{|b|
        val = "\"#{b.values[0]}\""
        req = req.any? ? req.map{|r|r.gsub(/\\#{b.keys[0]}\\/, val)} : yield.map{|r|r.class.name == 'Hash' ? r.values[0].gsub(/\\#{b.keys[0]}\\/, val) : r.gsub(/\\#{b.keys[0]}\\/, val)} 
      }
      req
    end
  end


  post '/get_data/' do
    startime = Time.now.to_i
    requests = JSON.parse params[:req]
    param = JSON.parse params[:param]
    if param.try(:any?)
      out_data = []
      tmp_db_requests = []
      clean_db_requests = []
      keys =  param.map(&:keys).flatten.uniq
      keys_without_date = keys.reverse.reject{|i|i.match(/DATE/)}
      keys_count = keys_without_date.count
      empty_params = JSON.parse(requests).map{|r|r.scan(/\\([A-Z|A-Z_A-Z]+)\\/)}.flatten - keys
      builded_requests = {}
      keys_without_date.each_with_index{|v,i|
        builded_requests[v] = []
        param.select{|z|z[v]}.map(&:values).flatten.each{|r|
          builded_requests[v] << { r => ([{ v => r }].filling_data{ i != 0 ? builded_requests[keys_without_date[i.more_on_one(keys_count)]].flatten : JSON.parse(requests) }).to_json }
        } 
      }
      builded_requests = builded_requests[keys_without_date.last].flatten
p 'builded_requests', Time.now.to_i - startime
      if empty_params.any?
        empty_params.each do |key|
          clean_db_requests = clean_db_requests.any? ? clean_db_requests.map{|r| { r.keys[0] => r.values[0].gsub(/,\{.*"\$(.*)#{key}(.*?)\}\},/, ',').gsub(/\,\s?\W?\"[a-z|A-Z|_]+\W?\"\:\s{\W?"\$eq\W?":(.*)?#{key}(.*?)\W}/, '') } } : builded_requests.map{|r| { r.keys[0] => r.values[0].gsub(/,\{.*"\$(.*)#{key}(.*?)\}\},/, ',').gsub(/\,\s?\W?\"[a-z|A-Z|_]+\W?\"\:\s{\W?"\$eq\W?":(.*)?#{key}(.*?)\W}/, '') } }
        end
      else
        clean_db_requests = builded_requests
      end
      p 'clean_db_requests', Time.now.to_i - startime
      param.each do |pm|
        date = Time.parse(pm[pm.keys[0]]) && pm[pm.keys[0]].match(/^\d*-\d*-\d+/) rescue nil
        val = date ? "Time.parse('#{pm.values[0]}')" : "\"#{pm.values[0]}\""
        key = pm.keys[0]
        tmp_db_requests = tmp_db_requests.any? ? tmp_db_requests.map{|r| { r.keys[0] => r.values[0].gsub(/\\#{key}\\/, val) } } : clean_db_requests.map{|r| { r.keys[0] => r.values[0].gsub(/\\#{key}\\/, val)  } }
      end
      p 'tmp_db_requests', Time.now.to_i - startime, tmp_db_requests
      param.reject{|i|i.keys[0].match(/DATE/)}.each do |pm|
        request_key = pm.values[0]
        begin
          rq = JSON.parse(tmp_db_requests.select{|i|i.keys[0] == request_key}.first[request_key])
          result = rq.map{|r|eval(r)} #if eval("#{pm.keys[0].capitalize}").where("self_#{pm.keys[0].downcase}_id".to_sym => pm.values[0]).first
          pm[pm.keys[0].downcase] = pm.delete(pm.keys[0])
          out_data << pm.merge({result: result})
        rescue StandardError => exception
          err_message = [exception.message, exception.backtrace].join("\n")
          p err_message
          out_data << { result: err_message }
        end
      end
      p 'end', Time.now.to_i - startime
      return DataSerializer.new(out_data).to_json
    else
      return DataSerializer.new(eval(requests)).to_json
    end
  end
end

#params = { :events => { :customers => { }, :users => [] } }; rand(1..6).times{ cust = customers.sample; params[:events][:customers][cust['id'].to_s] = cust;  params[:events][:users] << cust['user_id'].to_s }