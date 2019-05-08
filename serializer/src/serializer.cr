# TODO: Write documentation for `Serializer`
require "mongo"
require "json"

struct Int32
  def more_on_one(max_val : Int32)
    value = self != 0 ? ((self - 1) - (( (self - 1)/ max_val) * max_val)) : self
    return value
  end
end

class Object
  macro methods
    {{ @type.methods.map &.name.stringify }}
  end
end


class Array
  def filling_data
    req = [] of String
    self.each{|b|
      b_values = b.values[0].to_s
      b_keys = b.keys[0].to_s
      date = Time.parse(b[b_keys].to_s, "%F", Time::Location::UTC) && b[b_keys].to_s.match(/^\d*-\d*-\d+/) rescue nil
      val = date ? "Time.parse(\"#{b_values}\")" : "\"#{b_values}\""
      req = req.any? ? req.map{|r|r.to_s.gsub(/\\#{b_keys}\\/, val)} : yield.map{|r|r.to_s.gsub(/\\#{b_keys}\\/, val)}
    }
    req
  end
end

module Registrable
end

class Hash
  include Registrable
end

def dig(jsn)
  case jsn
  when .as_a?
    dig(jsn.as_a)
  when .as_h?
    dig(jsn.as_h)
  when .as_s?
    dig(jsn.as_s)
  when .as_i?
    dig(jsn.as_i)
  end
end

module Serializer
  VERSION = "0.1.0"

  client = Mongo::Client.new "mongodb://localhost:27017/hifc_statistic_dev"
  db = client["hifc_statistic_dev"]

  collection = db["user"]

  requests = JSON.parse(ARGV[1]).as_a
  param = JSON.parse(ARGV[0]).as_a
  if param.count{|i|i} != 0
    out_data = [] of String
    tmp_db_requests = [] of String
    clean_db_requests = Array(Hash(Int32, String)).new
    keys =  param.to_a.map{|k|k.as_h.keys}.flatten.uniq
    keys_without_date = keys.reverse.reject{|i|i.match(/DATE/)}
    keys_count = keys_without_date.count{|i|i}
    empty_params = requests.map{|r|r.as_s.scan(/\\([A-Z|A-Z_A-Z]+)\\/)}.flatten.map{|i|i.not_nil![1]} - keys
    builded_requests = Hash(String, Array(Hash(Int32, String))).new
    keys_without_date.each_with_index{|v,i|
        builded_requests[v] = Array(Hash(Int32, String)).new
        param.select{|z|z[v]}.map{|i|i.as_h.values}.flatten.each{|r|
        r = r.to_s.to_i32
        builded_requests[v] << { r => ([{ v => r }].filling_data{ i != 0 ? builded_requests[keys_without_date[i.more_on_one(keys_count)]].flatten : requests }).to_json }
      }
    }
    builded_requests = builded_requests[keys_without_date.last].flatten
    if empty_params.any?
      empty_params.each do |key|
        clean_db_requests = clean_db_requests.count{|i|i} != 0 ? clean_db_requests.map{|r| { r.keys[0] => r.values[0].gsub(/,\{.*"\$(.*)#{key}(.*?)\}\},/, ",") } } : builded_requests.map{|r| { r.keys[0] => r.values[0].gsub(/,\{.*"\$(.*)#{key}(.*?)\}\},/, ",") } }
        #clean_db_requests = clean_db_requests.any? ? clean_db_requests.map{|r| { r.keys[0] => r.values[0].gsub(/,\{.*"\$(.*)#{key}(.*?)\}\},/, ",").gsub(/\,\s?\W?\"[a-z|A-Z|_]+\W?\"\:\s{\W?"\$eq\W?":(.*)?#{key}(.*?)\W}/, "") } } : builded_requests.map{|r| { r.keys[0] => r.values[0].gsub(/,\{.*"\$(.*)#{key}(.*?)\}\},/, ",").gsub(/\,\s?\W?\"[a-z|A-Z|_]+\W?\"\:\s{\W?"\$eq\W?":(.*)?#{key}(.*?)\W}/, "") } }
      end
    else
      clean_db_requests = builded_requests
    end
  end
  test = "[{\"$sort\":{\"created_at\":1}}]"

  puts typeof(JSON.parse(test).as_a.map{|i|dig(i)}), [{ "$sort" => { "created_at" => 1 } }]
  puts typeof([{ "$sort" => { "created_at" => 1 } }])
  # puts db["user"].aggregate(JSON.parse(test).raw).first
  # class SerializerRequests
  #   puts 10.
  # end
end
