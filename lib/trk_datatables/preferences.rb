module TrkDatatables
  class Preferences
    def initialize(holder, field)
      @holder = holder
      @field = field
    end

    # Get the key from holder
    # Use check_value proc to ignore wrong format. This is usefull when you
    # change format and you do not want to clear all existing values
    def get(key, check_value = nil)
      return unless @holder

      result = @holder.send(@field).dig :dt_preferences, self.class.name, key
      return result if check_value.nil?
      return result if check_value.call result
    end

    def set(key, value)
      return unless @holder

      h = { dt_preferences: { self.class.name => { key => value } } }
      @holder.send("#{@field}=", {}) if @holder.send(@field).nil?
      @holder.send(@field).deep_merge! h
      @holder.save!
    end
  end
end
