#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



BareBench.suite "BareBench" do
  suite "Run" do
    suite "::new" do
      assert "Should return an instance of Run" do
        kind_of ::BareBench::Run, ::BareBench::Run.new(::BareBench::Suite.new)
      end

      assert "Should accept 1-2 arguments" do
        raises(ArgumentError) do ::BareBench::Run.new end &&
        raises_nothing do ::BareBench::Run.new(::BareBench::Suite.new) end &&
        raises_nothing do ::BareBench::Run.new(::BareBench::Suite.new, {}) end &&
        raises(ArgumentError) do ::BareBench::Run.new(::BareBench::Suite.new, {}, nil) end
      end

      assert "Should accept an option ':format'" do
        raises_nothing do ::BareBench::Run.new(::BareBench::Suite.new, :format => 'spec') end
      end

      assert "Should use the formatter specified in the :format option" do
        run = ::BareBench::Run.new(::BareBench::Suite.new, :format => 'spec')
        kind_of(::BareBench::Run::Spec, run)
      end

      assert "Should accept an option ':interactive' and load irb_mode" do
        run = ::BareBench::Run.new(::BareBench::Suite.new, :interactive => true)
        kind_of(::BareBench::IRBMode, run)
      end
    end

    suite "#suite" do
      assert "Should return the suite the instance was initialized with" do
        suite = ::BareBench::Suite.new
        run   = ::BareBench::Run.new(suite)

        same(suite, run.suite)
      end
    end

    suite "#inits" do
      setup do
        BareBench.extender.clear # avoid interference
        @executed    = []
        executed     = @executed # for closure
        @init_blocks = [
          proc { executed << :block1 },
          proc { executed << :block2 }
        ]
        init_blocks  = @init_blocks # for closure
        @extender    = Module.new do |m|
          (class <<m;self;end).send(:define_method, :extended) do |by|
            init_blocks.each { |init_block|
              by.init(&init_block)
            }
          end
        end
        $LOADED_FEATURES << 'barebench/run/test_init.rb' unless $LOADED_FEATURES.include?('barebench/run/test_init.rb') # suppress require
        ::BareBench.format['barebench/run/test_init'] = @extender # provide the module as formatter
      end

      assert "Should return the array with blocks called at the end of initialize" do
        run = ::BareBench::Run.new(::BareBench::Suite.new, :format => 'test_init')
        equal(@init_blocks, run.inits)
      end

      assert "Should run the blocks at the end of initialize" do
        run = ::BareBench::Run.new(::BareBench::Suite.new, :format => 'test_init')
        equal([:block1, :block2], @executed)
      end
    end

    suite "#run_all" do
      assert "Invokes #run_suite with the Run instance's toplevel suite" do
        invoked_suites = []
        extender       = Module.new do |m|
          define_method :run_suite do |suite|
            invoked_suites << suite
          end
        end
        toplevel_suite = ::BareBench::Suite.new
        $LOADED_FEATURES << 'barebench/run/test_init.rb' unless $LOADED_FEATURES.include?('barebench/run/test_init.rb') # suppress require
        ::BareBench.format['barebench/run/test_init'] = extender # provide the module as formatter
        run = ::BareBench::Run.new(toplevel_suite, :format => 'test_init')
        run.run_all

        equal([toplevel_suite], invoked_suites)
      end
    end

    suite "#run_suite" do
      assert "Invokes #run_suite with every suite in the given suite" do
        invoked_suites = []
        extender       = Module.new do |m|
          define_method :run_suite do |suite|
            invoked_suites << suite
            super(suite)
          end
        end

        suites = [
          ["desc1", ::BareBench::Suite.new],
          ["desc2", ::BareBench::Suite.new]
        ]
        toplevel_suite = ::BareBench::Suite.new
        toplevel_suite.suites.concat(suites) # HAX, should have an API for this
        expect = [toplevel_suite]+suites.map { |desc, suite| suite }

        $LOADED_FEATURES << 'barebench/run/test_init.rb' unless $LOADED_FEATURES.include?('barebench/run/test_init.rb') # suppress require
        ::BareBench.format['barebench/run/test_init'] = extender # provide the module as formatter
        run = ::BareBench::Run.new(toplevel_suite, :format => 'test_init')
        run.run_suite(toplevel_suite)

        equal_unordered(expect, invoked_suites)
      end

      assert "Invokes #run_test with every suite in the given suite" do
        invoked_tests = []
        extender       = Module.new do |m|
          define_method :run_test do |test|
            invoked_tests << test
          end
        end
        toplevel_suite = ::BareBench::Suite.new
        assertions     = [
          ::BareBench::Assertion.new(toplevel_suite, "assertion1"),
          ::BareBench::Assertion.new(toplevel_suite, "assertion2")
        ]
        toplevel_suite.assertions.concat(assertions) # HAX, should have an API for this
        $LOADED_FEATURES << 'barebench/run/test_init.rb' unless $LOADED_FEATURES.include?('barebench/run/test_init.rb') # suppress require
        ::BareBench.format['barebench/run/test_init'] = extender # provide the module as formatter
        run = ::BareBench::Run.new(toplevel_suite, :format => 'test_init')
        run.run_all

        equal_unordered(assertions, invoked_tests)
      end

      assert "Increments the counter ':suite' at the end" do
        toplevel_suite = ::BareBench::Suite.new
        run = ::BareBench::Run.new(toplevel_suite)

        count_before = run.count[:suite]
        run.run_suite(toplevel_suite)
        count_after = run.count[:suite]

        equal(count_before+1, count_after)
      end
    end

    suite "#run_test" do
      assert "Runs the given test" do
        # should implement this with a mock, expecting #execute to be called
        assertion = ::BareBench::Assertion.new(nil, nil) do true end
        run       = ::BareBench::Run.new(::BareBench::Suite.new)
        run.run_test(assertion)

        equal(:success, assertion.status)
      end

      assert "Increments the counter ':test' at the end" do
        assertion = ::BareBench::Assertion.new(nil, "") do true end
        run       = ::BareBench::Run.new(::BareBench::Suite.new)
        count_before = run.count[:test]
        run.run_test(assertion)
        count_after = run.count[:test]

        equal(count_before+1, count_after)
      end

      suite "The given test was a success" do
        assert "Increments the counter ':success' at the end" do
          assertion = ::BareBench::Assertion.new(nil, "") do true end
          run       = ::BareBench::Run.new(::BareBench::Suite.new)
          count_before = run.count[:success]
          run.run_test(assertion)
          count_after = run.count[:success]

          equal(count_before+1, count_after)
        end
      end

      suite "The given test was pending" do
        assert "Increments the counter ':pending' at the end" do
          assertion = ::BareBench::Assertion.new(nil, "")
          run       = ::BareBench::Run.new(::BareBench::Suite.new)
          count_before = run.count[:pending]
          run.run_test(assertion)
          count_after = run.count[:pending]

          equal(count_before+1, count_after)
        end
      end

      suite "The given test was skipped" do
        assert "Increments the counter ':skipped' at the end" do
          assertion = ::BareBench::Skipped::Assertion.new(nil, "")
          run       = ::BareBench::Run.new(::BareBench::Suite.new)
          count_before = run.count[:skipped]
          run.run_test(assertion)
          count_after = run.count[:skipped]

          equal(count_before+1, count_after)
        end
      end

      suite "The given test was failure" do
        assert "Increments the counter ':failure' at the end" do
          assertion = ::BareBench::Assertion.new(nil, "") do false end
          run       = ::BareBench::Run.new(::BareBench::Suite.new)
          count_before = run.count[:failure]
          run.run_test(assertion)
          count_after = run.count[:failure]

          equal(count_before+1, count_after)
        end
      end

      suite "The given test was error" do
        assert "Increments the counter ':error' at the end" do
          assertion = ::BareBench::Assertion.new(nil, "") do raise end
          run       = ::BareBench::Run.new(::BareBench::Suite.new)
          count_before = run.count[:error]
          run.run_test(assertion)
          count_after = run.count[:error]

          equal(count_before+1, count_after)
        end
      end
    end
  end
end
