module TrkDatatables
  module Preferences
    # Override this to set model where you can store order, index, page length
    # @example
    #   def preferences_holder
    #     @view.current_user
    #   end
    def preferences_holder
      nil
    end

    # Override if you use different than :preferences
    # You can generate with this command:
    # @code
    #   rails g migration add_preferences_to_users preferences:jsonb
    def preferences_field
      :preferences
    end

    def get_preference(key)
      return unless preferences_holder

      preferences_holder.send(preferences_field).dig :dt_preferences, self.class.name, key
    end

    def set_preference(key, value)
      return unless preferences_holder

      h = { dt_preferences: { self.class.name => { key => value } } }
      preferences_holder.send("#{preferences_field}=", {}) if preferences_holder.send(preferences_field).nil?
      preferences_holder.send(preferences_field).deep_merge! h
      preferences_holder.save!
    end
  end
end
