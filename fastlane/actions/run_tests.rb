require 'json'
require 'fileutils'

module Fastlane
  module Actions
    class RunTestsAction < Action
      def self.run(params)
        UI.message("Starting Flutter test execution...")
        
        # Create test reports directory
        reports_dir = File.join(Dir.pwd, 'test_reports')
        FileUtils.mkdir_p(reports_dir)
        
        # Initialize test results
        test_results = {
          success: false,
          unit_tests: { passed: 0, failed: 0, skipped: 0 },
          widget_tests: { passed: 0, failed: 0, skipped: 0 },
          integration_tests: { passed: 0, failed: 0, skipped: 0 },
          coverage_percentage: 0.0,
          duration: 0,
          reports: {
            unit_test_report: File.join(reports_dir, 'unit_test_report.json'),
            widget_test_report: File.join(reports_dir, 'widget_test_report.json'),
            integration_test_report: File.join(reports_dir, 'integration_test_report.json'),
            coverage_report: File.join(reports_dir, 'coverage_report.lcov'),
            html_coverage_report: File.join(reports_dir, 'coverage', 'index.html')
          }
        }
        
        start_time = Time.now
        
        begin
          # Run unit tests
          if params[:run_unit_tests]
            UI.message("Running unit tests...")
            unit_test_result = run_unit_tests(reports_dir, params)
            test_results[:unit_tests] = unit_test_result
          end
          
          # Run widget tests
          if params[:run_widget_tests]
            UI.message("Running widget tests...")
            widget_test_result = run_widget_tests(reports_dir, params)
            test_results[:widget_tests] = widget_test_result
          end
          
          # Run integration tests
          if params[:run_integration_tests] && Dir.exist?('integration_test')
            UI.message("Running integration tests...")
            integration_test_result = run_integration_tests(reports_dir, params)
            test_results[:integration_tests] = integration_test_result
          end
          
          # Generate code coverage
          if params[:generate_coverage]
            UI.message("Generating code coverage report...")
            coverage_percentage = generate_coverage_report(reports_dir, params)
            test_results[:coverage_percentage] = coverage_percentage
          end
          
          # Calculate total duration
          test_results[:duration] = Time.now - start_time
          
          # Determine overall success
          total_failed = test_results[:unit_tests][:failed] + 
                        test_results[:widget_tests][:failed] + 
                        test_results[:integration_tests][:failed]
          
          test_results[:success] = total_failed == 0
          
          # Generate summary report
          generate_summary_report(test_results, reports_dir)
          
          # Display results
          display_test_results(test_results)
          
          # Set lane context
          Actions.lane_context[SharedValues::TEST_RESULTS] = test_results
          Actions.lane_context[SharedValues::TEST_SUCCESS] = test_results[:success]
          Actions.lane_context[SharedValues::TEST_COVERAGE] = test_results[:coverage_percentage]
          
          if test_results[:success]
            UI.success("All tests passed successfully!")
          else
            if params[:fail_build_on_test_failure]
              UI.user_error!("Tests failed! Build cannot continue.")
            else
              UI.important("Some tests failed, but continuing build as requested.")
            end
          end
          
          return test_results
          
        rescue => e
          UI.error("Test execution failed: #{e.message}")
          UI.error("Stack trace: #{e.backtrace.join("\n")}")
          
          test_results[:success] = false
          test_results[:error] = e.message
          
          if params[:fail_build_on_test_failure]
            UI.user_error!("Test execution failed: #{e.message}")
          else
            UI.important("Test execution failed, but continuing build as requested.")
            return test_results
          end
        end
      end
      
      private
      
      def self.run_unit_tests(reports_dir, params)
        UI.message("Executing unit tests...")
        
        # Prepare test command
        test_cmd = ['flutter', 'test']
        test_cmd << '--coverage' if params[:generate_coverage]
        test_cmd << '--reporter=json' if params[:json_output]
        test_cmd << '--concurrency=4' # Run tests in parallel
        test_cmd << '--test-randomize-ordering-seed=random'
        
        # Add custom test directory if specified
        if params[:test_directory] && Dir.exist?(params[:test_directory])
          test_cmd << params[:test_directory]
        else
          test_cmd << 'test/'
        end
        
        # Execute tests and capture output
        output_file = File.join(reports_dir, 'unit_test_output.txt')
        json_output_file = File.join(reports_dir, 'unit_test_report.json')
        
        success = false
        test_output = ""
        
        begin
          if params[:json_output]
            # Run with JSON output for detailed parsing
            cmd_with_json = test_cmd + ['--reporter=json']
            test_output = sh(cmd_with_json.join(' '), log: false, error_callback: ->(result) {
              # Don't fail immediately, we'll handle the result
            })
            
            # Write JSON output to file
            File.write(json_output_file, test_output)
            success = $?.success?
          else
            # Run with regular output
            test_output = sh(test_cmd.join(' '), log: false, error_callback: ->(result) {
              # Don't fail immediately, we'll handle the result
            })
            success = $?.success?
          end
          
          # Write output to file
          File.write(output_file, test_output)
          
        rescue => e
          UI.error("Unit test execution failed: #{e.message}")
          test_output = e.message
          File.write(output_file, test_output)
        end
        
        # Parse test results
        parse_test_results(test_output, json_output_file, 'unit')
      end
      
      def self.run_widget_tests(reports_dir, params)
        UI.message("Executing widget tests...")
        
        # Widget tests are typically in the same test directory but focus on widget testing
        widget_test_pattern = 'test/**/*_widget_test.dart'
        widget_tests = Dir.glob(widget_test_pattern)
        
        if widget_tests.empty?
          UI.message("No widget tests found matching pattern: #{widget_test_pattern}")
          return { passed: 0, failed: 0, skipped: 0 }
        end
        
        # Run widget tests specifically
        test_cmd = ['flutter', 'test']
        test_cmd << '--coverage' if params[:generate_coverage]
        test_cmd << '--reporter=json' if params[:json_output]
        test_cmd += widget_tests
        
        output_file = File.join(reports_dir, 'widget_test_output.txt')
        json_output_file = File.join(reports_dir, 'widget_test_report.json')
        
        success = false
        test_output = ""
        
        begin
          if params[:json_output]
            cmd_with_json = test_cmd + ['--reporter=json']
            test_output = sh(cmd_with_json.join(' '), log: false, error_callback: ->(result) {})
            File.write(json_output_file, test_output)
            success = $?.success?
          else
            test_output = sh(test_cmd.join(' '), log: false, error_callback: ->(result) {})
            success = $?.success?
          end
          
          File.write(output_file, test_output)
          
        rescue => e
          UI.error("Widget test execution failed: #{e.message}")
          test_output = e.message
          File.write(output_file, test_output)
        end
        
        parse_test_results(test_output, json_output_file, 'widget')
      end
      
      def self.run_integration_tests(reports_dir, params)
        UI.message("Executing integration tests...")
        
        # Check if integration_test directory exists
        unless Dir.exist?('integration_test')
          UI.message("No integration_test directory found, skipping integration tests")
          return { passed: 0, failed: 0, skipped: 0 }
        end
        
        # Run integration tests
        test_cmd = ['flutter', 'test', 'integration_test/']
        test_cmd << '--coverage' if params[:generate_coverage]
        test_cmd << '--reporter=json' if params[:json_output]
        
        output_file = File.join(reports_dir, 'integration_test_output.txt')
        json_output_file = File.join(reports_dir, 'integration_test_report.json')
        
        success = false
        test_output = ""
        
        begin
          if params[:json_output]
            cmd_with_json = test_cmd + ['--reporter=json']
            test_output = sh(cmd_with_json.join(' '), log: false, error_callback: ->(result) {})
            File.write(json_output_file, test_output)
            success = $?.success?
          else
            test_output = sh(test_cmd.join(' '), log: false, error_callback: ->(result) {})
            success = $?.success?
          end
          
          File.write(output_file, test_output)
          
        rescue => e
          UI.error("Integration test execution failed: #{e.message}")
          test_output = e.message
          File.write(output_file, test_output)
        end
        
        parse_test_results(test_output, json_output_file, 'integration')
      end
      
      def self.generate_coverage_report(reports_dir, params)
        UI.message("Generating code coverage report...")
        
        coverage_file = 'coverage/lcov.info'
        target_coverage_file = File.join(reports_dir, 'coverage_report.lcov')
        
        unless File.exist?(coverage_file)
          UI.important("No coverage file found at #{coverage_file}")
          return 0.0
        end
        
        # Copy coverage file to reports directory
        FileUtils.cp(coverage_file, target_coverage_file)
        
        # Generate HTML coverage report if genhtml is available
        html_coverage_dir = File.join(reports_dir, 'coverage')
        
        begin
          # Try to generate HTML report using genhtml (part of lcov package)
          sh("genhtml #{target_coverage_file} -o #{html_coverage_dir}", log: false)
          UI.success("HTML coverage report generated at #{html_coverage_dir}/index.html")
        rescue
          UI.important("genhtml not available, skipping HTML coverage report generation")
          UI.important("Install lcov package to generate HTML coverage reports")
        end
        
        # Parse coverage percentage from lcov file
        coverage_percentage = parse_coverage_percentage(target_coverage_file)
        
        UI.message("Code coverage: #{coverage_percentage.round(2)}%")
        
        # Check minimum coverage threshold
        if params[:minimum_coverage] && coverage_percentage < params[:minimum_coverage]
          error_msg = "Code coverage #{coverage_percentage.round(2)}% is below minimum threshold #{params[:minimum_coverage]}%"
          if params[:fail_build_on_low_coverage]
            UI.user_error!(error_msg)
          else
            UI.important(error_msg)
          end
        end
        
        coverage_percentage
      end
      
      def self.parse_test_results(test_output, json_file, test_type)
        results = { passed: 0, failed: 0, skipped: 0 }
        
        begin
          if File.exist?(json_file) && File.size(json_file) > 0
            # Parse JSON output for detailed results
            json_content = File.read(json_file)
            json_lines = json_content.split("\n").select { |line| line.strip.start_with?('{') }
            
            json_lines.each do |line|
              begin
                event = JSON.parse(line)
                case event['type']
                when 'testDone'
                  if event['result'] == 'success'
                    results[:passed] += 1
                  elsif event['result'] == 'failure' || event['result'] == 'error'
                    results[:failed] += 1
                  elsif event['result'] == 'skip'
                    results[:skipped] += 1
                  end
                end
              rescue JSON::ParserError
                # Skip invalid JSON lines
              end
            end
          else
            # Fallback to parsing text output
            if test_output.include?('All tests passed!')
              # Simple heuristic for successful tests
              test_count = test_output.scan(/^\d+:\d+/).length
              results[:passed] = test_count > 0 ? test_count : 1
            elsif test_output.include?('Some tests failed')
              # Try to extract numbers from output
              if match = test_output.match(/(\d+) passed.*?(\d+) failed/)
                results[:passed] = match[1].to_i
                results[:failed] = match[2].to_i
              else
                results[:failed] = 1
              end
            end
          end
        rescue => e
          UI.error("Error parsing #{test_type} test results: #{e.message}")
          # Default to failure if we can't parse
          results[:failed] = 1
        end
        
        UI.message("#{test_type.capitalize} tests - Passed: #{results[:passed]}, Failed: #{results[:failed]}, Skipped: #{results[:skipped]}")
        results
      end
      
      def self.parse_coverage_percentage(lcov_file)
        return 0.0 unless File.exist?(lcov_file)
        
        total_lines = 0
        covered_lines = 0
        
        File.readlines(lcov_file).each do |line|
          if line.start_with?('LF:')
            total_lines += line.split(':')[1].to_i
          elsif line.start_with?('LH:')
            covered_lines += line.split(':')[1].to_i
          end
        end
        
        return 0.0 if total_lines == 0
        (covered_lines.to_f / total_lines.to_f) * 100.0
      end
      
      def self.generate_summary_report(test_results, reports_dir)
        summary_file = File.join(reports_dir, 'test_summary.json')
        
        summary = {
          timestamp: Time.now.iso8601,
          success: test_results[:success],
          duration_seconds: test_results[:duration].round(2),
          total_tests: {
            passed: test_results[:unit_tests][:passed] + test_results[:widget_tests][:passed] + test_results[:integration_tests][:passed],
            failed: test_results[:unit_tests][:failed] + test_results[:widget_tests][:failed] + test_results[:integration_tests][:failed],
            skipped: test_results[:unit_tests][:skipped] + test_results[:widget_tests][:skipped] + test_results[:integration_tests][:skipped]
          },
          unit_tests: test_results[:unit_tests],
          widget_tests: test_results[:widget_tests],
          integration_tests: test_results[:integration_tests],
          coverage_percentage: test_results[:coverage_percentage],
          reports: test_results[:reports]
        }
        
        File.write(summary_file, JSON.pretty_generate(summary))
        UI.message("Test summary report generated: #{summary_file}")
      end
      
      def self.display_test_results(test_results)
        UI.header("Test Results Summary")
        
        total_passed = test_results[:unit_tests][:passed] + test_results[:widget_tests][:passed] + test_results[:integration_tests][:passed]
        total_failed = test_results[:unit_tests][:failed] + test_results[:widget_tests][:failed] + test_results[:integration_tests][:failed]
        total_skipped = test_results[:unit_tests][:skipped] + test_results[:widget_tests][:skipped] + test_results[:integration_tests][:skipped]
        
        summary_table = {
          "Overall Status" => test_results[:success] ? "✅ PASSED" : "❌ FAILED",
          "Duration" => "#{test_results[:duration].round(2)}s",
          "Total Tests" => "#{total_passed + total_failed + total_skipped}",
          "Passed" => "#{total_passed}",
          "Failed" => "#{total_failed}",
          "Skipped" => "#{total_skipped}",
          "Unit Tests" => "#{test_results[:unit_tests][:passed]}/#{test_results[:unit_tests][:passed] + test_results[:unit_tests][:failed]}",
          "Widget Tests" => "#{test_results[:widget_tests][:passed]}/#{test_results[:widget_tests][:passed] + test_results[:widget_tests][:failed]}",
          "Integration Tests" => "#{test_results[:integration_tests][:passed]}/#{test_results[:integration_tests][:passed] + test_results[:integration_tests][:failed]}",
          "Code Coverage" => "#{test_results[:coverage_percentage].round(2)}%"
        }
        
        FastlaneCore::PrintTable.print_values(
          config: summary_table,
          title: "Test Execution Results"
        )
      end
      
      def self.description
        "Execute Flutter tests with comprehensive reporting and code coverage"
      end
      
      def self.details
        "This action runs Flutter unit tests, widget tests, and integration tests. " \
        "It generates detailed test reports, collects code coverage, and provides " \
        "comprehensive error reporting. The action can be configured to fail the " \
        "build on test failures or low code coverage."
      end
      
      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :run_unit_tests,
            description: "Whether to run unit tests",
            optional: true,
            default_value: true,
            type: Boolean
          ),
          FastlaneCore::ConfigItem.new(
            key: :run_widget_tests,
            description: "Whether to run widget tests",
            optional: true,
            default_value: true,
            type: Boolean
          ),
          FastlaneCore::ConfigItem.new(
            key: :run_integration_tests,
            description: "Whether to run integration tests",
            optional: true,
            default_value: true,
            type: Boolean
          ),
          FastlaneCore::ConfigItem.new(
            key: :generate_coverage,
            description: "Whether to generate code coverage report",
            optional: true,
            default_value: true,
            type: Boolean
          ),
          FastlaneCore::ConfigItem.new(
            key: :fail_build_on_test_failure,
            description: "Whether to fail the build if tests fail",
            optional: true,
            default_value: true,
            type: Boolean
          ),
          FastlaneCore::ConfigItem.new(
            key: :fail_build_on_low_coverage,
            description: "Whether to fail the build if coverage is below minimum",
            optional: true,
            default_value: false,
            type: Boolean
          ),
          FastlaneCore::ConfigItem.new(
            key: :minimum_coverage,
            description: "Minimum code coverage percentage required",
            optional: true,
            type: Float
          ),
          FastlaneCore::ConfigItem.new(
            key: :test_directory,
            description: "Custom test directory path",
            optional: true,
            default_value: "test/",
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :json_output,
            description: "Whether to generate JSON test output for detailed parsing",
            optional: true,
            default_value: true,
            type: Boolean
          )
        ]
      end
      
      def self.output
        [
          ['TEST_RESULTS', 'Complete test results hash with all test statistics'],
          ['TEST_SUCCESS', 'Boolean indicating if all tests passed'],
          ['TEST_COVERAGE', 'Code coverage percentage as float']
        ]
      end
      
      def self.return_value
        "Returns a hash containing detailed test results, coverage information, and report file paths"
      end
      
      def self.authors
        ["IoTeck Solutions"]
      end
      
      def self.is_supported?(platform)
        true # Supports all platforms since it's Flutter testing
      end
      
      def self.example_code
        [
          'run_tests',
          'run_tests(generate_coverage: true, minimum_coverage: 80.0)',
          'test_results = run_tests(fail_build_on_test_failure: false)',
          'run_tests(run_integration_tests: false, minimum_coverage: 70.0, fail_build_on_low_coverage: true)'
        ]
      end
      
      def self.category
        :testing
      end
    end
  end
end

# Define shared values for lane context
module Fastlane
  module Actions
    module SharedValues
      TEST_RESULTS = :TEST_RESULTS
      TEST_SUCCESS = :TEST_SUCCESS
      TEST_COVERAGE = :TEST_COVERAGE
    end
  end
end