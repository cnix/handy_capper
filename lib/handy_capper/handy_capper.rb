module HandyCapper

  # Public: Scores a result with the PHRF scoring system.
  # See http://http://offshore.ussailing.org/PHRF.htm
  #
  # options - Hash for setting a different PHRF scoring method (default: {})
  #
  # Examples
  #
  #   # Assuming a class named Result in your application
  #   result = Result.new({
  #     rating: 222,
  #     start_time: '10:00:00',
  #     finish_time: '11:30:30',
  #     distance: 10.5
  #   })
  #   result.phrf
  #   # => #<Result ...>
  #   result.elapsed_time
  #   # => '01:30:30'
  #   result.corrected_time
  #   # => '00:59:50'
  #
  # Returns receiver with elapsed_time and corrected_time set
  def phrf(options={})
    cf  = self.rating
    st  = self.start_time
    ft  = self.finish_time
    d   = self.distance

    unless cf && st && ft && d
      raise AttributeError, "You're missing a required attribute to process this result"
    end

    et = calculate_elapsed_time(self)
    ct_in_seconds = (et - (d * cf))
    self.corrected_time = convert_seconds_to_time(ct_in_seconds)
    self.elapsed_time = convert_seconds_to_time(et)

    self
  end

  private

  # Internal: Calculate delta in seconds between two time objects
  #
  # result - an object with a start_time and a finish_time attribute
  #
  # Examples
  #
  #   Result = Struct.new(:start_time, :finish_time)
  #   result = Result.new("10:00:00", "11:30:00")
  #   calculate_elapsed_time(result)
  #   # => 5400
  #
  # Returns a Fixnum 
  def calculate_elapsed_time(result)
    Time.parse(result.finish_time).to_i - Time.parse(result.start_time).to_i
  end

  # Internal: Covert seconds to a string of seconds
  #
  # seconds - a Fixnum representing time in seconds
  #
  # Examples
  #
  #   convert_seconds_to_time(5400)
  #   # => '01:30:00'
  #
  # Returns a string
  def convert_seconds_to_time(seconds)
    Time.at(seconds).gmtime.strftime('%R:%S')
  end

  class AttributeError < Exception; end

end

# PreliminaryResult
# preliminary_result:
#   :boat_id (to get rating)
#   :fleet_id (to get scoring type)
#   :race_id (for edits)
#   :penalty
#   :course_length (for PHRF TOD)
#   :wind_speed (for PHRF TOT, DP-N)
#   :start_time
#   :finish_time
#   :corrected_time
#
#
#
# corrected = result.phrf(system: :tod)
#
# things we want to know:
#   elapsed_time
#   corrected_time
#   avg_speed
#   time_behind_in_seconds_per_mile => must process entire result set. =\
