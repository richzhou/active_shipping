module ActiveShipping
  class LabelResponse < Response
    attr_reader :labels
    attr_reader :high_value_report
    attr_reader :commercial_invoice

    def initialize(success, message, params = {}, options = {})
      @labels = options[:labels]
      @high_value_report = options[:high_value_report]   
      @commercial_invoice = options[:commercial_invoice]            
      super
    end
  end
end
