module TrkDatatables
  class Preferences
    KEY_IN_PREFERENCES = "trk_datatables"
    def initialize(holder, field, class_name)
      @holder = holder
      @field = field
      @class_name = class_name
    end

    # Get the key from holder
    # Use check_value proc to ignore wrong format. This is usefull when you
    # change format and you do not want to clear all existing values
    def get(key, check_value = nil)
      return unless @holder

      values = @holder.send(@field).dig KEY_IN_PREFERENCES, @class_name
      result = values&.fetch(key, nil) || values&.fetch(key.to_s, nil)
      return result if check_value.nil?
      result if check_value.call result
    end

    def set(key, value)
      return unless @holder

      h = {KEY_IN_PREFERENCES => {@class_name => {key.to_s => _value_for_serialization(value)}}}
      @holder.send(:"#{@field}=", {}) if @holder.send(@field).nil?
      @holder.send(@field).deep_merge! h
      @holder.save!
    end

    private

    def _value_for_serialization(value)
      case value
      when Array
        value.map { |v| _value_for_serialization v }
      when Hash
        value.transform_values { |v| _value_for_serialization v }
      when Symbol
        value.to_s
      else
        value
      end
    end
  end
end
