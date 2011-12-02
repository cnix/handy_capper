require File.dirname(__FILE__) + '/../test_helper'

describe HandyCapper do
  before do
    Result = Struct.new(
      :rating,
      :start_time,
      :finish_time,
      :distance,
      :elapsed_time,
      :corrected_time
    )

    @result = Result.new( 222, '10:00:00', '11:30:30', 10.6)
  end

  after do
    # silence warnings for already initialized constant
    # this could probably be done better if it wasn't a Struct. =\
    Object.send(:remove_const, :Result)
  end

  describe "#phrf" do
    it "should set the elapsed time" do
      @result.phrf.elapsed_time.wont_be_nil
    end

    it "should set the corrected time" do
      @result.phrf.corrected_time.wont_be_nil
    end

    it "should require a rating" do
      @result.rating = nil
      -> { @result.phrf }.must_raise AttributeError
    end

    it "should require a start time" do
      @result.start_time = nil
      -> { @result.phrf }.must_raise AttributeError
    end

    it "should require a finish time" do
      @result.finish_time = nil
      -> { @result.phrf }.must_raise AttributeError
    end

    it "should require a distance" do
      @result.distance = nil
      -> { @result.phrf }.must_raise AttributeError
    end
  end

  describe "#calculate_elapsed_time" do
    it "should return a Fixnum representing time in seconds" do
      seconds = calculate_elapsed_time(@result)
      seconds.must_be_instance_of Fixnum
      seconds.must_equal 5430
    end
  end

  describe "#convert_seconds_to_time" do
    it "should accept a Fixnum" do
      -> { convert_seconds_to_time("90") }.
        must_raise TypeError
    end

    it "should return a Time" do
      time = convert_seconds_to_time(90)
      time.must_be_instance_of String
      time.must_equal "00:01:30"
    end
  end
end
