#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Test

	# Defines an assertion
	# An assertion belongs to a suite and consists of a message and a block.
	# The verify the assertion, the suite's (and its ancestors) setup blocks are
	# executed, then the assertions block is executed and after that, the suite's
	# (and ancestors) teardown blocks are invoked.
	#
	# An assertion has 5 possible states, see Assertion#status for a list of them.
	#
	# There are various helper methods in lib/test/support.rb which help you
	# defining nicer diagnostics or just easier ways to test common scenarios.
	# The following are test helpers:
	# * Kernel#raises(exception_class=StandardError)
	# * Kernel#within_delta(a, b, delta)
	# * Kernel#equal_unordered(a,b)
	# * Enumerable#equal_unordered(other)
	class Assertion

		# An assertion has 5 possible states:
		# :success
		# :    The assertion passed. This means the block returned a trueish value.
		# :failure
		# :    The assertion failed. This means the block returned a falsish value.
		#      Alternatively it raised a Test::Failure (NOT YET IMPLEMENTED).
		#      The latter has the advantage that it can provide nicer diagnostics.
		# :pending
		# :    No block given to the assertion to be run
		# :skipped
		# :    If one of the parent suites is missing a dependency, its assertions
		#      will be skipped
		# :error
		# :    The assertion errored out. This means the block raised an exception
		attr_reader :status

		# If an exception occured in Assertion#execute, this will contain the
		# Exception object raised.
		attr_reader :exception

		# The description of this assertion.
		attr_reader :message

		# The suite this assertion belongs to
		attr_reader :suite

		# The block specifying the assertion
		attr_reader :block

		# suite
		# :   The suite the Assertion belongs to
		# message
		# :   A descriptive string about what this Assertion tests.
		# &block
		# :   The block definition. Without one, the Assertion will have a :pending
		#     status.
		def initialize(suite, message, &block)
			@suite     = suite
			@status    = nil
			@exception = nil
			@message   = message || "No message given"
			@block     = block
		end

		# Run all setups in the order of their nesting (outermost first, innermost last)
		def setup
			@suite.ancestors.map { |suite| suite.setup }.flatten.reverse_each { |setup| instance_eval(&setup) }
		end

		# Run all teardowns in the order of their nesting (innermost first, outermost last)
		def teardown
			@suite.ancestors.map { |suite| suite.teardown }.flatten.each { |setup| instance_eval(&setup) }
		end

		# Runs the assertion and sets the status and exception
		def execute
			@exception = nil
			if @block then
				setup
				# run the assertion
				@status = instance_eval(&@block) ? :success : :failure
				teardown
			else
				@status = :pending
			end
		rescue => e
			@exception, @status = e, :error
			self
		else
			self
		end

		def clean_copy
			self.class.new(@suite, @message, &@block)
		end
	end
end
