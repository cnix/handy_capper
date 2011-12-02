HandyCapper
===========

Usage
-----
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

result.phrf
# => #<Result ...>
result.elapsed_time
# => '01:30:30'
result.corrected_time
# => '00:59:50'
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
