module FastJsonapi
  class Attribute
    attr_reader :key, :method, :conditional_proc

    def initialize(key:, method:, options: {})
      @key = key
      @method = method
      @conditional_proc = options[:if]
    end

    def serialize(record, serialization_params, output_hash)
      if include_attribute?(record, serialization_params)
        output_hash[key] = if method.is_a?(Proc)
          # Handle based on method arity to avoid ArgumentError
          case method.arity
          when 1
            # Proc expects exactly 1 argument
            method.call(record)
          when 2
            # Proc expects exactly 2 arguments
            method.call(record, serialization_params)
          when -1
            # Proc accepts variable arguments (*args) - try with 2 first
            begin
              method.call(record, serialization_params)
            rescue ArgumentError
              method.call(record)
            end
          when -2
            # Proc has 1 required + variable args (record, *args) - safe to call with 2
            method.call(record, serialization_params)
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
    end

    def include_attribute?(record, serialization_params)
      if conditional_proc.present?
        conditional_proc.call(record, serialization_params)
      else
        true
      end
    end
  end
end
