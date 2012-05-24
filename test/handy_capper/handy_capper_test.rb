require File.dirname(__FILE__) + '/../test_helper'
require 'ruby-debug'

describe HandyCapper do
  before do
    Result = Struct.new(
      :rating,
      :start_time,
      :finish_time,
      :distance,
      :elapsed_time,
      :corrected_time,
      :position,
      :points,
      :code,
      :boat_id,
      :fleet_id
    )
  end

  after do
    # silence warnings for already initialized constant
    # this could probably be done better if it wasn't a Struct. =\
    Object.send(:remove_const, :Result)
  end

  describe "#score" do
    before do
      @corrected_results = []
      10.times do
        result = Result.new
        # TODO: Address potential race condition
        ctime = Time.parse("#{[*0..3].sample}:#{[*0..59].sample}:#{[*0..59].sample}").strftime('%R:%S')
        result.corrected_time = ctime
        ftime = Time.parse("#{[*0..3].sample}:#{[*0..59].sample}:#{[*0..59].sample}").strftime('%R:%S')
        result.finish_time = ftime
        @corrected_results << result
      end

      @one_design_results = []
      10.times do
        result = Result.new
        # TODO: Address potential race condition
        etime = Time.parse("#{[*0..3].sample}:#{[*0..59].sample}:#{[*0..59].sample}").strftime('%R:%S')
        result.elapsed_time = etime
        ftime = Time.parse("#{[*0..3].sample}:#{[*0..59].sample}:#{[*0..59].sample}").strftime('%R:%S')
        result.finish_time = ftime
        @one_design_results << result
      end
    end

    describe "one design" do
      it "should sort results by elapsed_time" do
        scored_results = HandyCapper.score(@one_design_results, :elapsed_time)

        previous = '0'
        scored_results.each do |r|
          this = r.elapsed_time
          (this > previous).must_equal true
          previous = this
        end
      end
    end

    describe "corrected time" do
      it "should sort the results by corrected_time" do
        scored_results = HandyCapper.score(@corrected_results)

        previous = '0'
        scored_results.each do |r|
          this = r.corrected_time
          (this > previous).must_equal true
          previous = this
        end
      end

      it "should push results with no finish time to the end of the array" do
        no_finish_time_result = @corrected_results.first
        no_finish_time_result.finish_time = nil
        no_finish_time_result.corrected_time = nil
        no_finish_time_result.code = 'dnc'
        
        scored_results = HandyCapper.score(@corrected_results)
        scored_results[-1].must_equal no_finish_time_result
      end
    end

    it "should add position to the result" do
      scored_results = HandyCapper.score(@corrected_results)

      scored_results.each do |r|
        r.position.wont_be_nil
      end
    end
  end

  describe "#phrf" do
    before do
      @result = Result.new( 222, '10:00:00', '11:30:30', 10.6)
    end

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

    it "should default to PHRF Time On Distance" do
      @result.phrf.corrected_time.must_equal '00:51:17'
    end
  end

  describe "#one_design" do
    before do
      @result = Result.new(222, '10:00:00', '11:30:30', 10.6)
    end

    it "should set the elapsed time" do
      @result.one_design.elapsed_time.wont_be_nil
    end

    it "should not be corrected" do
      @result.one_design.elapsed_time.must_equal '01:30:30'
    end
  end

  describe "#score_with_phrf_time_on_distance" do
    before do
      # set elapsed time to seconds so we don't need to convert to test this
      @result = Result.new(222, '10:00:00', '11:30:30', 10.6, 5430)
    end

    it "should calculate corrected time with Time on Distance formula" do
      corrected_time_in_seconds = @result.send(:score_with_phrf_time_on_distance)
      corrected_time_in_seconds.must_be_instance_of Fixnum
      corrected_time_in_seconds.must_equal 3077
    end
  end

  describe "#score_with_phrf_time_on_time" do
    before do
      @result = Result.new(222, '10:00:00', '11:30:30', nil, 5430)
    end

    it "should calculate corrected time with Time on Time formula" do
      corrected_time_in_seconds = @result.send(:score_with_phrf_time_on_time, 650,550)
      corrected_time_in_seconds.must_be_instance_of Fixnum
      corrected_time_in_seconds.must_equal 4572
    end

    it "should allow configuration of time on time numerator" do
      corrected_time_in_seconds = @result.send(:score_with_phrf_time_on_time, 550,550)
      corrected_time_in_seconds.must_equal 3869
    end

    it "should allow configuration of time on time denominator" do
      corrected_time_in_seconds = @result.send(:score_with_phrf_time_on_time, 650,480)
      corrected_time_in_seconds.must_equal 5028
    end
  end

  describe "#yardstick" do
    before do
      @result = Result.new(91.1, '10:00:00', '11:30:30')
    end

    it "should set the elapsed time" do
      @result.yardstick.elapsed_time.wont_be_nil
      @result.elapsed_time.must_equal '01:30:30'
    end

    it "should calculate corrected time with Portsmouth Yardstick formula" do
      @result.yardstick.corrected_time.must_equal '01:39:20'
    end
  end

  describe "#calculate_elapsed_time" do
    before do
      @result = Result.new( 222, '10:00:00', '11:30:30', 10.6)
    end

    it "should return a Fixnum representing time in seconds" do
      seconds = calculate_elapsed_time(@result)
      seconds.must_be_instance_of Fixnum
      seconds.must_equal 5430
    end
  end

  describe "#convert_seconds_to_time" do
    before do
      @result = Result.new( 222, '10:00:00', '11:30:30', 10.6)
    end

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

  describe ".calculate_points" do
    before do
      @result = Result.new
      @result.position = 2
    end

    it "should set the points for a result" do
      HandyCapper.calculate_points(@result, 10)
      @result.points.must_equal 2
    end

    describe "penalty scoring" do

      describe "when the penalty code is a n + 1 code" do

        it "should set points based on ISAF penalty code" do
          ['DSQ', 'DNS', 'DNF', 'DNC', 'OCS', 'BFD', 'DGM', 'DNE', 'RAF'].each do |c|
            @result.code = c
            HandyCapper.calculate_points(@result, 10)
            @result.points.must_equal 11
          end

        end
      end

      describe "when the penalty code is a 20% penalty" do

        it "should apply the 20% penalty" do
          [ 'ZFP', 'SCP' ].each do |c|
            @result.code = c
            HandyCapper.calculate_points(@result, 10)
            @result.points.must_equal 4
          end
        end

        it "should not apply a penalty greater than n + 1" do
          [ 'ZFP', 'SCP' ].each do |c|
            @result.code = c
            @result.position = 10
            HandyCapper.calculate_points(@result, 10)
            @result.points.must_equal 11
          end
        end

      end
    end
  end

  describe "#score_series" do
    before do
      Event = Struct.new(:races)
      Race = Struct.new(:results)
      @event = Event.new
      @event.races = []

      10.times do
        @event.races << Race.new
      end
      
      boat_id = 1
      @event.races.each do |race|
        race.results = []
        10.times do
          r = Result.new
          r.boat_id = boat_id
          r.points = rand(10)+1
          race.results << r
        end
        boat_id += 1
      end

    end

    after do
      # silence warnings for already initialized constant
      # this could probably be done better if it wasn't a Struct. =\
      Object.send(:remove_const, :Event)
      Object.send(:remove_const, :Race)
    end

    it "should return a single result for each unique boat_id" do
      sample_result = @event.races.first.results.first
      # Figure out how many unique boat_ids we have
      results = []
      @event.races.each do |race|
        results.push(race.results).flatten!
      end
      boats = results.map(&:boat_id).uniq

      scored = @event.score_series
      scored.length.must_equal boats.length
      scored.each do |result|
        result.length.must_equal sample_result.length
        result.must_be_instance_of sample_result.class
      end
    end

  end
end
