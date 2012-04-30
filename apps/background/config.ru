require 'something'

run lambda { |env|
  Something.new.foo
  [200, {'Content-Type'=>'text/plain'}, "success"]
}
