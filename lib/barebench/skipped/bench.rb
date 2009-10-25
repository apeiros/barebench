#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module BareBench
  module Skipped

    # Like Test::Assertion, but fakes execution and sets status always to
    # skipped.
    class Bench < ::BareBench::Bench
      def execute() # :nodoc:
        @status = :skipped and self
      end
    end
  end
end
