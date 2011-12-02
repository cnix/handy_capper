require File.dirname(__FILE__) + '/../test_helper'

describe HandyCapper::Models::PreliminaryResult do
  describe ".included" do
    before :each do
      class Result; include HandyCapper::Models::PreliminaryResult; end

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
    end

    it "should install the default attributes when included in a class" do
      result = Result.new

      DEFAULT_PROPERTIES.each do |p|
        result.must_respond_to p
      end
    end
  end
end
