module ActiveShipping
  class LabelResponse < Response
    attr_reader :labels
    attr_reader :high_value_report
    

    def initialize(success, message, params = {}, options = {})
      @labels = options[:labels]
      @high_value_report = options[:high_value_report]      
      super
    end
  end
end
