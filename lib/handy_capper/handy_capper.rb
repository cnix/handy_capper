# Public: Various methods for scoring sailing regattas.
# All methods are instance methods.
# Currently only PHRF Time on Time and PHRF Time on Distance are supported.
module HandyCapper

  # Public: Applies position and points to a group of results
  #
  # Examples
  #
  #   # get some result objects from a database or something
  #   results = Result.where('race_id = ?', 1)
  #   # => [ #<Result ...>, #<Result ...>]
  #   HandyCapper.score(results, :corrected_time)
  #   # returns results with position and points set
  #   # => [ #<Result ...>, #<Result ...>]
  #   results.first.position
  #   # => 1
  #   results.first.points
  #   # => 1
  #
  # Returns Array with position and points set for each result in the array
  def self.score(results, sort=:corrected_time)

    sorted_results = results.sort do |a,b|
      if a.finish_time && b.finish_time
        a.send(sort) <=> b.send(sort)
      else
        a.finish_time ? -1 : 1
      end
    end

    sorted_results.each_with_index do |result, index|
      if result.finish_time.nil?
        result.position = results.length
      else
        result.position = index + 1
      end
      calculate_points(result, results.length)
    end

    sorted_results
  end

  # Public: Corects a result with the PHRF scoring system.
  # See http://http://offshore.ussailing.org/PHRF.htm
  #
  # options - Hash for setting a different PHRF scoring method (default: {})
  #           :formula -  If you wish to use Time on Time, pass the Symbol :tot
  #                       Additionally, you can set the numerator and 
  #                       denominator for the Time on Time formula by setting
  #                       values for :a & :b
  #           :a       -  Set :a to a Fixnum to set the numerator of the formula
  #           :b       -  Set :b to a Fixnum to set the denominator of the formula
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
  #
  #   result.phrf
  #   # => #<Result ...>
  #   result.elapsed_time
  #   # => '01:30:30'
  #   result.corrected_time
  #   # => '00:59:50'
  #
  #   # Using default settings for Time on Time formula
  #   result.phrf(formula: :tot)
  #   # => #<Result ...>
  #   result.corrected_time
  #   # => '01:16:12'
  #
  #   # Change the denominator to accommodate conditions
  #   result.phrf(formula: :tot, b: 480) # heavy air
  #   # => #<Result ...>
  #   result.corrected_time
  #   # => '01:23:48'
  #
  # Returns receiver with elapsed_time and corrected_time set
  # Raises AttributeError if a required attribute is missing from the receiver
  def phrf(options={})

    unless rating && start_time && finish_time
      raise AttributeError, "You're missing a required attribute to process this result"
    end

    self.elapsed_time = calculate_elapsed_time(self)

    if options[:formula] == :tot
      a = options[:a] || 650 # generic numerator
      b = options[:b] || 550 # average conditions
      ct_in_seconds = score_with_phrf_time_on_time(a,b)
    else
      ct_in_seconds = score_with_phrf_time_on_distance
    end

    self.corrected_time = convert_seconds_to_time(ct_in_seconds)
    self.elapsed_time = convert_seconds_to_time(self.elapsed_time)

    self
  end

  # Public: Process elapsed_time for a result
  #
  # Returns receiver with elapsed_time set
  # Raises AttributeError is a required attribute is missing from the receiver
  def one_design

    unless start_time && finish_time
      raise AttributeError, "You need a start_time and finish_time to process this result"
    end

    self.elapsed_time = convert_seconds_to_time(calculate_elapsed_time(self))

    self
  end

  # Public: Score a series of races
  #
  # options - Hash for setting series scoring options
  #
  # Examples
  #   event = Event.find(1)
  #   results = event.score_series(throwouts: 1, system: :isaf_low_point)
  #   # => [ { boat_id: 1, points: 17 }, { boat_id: 2, points: 22 } ... ]
  #
  # Returns an array of Hashes
  def score_series(options={})
    options[:system] ||= :isaf_low_point
    options[:throwouts] ||= 0

    results = []
    self.races.each do |r|
      results.push(r.results).flatten!
    end

    results = results.group_by { |r| r.boat_id }

    # no throwouts yet
    scored_results = []
    results.each do |n|
      points = (n[1].map { |r| r[:points] }.inject(0){ |sum,item| sum + item })
      
      # Get a new instance of the result class so we can return this awesomely
      result = self.races.first.results.first.class.allocate
      result.boat_id = n[0]
      result.fleet_id = n[1].first.fleet_id
      result.points = points

      scored_results << result
    end

    scored_results
  end

  private

  # Internal: Calculate corrected time with PHRF Time on Distance
  #
  # result - corrected time in seconds
  #
  # Examples
  #
  #   Result = Struct.new(:elapsed_time, :rating, :distance)
  #   result = Result.new(5400, 222, 10.5)
  #   result.score_with_phrf_time_on_distance
  #   # => 3069
  #
  # Returns a Fixnum
  def score_with_phrf_time_on_distance
    cf  = self.rating
    et  = self.elapsed_time
    d   = self.distance

    (et - (d * cf)).round
  end

  # Internal: Calculate corrected time in seconds with PHRF Time on Time
  #
  # a - Numerator for TOT formula. Does not affect position.
  # b - Denominator for TOT formula. This one affects position.
  #
  # Examples
  #
  #   Result = Struct.new(:elapsed_time, :rating)
  #   result = Result.new(5400, 222)
  #   result.score_with_phrf_time_on_time(b: 480)
  #   # => 5000
  #   result.score_with_phrf_time_on_time(b: 600)
  #   # => 4270
  #
  # Returns a Fixnum representing corrected time in seconds
  def score_with_phrf_time_on_time(a, b)
    tcf = a.to_f / ( b.to_f + self.rating.to_f )
    (self.elapsed_time * tcf).round
  end

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

  # Internal: Calculate the points for a scored result
  #
  # result        - A Result object
  # total_results - A Fixnum representing the number of results in the set
  #
  # Examples
  #
  #   first_place_boat = Result.new({
  #     corrected_time: '01:30:41',
  #     position:       1,
  #     code:           nil
  #   })
  #   HandyCapper.calculate_points(first_place_boat, 10)
  #   # => #<Result ...>
  #   first_place_boat.points
  #   # => 1
  #   
  #   dnf_boat = Result.new({
  #     corrected_time: nil,
  #     position:       10,
  #     code:           'DNF'
  #   })
  #   HandyCapper.calculate_points(dnf_boat, 10)
  #   # => #<Result ...>
  #   dnf_boat.points
  #   # => 11
  #
  # Returns the result argument with the points attribute set to a Fixnum
  def self.calculate_points(result, total_results)
    if result.code
      calculate_points_with_penalty(result, total_results)
    else
      result.points = result.position
    end
    result
  end

  # Internal: Calculate points based on a penalty code
  def self.calculate_points_with_penalty(result, total_results)
    if ONE_POINT_PENALTY_CODES.include?(result.code.upcase)
      result.points = total_results + 1
    elsif TWENTY_PERCENT_PENALTY_CODES.include?(result.code.upcase)
      penalty_points = (total_results * 0.20).round
      if (penalty_points + result.position) > (total_results + 1)
        result.points = total_results + 1
      else
        result.points = result.position + penalty_points
      end
    else
      result.points = result.position
    end
    result
  end

  # Internal: Array of String penalty codes that apply the n + 1 penalty where
  # n = the total number of entries for a fleet
  ONE_POINT_PENALTY_CODES = [
    'DSQ', 'DNS', 'DNC', 'DNF',
    'OCS', 'BFD', 'DGM', 'DNE',
    'RAF'
  ]

  # Internal: Array of String penalty codes that apply the 20% penalty
  TWENTY_PERCENT_PENALTY_CODES = [ 'ZFP', 'SCP' ]

  # Internal: Error that is raised when required attributes are missing from a
  # receiver for PHRF scoring
  class AttributeError < StandardError; end

end
