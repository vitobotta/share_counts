require 'autotest'

class Autotest::Rules < Autotest
  def initialize
    super

    add_mapping(%r{^lib/.*\.rb$}, true) { |filename, _|
      files_matching %r%^test/test_.*\.rb$%
    }
  end
end

