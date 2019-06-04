require 'sinatra'
require 'rubygems'
require 'sinatra/activerecord'
require './environments'
require 'sinatra/namespace'

Rack::Utils.key_space_limit = 262_144
# module StatisticServer
ActiveRecord::Base.connection.enable_query_cache!
class CustomerStatus < ActiveRecord::Base
end
class HashSerializer
  def self.dump(hash)
    hash.to_json
  end

  def self.load(hash)
    (hash || {}).with_indifferent_access
  end
end

get '/' do
  ''
end
namespace '/api/v1' do
  before do
    content_type 'application/json'
  end

  post '/pass_data' do
    Thread.new do
      data = JSON.parse(params[:events])
      event_models = data.keys.reject { |i| i == 'nil_classes' }.map { |k| { plural: k, singular: k.gsub(%r{/}, '__').camelize.singularize } }
      event_models.each do |model|
        data_model = data[model[:plural]].first
        begin
          if data_model.any?
            cs = eval((model[:singular]).to_s).find_by(id: data_model['id'])
            if cs
              cs.as_json.each { |k, _v| cs[k] = data_model[k] }
              cs.update(data_model) if cs.changed?
            else
              eval((model[:singular]).to_s).create(data_model)
            end
          end
        rescue StandardError => e
          p 'error: ', e
          p "in lines #{e.backtrace.first.split("\n").first}\n#{e.backtrace.first.split("\n").last}"
        end
      end
    end
  end
end

namespace '/api/v2' do
  before do
    content_type 'application/json'
  end

  class DataSerializer
    def initialize(data)
      @data = data
    end

    def as_json(*)
      data = []
      @data.flatten.each { |i| i.delete('_id') if i['_id'] == 'null'; data << i }
      data
    end
  end

  post '/get_data/' do
    startime = Time.now.to_i
    requests = JSON.parse params[:req]
    param = JSON.parse params[:param]
    runcommand = JSON.parse params[:exec]
    multiple_params = {}
    param.each { |k| multiple_params[k.keys[0]] = multiple_params[k.keys[0]] ? multiple_params[k.keys[0]] << k.values[0] : [k.values[0]] }
    class Integer
      def more_on_one(max_val)
        value = self != 0 ? ((self - 1) - (((self - 1) / max_val) * max_val)) : self
        value
      end
    end

    class Hash
      def filling_data
        req = ''
        each  do |b|
          val = b[1].class.name == 'Array' ? b[1].count > 1 ? b[1].to_s : b[1].first.to_s : b[1].class.name == 'Fixnum' ? b[1].to_s : b[1]
          req = !req.empty? ? req.gsub(/\\\\#{b[0]}\\\\/, val) : yield.gsub(/\\\\#{b[0]}\\\\/, val)
        end
        req.gsub(/,\s+\)/, ')').gsub(/,\s+\w+\:\s\)/, ')')
      end
    end

    class BuildObject
    end

    if param.try(:any?)
      builded_runcommand = {}
      builded_runcommand = multiple_params.filling_data { runcommand }
      bo = BuildObject.new
      bo.instance_eval(requests)
      return eval("bo.#{builded_runcommand}").to_json
    else
      return DataSerializer.new(eval(requests)).to_json
    end
  end
end
