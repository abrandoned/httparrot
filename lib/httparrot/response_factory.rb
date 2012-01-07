require 'httparrot/widget'

module HTTParrot

  class ResponseFactory

    def self.clear!
      @factory_classes = {}
    end

    def self.define(factory_class, &block)
      raise error_no_block(factory_class) if block.nil?
      @factory_classes ||= {} 
      warn_factory_exists(factory_class) if @factory_classes.keys.include?(factory_class)
      default_object = HTTParrot::Widget.new(:class => "Widget::#{factory_class.to_s.camelize}")
      @factory_classes[factory_class] = lambda{ block.call(default_object); default_object } 
    end

    def self.build(factory_class, new_options={})
      raise error_for_missing(factory_class) if @factory_classes[factory_class].nil?
      object = @factory_classes[factory_class].call

      new_options.each do |k, v|
        object.send("#{k}=", v) 
      end

      return Marshal.load(Marshal.dump(object)) 
    end

    def self.collection_of(factory_class, number, new_options={})
      collection = []

      number.times do 
        collection << build(factory_class, new_options)
      end

      return collection
    end

    def self.one_of(choices)
      warn_no_choices if choices.size <= 0
      choices[rand(choices.size)]
    end

    private 

    def self.error_for_missing(factory_class)
      "Unknown factory type: #{factory_class} in known factories: #{@factory_classes.keys}"
    end

    def self.error_no_block(factory_class)
      "No block included in definition of #{factory_class} factory"
    end

    def self.warn_no_choices
      raise "foo"
    rescue => e
      warn <<-WARNING
          ==============================================================
              No choices were provided for #one_of

                  This constitutes a nil choice 

                  At:

              #{e.backtrace.join("#{$/}      ")}
          ==============================================================
      WARNING
    end

    def self.warn_factory_exists(factory_class)
      raise "foo"
    rescue => e
      warn <<-WARNING
          ==============================================================
              #{factory_class} is already defined as a ResponseFactory

                  This constitutes a redefinition of the factory

                  Redefined at:

              #{e.backtrace.join("#{$/}      ")}
          ==============================================================
      WARNING
    end

  end

end
