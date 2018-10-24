# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "json"
require "json-schema"

java_import 'java.util.concurrent.locks.ReentrantReadWriteLock'

class LogStash::Filters::SchemaCheck < LogStash::Filters::Base
  # configure this filter from your Logstash config.
  #
  # filter {
  #   schema_check {
  #     schema_path => "test.json"
  #   }
  # }
  #
  # {
  #   "type": "object",
  #   "required": ["message","@version","@timestamp","host"],
  #   "properties": {
  #     "message": {
  #       "oneOf":[
  #         {
  #           "format":"ipv4",
  #           "type":"string"
  #         },
  #         {
  #           "format":"ipv6",
  #           "type":"string"
  #         }
  #       ]
  #     }
  #   }
  # }
  config_name "schema_check"

  # Setup json schema in ruby hash inline logstash config
  config :schema, :validate => :string, :default => ""
  # Provide path to the json schema to use
  config :schema_path, :validate => :path
  # Set refresh interval for reading json schema file for updates
  config :refresh_interval, :validate => :number, :default => 300
  # Enable json-schema strict checking
  config :strict, :validate => :boolean, :default => false
  # JSON-Schema fragment option
  config :fragment, :validate => :string
  # JSON-Schema validate schema option
  config :validate_schema, :validate => :boolean, :default => false
  # Enable debug
  config :debug_output, :validate => :boolean, :default => false
  # Schema failures output field
  config :failures_field, :validate => :string, :default => "schema_errors"
  # Enable Schema Error Message
  config :tag_on_failure, :validate => :array, :default => ["_schemacheckfailure"]

  public
  def register
    rw_lock = java.util.concurrent.locks.ReentrantReadWriteLock.new
    @read_lock = rw_lock.readLock
    @write_lock = rw_lock.writeLock

    if @schema_path && !@schema.empty?
      raise LogStash::ConfigurationError, I18n.t(
        "logstash.agent.configuration.invalid_plugin_register",
        :plugin => "filter",
        :type => "schema_check",
        :error => "The configuration options 'schema' and 'schema_path' are mutually exclusive"
      )
    end

   if @schema_path
     @next_refresh = Time.now + @refresh_interval
     raise_exception = true
     lock_for_write { load_schema(raise_exception) }
   end

    @logger.debug? and @logger.debug("#{self.class.name}: schema - ", :schema => @schema)
  end # def register

  public
  def filter(event)
    if @schema_path
      if needs_refresh?
        lock_for_write do
          if needs_refresh?
            load_schema
            @next_refresh = Time.now + @refresh_interval
            @logger.info("refreshing schema file")
          end
        end
      end
    end

    begin
      event_obj = event.to_hash
      if @debug_output
        output = JSON::Validator.fully_validate(@schema, event_obj, :strict => @strict, :fragment => @fragment, :validate_schema => validate_schema)
        unless output.empty?
          @tag_on_failure.each {|tag| event.tag(tag)}
          event.set(@failures_field, output)
        end
      else
        unless JSON::Validator.validate(@schema, event_obj, :strict => @strict, :fragment => @fragment, :validate_schema => validate_schema)
          @tag_on_failure.each {|tag| event.tag(tag)}
        end
      end
      filter_matched(event)
    rescue Exception => e
      @logger.error("Something went wrong when checking schema", :exception => e, :event => event)
    end
  end # def filter

  private
  def lock_for_read
    @read_lock.lock
    begin
      yield
    ensure
      @read_lock.unlock
    end
  end

  private
  def lock_for_write
    @write_lock.lock
    begin
      yield
    ensure
      @write_lock.unlock
    end
  end

  private
  def load_schema(raise_exception=false)
    if !File.exists?(@schema_path)
      @logger.warn("schema file read failure", :path => @schema_path)
      return
    end
    refresh_schema!(JSON.parse(File.read(@schema_path)))
  end

  private
  def refresh_schema!(data)
    @schema = data
  end

  def loading_exception(e, raise_exception=false)
    msg = "#{self.class.name}: #{e.message} when loading schema file at #{@schema_path}"
    if raise_exception
      raise RuntimeError.new(msg)
    else
      @logger.warn("#{msg}, continuing with old schema", :schema_path => @schema_path)
    end
  end

  private
  def needs_refresh?
    @next_refresh < Time.now
  end
end # class LogStash::Filters::JsonSchema
