#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'barebench/skipped/bench'



module BareBench

  module Skipped

    # Like Test::Suite, but all Assertions are defined as Skipped::Assertion
    class Suite < ::BareBench::Suite
      def self.create(description=nil, parent=nil, opts={}, &block) # :nodoc:
        new(description, parent, &block) # Skipped::Suite always
      end

      # All Assertions use Skipped::Assertion instead of Test::Assertion.
      def assert(description=nil, &block) # :nodoc:
        @skipped << Skipped::Bench.new(self, description, &block)
      end

      # All setup blocks are disabled
      def ancestry_setup # :nodoc:
        []
      end

      # All teardown blocks are disabled
      def ancestry_teardown # :nodoc:
        []
      end

      # All setup blocks are disabled
      def setup(&block) # :nodoc:
        []
      end

      # All teardown blocks are disabled
      def teardown(&block) # :nodoc:
        []
      end
    end
  end
end
