require "httparrot/version"
require "httparrot/server"
require "httparrot/response_factory"

require "ostruct"
require "thread"

class HTTParrot
  @config_lock = Mutex.new
  @config = OpenStruct.new

  def self.configure 
    @config_lock.synchronize do 
      yield self
    end
  end

  def self.config
    @config.instance_variable_get(:@table)
  end

  def self.valid_key?(key)
    [ :Port, 
      :SSLPort,
      :ssl,
      :templates,
      :verbose ].include?(key)
  end

  def self.method_missing(sym, *args, &blk)
    case 
    when sym.to_s =~ /(.+)=$/ && valid_key?($1.to_sym) then
      @config.send(sym, *args, &blk)
    when @config.respond_to?(sym) then
      @config.send(sym, *args, &blk)
    else 
      super
    end
  end

end

HTTParrot.configure do |config|
  config.Port = 4000
  config.SSLPort = config.Port + 1
  config.ssl = true
  config.verbose = false
end
