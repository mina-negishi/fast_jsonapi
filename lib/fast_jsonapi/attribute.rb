# frozen_string_literal: true

module FastJsonapi
  class Attribute
    attr_reader :key, :method, :conditional_proc

    def initialize(key:, method:, options: {})
      @key = key
      @method = method
      @conditional_proc = options[:if]
      # Cache method type and arity for performance
      @is_proc = method.is_a?(Proc)
      @method_arity = @is_proc ? method.arity : nil
    end

    def serialize(record, serialization_params, output_hash)
      return unless include_attribute?(record, serialization_params)
      
      output_hash[key] = if @is_proc
        # Optimized method calling based on cached arity
        case @method_arity
        when 1
          # Proc expects exactly 1 argument
          method.call(record)
        when 2
          # Proc expects exactly 2 arguments
          method.call(record, serialization_params)
        when -1
          # Proc accepts variable arguments (*args) - try with 2 first, fallback to 1
          begin
            method.call(record, serialization_params)
          rescue ArgumentError
            method.call(record)
          end
        when -2
          # Proc has 1 required + variable args (record, *args)
          # But symbol-to-proc (&:method) also has arity -2 and expects only 1 arg
          # Try with 1 argument first for symbol-to-proc compatibility
          begin
            method.call(record)
          rescue ArgumentError
            method.call(record, serialization_params)
          end
        else
          # For other arity values, try 2 args first, fallback to 1 if ArgumentError
          begin
            method.call(record, serialization_params)
          rescue ArgumentError
            method.call(record)
          end
        end
      else
        record.public_send(method)
      end
    end

    def include_attribute?(record, serialization_params)
      conditional_proc ? conditional_proc.call(record, serialization_params) : true
    end
  end
end
