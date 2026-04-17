# Build Logger for Fastlane Environment Configuration
# Provides detailed logging for build processes with structured output

require 'logger'
require 'json'
require 'fileutils'
require 'benchmark'

class BuildLogger
  attr_reader :logger, :build_log_path, :environment, :build_id
  
  def initialize(environment = 'development', build_type = 'debug')
    @environment = environment
    @build_type = build_type
    @build_id = generate_build_id
    @start_time = Time.now
    @build_log_path = setup_build_logging
    @step_timings = {}
    @current_step = nil
  end
  
  # Start logging a build process
  def start_build(config)
    @config = config
    
    build_info = {
      build_id: @build_id,
      environment: @environment,
      build_type: @build_type,
      start_time: @start_time.iso8601,
      config: sanitize_config_for_logging(config),
      system_info: get_system_info
    }
    
    log_structured('BUILD_START', 'Build process started', build_info)
    
    FastlaneCore::UI.header("🚀 Starting build #{@build_id} for #{@environment} environment")
    FastlaneCore::UI.message("📋 Build Type: #{@build_type}")
    FastlaneCore::UI.message("⏰ Start Time: #{@start_time.strftime('%Y-%m-%d %H:%M:%S')}")
  end
  
  # End logging a build process
  def end_build(success = true, error = nil)
    end_time = Time.now
    duration = end_time - @start_time
    
    build_result = {
      build_id: @build_id,
      environment: @environment,
      build_type: @build_type,
      success: success,
      start_time: @start_time.iso8601,
      end_time: end_time.iso8601,
      duration_seconds: duration.round(2),
      step_timings: @step_timings,
      error: error ? {
        class: error.class.name,
        message: error.message
      } : nil
    }
    
    log_structured('BUILD_END', success ? 'Build completed successfully' : 'Build failed', build_result)
    
    if success
      FastlaneCore::UI.success("✅ Build #{@build_id} completed successfully in #{format_duration(duration)}")
    else
      FastlaneCore::UI.error("❌ Build #{@build_id} failed after #{format_duration(duration)}")
    end
    
    # Generate build summary
    generate_build_summary(build_result)
    
    build_result
  end
  
  # Start a build step with timing
  def start_step(step_name, description = nil)
    @current_step = {
      name: step_name,
      description: description,
      start_time: Time.now
    }
    
    step_info = {
      build_id: @build_id,
      step_name: step_name,
      description: description,
      start_time: @current_step[:start_time].iso8601
    }
    
    log_structured('STEP_START', "Starting step: #{step_name}", step_info)
    
    FastlaneCore::UI.message("🔄 #{step_name}#{description ? ": #{description}" : ''}")
  end
  
  # End a build step with timing
  def end_step(success = true, details = {})
    return unless @current_step
    
    end_time = Time.now
    duration = end_time - @current_step[:start_time]
    
    step_result = {
      build_id: @build_id,
      step_name: @current_step[:name],
      description: @current_step[:description],
      success: success,
      start_time: @current_step[:start_time].iso8601,
      end_time: end_time.iso8601,
      duration_seconds: duration.round(2),
      details: details
    }
    
    # Store timing for summary
    @step_timings[@current_step[:name]] = {
      duration: duration.round(2),
      success: success
    }
    
    log_structured('STEP_END', "Step completed: #{@current_step[:name]}", step_result)
    
    if success
      FastlaneCore::UI.success("  ✅ #{@current_step[:name]} completed in #{format_duration(duration)}")
    else
      FastlaneCore::UI.error("  ❌ #{@current_step[:name]} failed after #{format_duration(duration)}")
    end
    
    @current_step = nil
    step_result
  end
  
  # Execute a step with automatic timing and error handling
  def execute_step(step_name, description = nil)
    start_step(step_name, description)
    
    begin
      result = yield
      end_step(true, result.is_a?(Hash) ? result : {})
      result
    rescue => error
      end_step(false, { error: error.message })
      raise error
    end
  end
  
  # Log configuration loading
  def log_config_loading(config_path, config)
    config_info = {
      build_id: @build_id,
      config_path: config_path,
      config_size: File.exist?(config_path) ? File.size(config_path) : 0,
      config_modified: File.exist?(config_path) ? File.mtime(config_path).iso8601 : nil,
      config_summary: {
        environment: config['environment']&.dig('name'),
        app_name: config['app']&.dig('name'),
        bundle_id: config['app']&.dig('bundle_id'),
        api_url: config['network']&.dig('api_base_url'),
        build_type: config['build']&.dig('build_type')
      }
    }
    
    log_structured('CONFIG_LOADED', 'Configuration loaded', config_info)
    
    FastlaneCore::UI.message("📄 Configuration loaded from #{File.basename(config_path)}")
    FastlaneCore::UI.message("   App: #{config_info[:config_summary][:app_name]}")
    FastlaneCore::UI.message("   Bundle ID: #{config_info[:config_summary][:bundle_id]}")
    FastlaneCore::UI.message("   API URL: #{config_info[:config_summary][:api_url]}")
  end
  
  # Log environment setup
  def log_environment_setup(env_vars)
    env_info = {
      build_id: @build_id,
      environment_variables: env_vars.keys,
      variable_count: env_vars.count
    }
    
    log_structured('ENV_SETUP', 'Environment variables configured', env_info)
    
    FastlaneCore::UI.message("🔧 Environment variables configured (#{env_vars.count} variables)")
    env_vars.each do |key, value|
      # Don't log sensitive values
      display_value = key.include?('PASSWORD') || key.include?('KEY') ? '[HIDDEN]' : value
      FastlaneCore::UI.verbose("   #{key}=#{display_value}")
    end
  end
  
  # Log signing setup
  def log_signing_setup(keystore_path, key_alias)
    signing_info = {
      build_id: @build_id,
      keystore_path: keystore_path,
      keystore_exists: File.exist?(keystore_path),
      keystore_size: File.exist?(keystore_path) ? File.size(keystore_path) : 0,
      key_alias: key_alias
    }
    
    log_structured('SIGNING_SETUP', 'Code signing configured', signing_info)
    
    FastlaneCore::UI.message("🔐 Code signing configured")
    FastlaneCore::UI.message("   Keystore: #{File.basename(keystore_path)}")
    FastlaneCore::UI.message("   Alias: #{key_alias}")
    FastlaneCore::UI.message("   Status: #{signing_info[:keystore_exists] ? 'Found' : 'Missing'}")
  end
  
  # Log Flutter command execution
  def log_flutter_command(command, working_dir = nil)
    command_info = {
      build_id: @build_id,
      command: command,
      working_directory: working_dir || Dir.pwd,
      timestamp: Time.now.iso8601
    }
    
    log_structured('FLUTTER_COMMAND', 'Executing Flutter command', command_info)
    
    FastlaneCore::UI.message("🔨 Executing: #{command}")
    if working_dir
      FastlaneCore::UI.verbose("   Working directory: #{working_dir}")
    end
  end
  
  # Log command output
  def log_command_output(command, output, exit_status)
    output_info = {
      build_id: @build_id,
      command: command,
      exit_status: exit_status,
      output_lines: output.lines.count,
      success: exit_status == 0
    }
    
    log_structured('COMMAND_OUTPUT', 'Command execution completed', output_info)
    
    if exit_status == 0
      FastlaneCore::UI.success("   ✅ Command completed successfully")
    else
      FastlaneCore::UI.error("   ❌ Command failed with exit status #{exit_status}")
    end
    
    # Log output in debug mode
    if ENV['FASTLANE_DEBUG'] == 'true' && output && !output.empty?
      FastlaneCore::UI.verbose("Command output:")
      output.lines.each do |line|
        FastlaneCore::UI.verbose("  #{line.chomp}")
      end
    end
  end
  
  # Log artifact generation
  def log_artifact_generation(artifacts)
    artifact_info = {
      build_id: @build_id,
      artifacts: artifacts.map do |artifact|
        {
          type: artifact[:type],
          path: artifact[:path],
          filename: File.basename(artifact[:path]),
          size: File.exist?(artifact[:path]) ? File.size(artifact[:path]) : 0,
          size_human: File.exist?(artifact[:path]) ? format_file_size(File.size(artifact[:path])) : '0 B'
        }
      end,
      total_artifacts: artifacts.count
    }
    
    log_structured('ARTIFACTS_GENERATED', 'Build artifacts generated', artifact_info)
    
    FastlaneCore::UI.message("📦 Generated #{artifacts.count} build artifacts:")
    artifacts.each do |artifact|
      size_info = File.exist?(artifact[:path]) ? " (#{format_file_size(File.size(artifact[:path]))})" : " (missing)"
      FastlaneCore::UI.message("   #{artifact[:type]}: #{File.basename(artifact[:path])}#{size_info}")
    end
  end
  
  # Log version management
  def log_version_update(old_version, new_version, version_type = 'build')
    version_info = {
      build_id: @build_id,
      version_type: version_type,
      old_version: old_version,
      new_version: new_version,
      timestamp: Time.now.iso8601
    }
    
    log_structured('VERSION_UPDATE', "Version #{version_type} updated", version_info)
    
    FastlaneCore::UI.message("🔢 Version #{version_type} updated: #{old_version} → #{new_version}")
  end
  
  # Log warnings
  def log_warning(message, context = {})
    warning_info = {
      build_id: @build_id,
      message: message,
      context: context,
      timestamp: Time.now.iso8601
    }
    
    log_structured('WARNING', message, warning_info)
    FastlaneCore::UI.important("⚠️  #{message}")
  end
  
  # Log performance metrics
  def log_performance_metrics(metrics)
    perf_info = {
      build_id: @build_id,
      metrics: metrics,
      timestamp: Time.now.iso8601
    }
    
    log_structured('PERFORMANCE', 'Performance metrics', perf_info)
    
    FastlaneCore::UI.message("📊 Performance Metrics:")
    metrics.each do |key, value|
      FastlaneCore::UI.message("   #{key}: #{value}")
    end
  end
  
  # Generate build summary report
  def generate_build_summary(build_result)
    summary_dir = File.join(Dir.pwd, '..', '..', 'build', 'build_summaries')
    FileUtils.mkdir_p(summary_dir)
    
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    summary_file = File.join(summary_dir, "build_summary_#{@environment}_#{timestamp}.json")
    
    # Enhanced summary with additional metrics
    enhanced_summary = build_result.merge({
      performance_metrics: calculate_performance_metrics,
      step_analysis: analyze_step_performance,
      recommendations: generate_recommendations
    })
    
    File.write(summary_file, JSON.pretty_generate(enhanced_summary))
    
    # Also create human-readable summary
    text_summary_file = File.join(summary_dir, "build_summary_#{@environment}_#{timestamp}.txt")
    generate_text_summary(enhanced_summary, text_summary_file)
    
    FastlaneCore::UI.message("📋 Build summary saved to #{summary_file}")
  end
  
  private
  
  def setup_build_logging
    log_dir = File.join(Dir.pwd, '..', '..', 'build', 'build_logs')
    FileUtils.mkdir_p(log_dir)
    
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    log_file = File.join(log_dir, "build_#{@environment}_#{timestamp}.log")
    
    @logger = Logger.new(log_file)
    @logger.level = Logger::DEBUG
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime.iso8601} [#{severity}] #{msg}\n"
    end
    
    log_file
  end
  
  def generate_build_id
    "#{@environment}_#{@build_type}_#{Time.now.strftime('%Y%m%d_%H%M%S')}_#{SecureRandom.hex(4)}"
  end
  
  def log_structured(event_type, message, data = {})
    log_entry = {
      event_type: event_type,
      message: message,
      timestamp: Time.now.iso8601,
      data: data
    }
    
    @logger.info(JSON.generate(log_entry))
  end
  
  def sanitize_config_for_logging(config)
    # Remove sensitive information from config for logging
    sanitized = config.deep_dup
    
    if sanitized['signing']
      sanitized['signing']['store_password_env'] = '[HIDDEN]'
      sanitized['signing']['key_password_env'] = '[HIDDEN]'
    end
    
    sanitized
  end
  
  def get_system_info
    {
      ruby_version: RUBY_VERSION,
      fastlane_version: Fastlane::VERSION,
      platform: RUBY_PLATFORM,
      working_directory: Dir.pwd,
      hostname: Socket.gethostname,
      user: ENV['USER'] || ENV['USERNAME'],
      ci_environment: ENV['CI'] == 'true'
    }
  end
  
  def format_duration(seconds)
    if seconds < 60
      "#{seconds.round(1)}s"
    elsif seconds < 3600
      minutes = (seconds / 60).floor
      remaining_seconds = (seconds % 60).round(1)
      "#{minutes}m #{remaining_seconds}s"
    else
      hours = (seconds / 3600).floor
      remaining_minutes = ((seconds % 3600) / 60).floor
      "#{hours}h #{remaining_minutes}m"
    end
  end
  
  def format_file_size(bytes)
    units = ['B', 'KB', 'MB', 'GB']
    size = bytes.to_f
    unit_index = 0
    
    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end
    
    "#{size.round(1)} #{units[unit_index]}"
  end
  
  def calculate_performance_metrics
    total_duration = @step_timings.values.sum { |timing| timing[:duration] }
    successful_steps = @step_timings.values.count { |timing| timing[:success] }
    failed_steps = @step_timings.values.count { |timing| !timing[:success] }
    
    {
      total_build_time: total_duration.round(2),
      total_steps: @step_timings.count,
      successful_steps: successful_steps,
      failed_steps: failed_steps,
      success_rate: @step_timings.count > 0 ? (successful_steps.to_f / @step_timings.count * 100).round(1) : 0,
      average_step_time: @step_timings.count > 0 ? (total_duration / @step_timings.count).round(2) : 0
    }
  end
  
  def analyze_step_performance
    return {} if @step_timings.empty?
    
    sorted_steps = @step_timings.sort_by { |_, timing| timing[:duration] }.reverse
    
    {
      slowest_step: {
        name: sorted_steps.first[0],
        duration: sorted_steps.first[1][:duration]
      },
      fastest_step: {
        name: sorted_steps.last[0],
        duration: sorted_steps.last[1][:duration]
      },
      step_breakdown: sorted_steps.map do |name, timing|
        {
          name: name,
          duration: timing[:duration],
          success: timing[:success],
          percentage: ((timing[:duration] / @step_timings.values.sum { |t| t[:duration] }) * 100).round(1)
        }
      end
    }
  end
  
  def generate_recommendations
    recommendations = []
    
    # Performance recommendations
    if @step_timings.any?
      slowest_step = @step_timings.max_by { |_, timing| timing[:duration] }
      if slowest_step[1][:duration] > 60 # More than 1 minute
        recommendations << {
          type: 'performance',
          message: "Step '#{slowest_step[0]}' took #{format_duration(slowest_step[1][:duration])}. Consider optimizing this step.",
          priority: 'medium'
        }
      end
    end
    
    # Build type recommendations
    if @build_type == 'debug' && @environment == 'production'
      recommendations << {
        type: 'configuration',
        message: "Using debug build type for production environment. Consider using release build type.",
        priority: 'high'
      }
    end
    
    # Environment recommendations
    if @environment == 'development' && @step_timings.values.any? { |timing| !timing[:success] }
      recommendations << {
        type: 'development',
        message: "Build failures in development environment. Consider running 'flutter clean' and checking dependencies.",
        priority: 'low'
      }
    end
    
    recommendations
  end
  
  def generate_text_summary(summary, file_path)
    lines = []
    lines << "BUILD SUMMARY"
    lines << "=" * 50
    lines << "Build ID: #{summary[:build_id]}"
    lines << "Environment: #{summary[:environment]}"
    lines << "Build Type: #{summary[:build_type]}"
    lines << "Status: #{summary[:success] ? 'SUCCESS' : 'FAILED'}"
    lines << "Duration: #{format_duration(summary[:duration_seconds])}"
    lines << "Start Time: #{summary[:start_time]}"
    lines << "End Time: #{summary[:end_time]}"
    lines << ""
    
    if summary[:performance_metrics]
      metrics = summary[:performance_metrics]
      lines << "PERFORMANCE METRICS"
      lines << "-" * 30
      lines << "Total Steps: #{metrics[:total_steps]}"
      lines << "Successful Steps: #{metrics[:successful_steps]}"
      lines << "Failed Steps: #{metrics[:failed_steps]}"
      lines << "Success Rate: #{metrics[:success_rate]}%"
      lines << "Average Step Time: #{format_duration(metrics[:average_step_time])}"
      lines << ""
    end
    
    if summary[:step_analysis] && summary[:step_analysis][:step_breakdown]
      lines << "STEP BREAKDOWN"
      lines << "-" * 30
      summary[:step_analysis][:step_breakdown].each do |step|
        status = step[:success] ? "✅" : "❌"
        lines << "#{status} #{step[:name]}: #{format_duration(step[:duration])} (#{step[:percentage]}%)"
      end
      lines << ""
    end
    
    if summary[:recommendations] && summary[:recommendations].any?
      lines << "RECOMMENDATIONS"
      lines << "-" * 30
      summary[:recommendations].each_with_index do |rec, index|
        priority_icon = case rec[:priority]
                       when 'high' then '🔴'
                       when 'medium' then '🟡'
                       when 'low' then '🟢'
                       else '⚪'
                       end
        lines << "#{index + 1}. #{priority_icon} #{rec[:message]}"
      end
      lines << ""
    end
    
    if summary[:error]
      lines << "ERROR DETAILS"
      lines << "-" * 30
      lines << "Error Class: #{summary[:error][:class]}"
      lines << "Error Message: #{summary[:error][:message]}"
    end
    
    File.write(file_path, lines.join("\n"))
  end
end

# Extension to Hash for deep_dup (if not available)
class Hash
  def deep_dup
    hash = dup
    each_pair do |key, value|
      if key.frozen? && ::String === key
        hash[key] = value.is_a?(Hash) ? value.deep_dup : value
      else
        hash.delete(key)
        hash[key.is_a?(Hash) ? key.deep_dup : key] = value.is_a?(Hash) ? value.deep_dup : value
      end
    end
    hash
  end
end