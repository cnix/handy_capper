module HandyCapper
  # Public: Namespace for model-like modules
  module Models
    # Public: Include this module in your result class to get required attributes
    # for scoring the results. Alternatively, you can alias these to whatever
    # you have called them in your application
    module PreliminaryResult

      # Public: Array of Symbols passed attr_accessor on base class
      DEFAULT_PROPERTIES = [
        :rating,
        :start_time,
        :finish_time,
        :elapsed_time,
        :corrected_time,
        :distance,
        :penalty,
        :code,
        :avg_speed
      ]

      # Public: Installs attributes on a class where this module is included
      def self.included(base)
        DEFAULT_PROPERTIES.each do |p|
          base.send(:attr_accessor, p)
        end
      end

    end
  end
end
