# HandyCapper
This is alpha software. It currently only supports PHRF Time on Distance and
PHRF Time on Time scoring.

## Requirements
- Ruby 1.9.2 or greater
- minitest gem (if you want to run the test suite)

## Usage

### Calculating corrected time

```ruby
class YourApp
  include HandyCapper

  class Result
    # installs attr_accessors for required result attributes
    include HandyCapper::Models::PreliminaryResult
  end
end

result = YourApp::Result.new({
  rating: 222,
  start_time: '10:00:00',
  finish_time: '11:30:30',
  distance: 10.5
})

# If no options are passed to #phrf, the Time on Distance system will be used
result.phrf
# => #<Result ...>
result.elapsed_time
# => '01:30:30'
result.corrected_time
# => '00:51:39'
```

#### PHRF Time on Time Scoring
The PHRF Time on Time scoring method calculates a Time Correction Factor (TCF)
which is multiplied by the elapsed time to get 'corrected time'. The TCF is
calculated thusly:

```
            A
TCF = -------------
       B + Rating
```

Adjusting the _A_ numerator will have no impact on finishing order. It's used
to generate a pretty coeffecient. It is set to 650 as a default.

Adjusting the _B_ denominator will potentially impact finishing order. It's used
to represent the conditions for a given race. It is set to 550 as a default, for
average conditions. Use 480 for heavy air or all off the wind. Use 600 for light
air or all windward work. 

Corrected time is then calculated as:

```
corrected = TCF * elapsed time
```

For more information on PHRF Time on Time scoring, see 
[http://offshore.ussailing.org/PHRF/Time-On-Time_Scoring.htm][]

```ruby
result.phrf(formula: :tot, a: 650, b: 550)
# => #<Result ...>
result.elapsed_time
# => '01:30:30'
result.corrected_time
# => '01:16:12'
```

### Scoring a race
Now that we can correct times, we need to be able to sort a group of corrected
results and apply points. Currently, HandyCapper only supports scoring a
single event. Scoring a series, including applying throwouts will be supported
in a future release.

```ruby
# get some result objects from a database or something
results = Result.where('race_id = ?', 1)
# => [ #<Result ...>, #<Result ...>]
results.score
# returns results with position and points set
# => [ #<Result ...>, #<Result ...>]
results.first.position
# => 1
results.first.points
# => 1
```


Run the Tests
-------------
```bash
rake test
```

Utilities
---------
Launch an irb session with HandyCapper loaded

```bash
rake console
```

Copyright
---------
Copyright (c) 2011 Claude Nix. See [LICENSE][] for details.

[license]: https://github.com/cnix/handy_capper/blob/master/LICENSE.md
[http://offshore.ussailing.org/PHRF/Time-On-Time_Scoring.htm]: http://offshore.ussailing.org/PHRF/Time-On-Time_Scoring.htm
