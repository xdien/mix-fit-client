require 'yaml'
require 'json'

# CI/CD Environment Manager
# Handles environment variable setup and validation for CI/CD pipelines
class CIEnvironmentManager
  def self.setup_ci_environment(environment)
    UI.header("🔧 Setting up CI environment for #{environment}")
    
    manager = new(environment)
    manager.setup_environment_variables
    manager.validate_ci_requirements
    manager.setup_build_metadata
    
    UI.success("✅ CI environment setup completed")
  end
  
  def initialize(environment)
    @environment = environment
    @is_ci = ENV['CI'] == 'true'
    @github_actions = ENV['GITHUB_ACTIONS'] == 'true'
  end
  
  def setup_environment_variables
    UI.message("Setting up environment variables for #{@environment}")
    
    # Load environment configuration
    config = ConfigLoader.load_environment_config(@environment)
    
    # Set Flutter environment variables
    ConfigLoader.setup_flutter_environment(config)
    
    # Set CI-specific variables
    setup_ci_specific_variables
    
    # Set build metadata variables
    setup_build_metadata_variables
    
    # Validate required variables are set
    validate_required_variables(config)
  end
  
  def validate_ci_requirements
    UI.message("Validating CI requirements")
    
    required_tools = ['flutter', 'fastlane']
    required_tools.each do |tool|
      unless system("which #{tool} > /dev/null 2>&1")
        UI.user_error!("Required tool not found: #{tool}")
      end
    end
    
    # Validate CI environment
    unless @is_ci
      UI.important("⚠️  Not running in CI environment")
    end
    
    # Validate GitHub Actions specific requirements
    if @github_actions
      validate_github_actions_requirements
    end
  end
  
  def setup_build_metadata
    UI.message("Setting up build metadata")
    
    metadata = {
      ci: @is_ci,
      github_actions: @github_actions,
      environment: @environment,
      build_number: ENV['BUILD_NUMBER'] || ENV['GITHUB_RUN_NUMBER'],
      commit_sha: ENV['COMMIT_SHA'] || ENV['GITHUB_SHA'],
      branch: ENV['BRANCH_NAME'] || ENV['GITHUB_REF_NAME'],
      build_time: Time.now.utc.iso8601,
      runner: ENV['RUNNER_OS'] || 'unknown'
    }
    
    # Save metadata for later use
    metadata_dir = File.join(Dir.pwd, '..', '..', 'build', 'ci')
    FileUtils.mkdir_p(metadata_dir)
    
    metadata_file = File.join(metadata_dir, 'build-metadata.json')
    File.write(metadata_file, JSON.pretty_generate(metadata))
    
    UI.message("Build metadata saved to #{metadata_file}")
  end
  
  def self.validate_secrets(environment)
    UI.header("🔍 Validating CI secrets for #{environment}")
    
    manager = new(environment)
    manager.validate_signing_secrets
    manager.validate_distribution_secrets
    manager.validate_notification_secrets
    
    UI.success("✅ CI secrets validation completed")
  end
  
  def validate_signing_secrets
    UI.message("Validating signing secrets")
    
    case @environment
    when 'development'
      required_secrets = ['DEV_STORE_PASSWORD', 'DEV_KEY_PASSWORD']
    when 'staging'
      required_secrets = ['STAGING_STORE_PASSWORD', 'STAGING_KEY_PASSWORD']
    when 'production'
      required_secrets = ['PROD_STORE_PASSWORD', 'PROD_KEY_PASSWORD']
    else
      UI.user_error!("Unknown environment: #{@environment}")
    end
    
    missing_secrets = []
    required_secrets.each do |secret|
      if ENV[secret].nil? || ENV[secret].empty?
        missing_secrets << secret
      end
    end
    
    unless missing_secrets.empty?
      UI.user_error!("Missing required secrets: #{missing_secrets.join(', ')}")
    end
    
    UI.success("All signing secrets are available")
  end
  
  def validate_distribution_secrets
    return unless @environment == 'production' || @environment == 'staging'
    
    UI.message("Validating distribution secrets")
    
    # Check Google Play credentials
    if ENV['GOOGLE_PLAY_SERVICE_ACCOUNT_JSON'].nil?
      UI.important("⚠️  Google Play service account JSON not available - uploads will be skipped")
    else
      UI.success("Google Play credentials available")
    end
  end
  
  def validate_notification_secrets
    UI.message("Validating notification secrets")
    
    # Check Slack webhook
    if ENV['SLACK_WEBHOOK_URL'].nil?
      UI.important("⚠️  Slack webhook URL not available - notifications will be skipped")
    else
      UI.success("Slack webhook available")
    end
  end
  
  def self.cleanup_ci_environment
    UI.header("🧹 Cleaning up CI environment")
    
    # Remove sensitive files
    sensitive_files = [
      'google-play-service-account.json',
      'credentials.yaml',
      'fastlane/credentials.yaml'
    ]
    
    sensitive_files.each do |file|
      file_path = File.join(Dir.pwd, file)
      if File.exist?(file_path)
        File.delete(file_path)
        UI.message("Removed sensitive file: #{file}")
      end
    end
    
    # Clear sensitive environment variables
    sensitive_vars = [
      'STORE_PASSWORD',
      'KEY_PASSWORD',
      'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON',
      'SLACK_WEBHOOK_URL'
    ]
    
    sensitive_vars.each do |var|
      ENV.delete(var)
    end
    
    UI.success("✅ CI environment cleanup completed")
  end
  
  def self.generate_ci_report(environment)
    UI.header("📊 Generating CI report for #{environment}")
    
    report = {
      environment: environment,
      ci_platform: detect_ci_platform,
      build_info: collect_build_info,
      test_results: collect_test_results,
      artifacts: collect_artifact_info,
      security: collect_security_info,
      timestamp: Time.now.utc.iso8601
    }
    
    # Save report
    report_dir = File.join(Dir.pwd, '..', '..', 'build', 'reports')
    FileUtils.mkdir_p(report_dir)
    
    report_file = File.join(report_dir, "ci-report-#{environment}-#{Time.now.strftime('%Y%m%d-%H%M%S')}.json")
    File.write(report_file, JSON.pretty_generate(report))
    
    UI.success("CI report saved to #{report_file}")
    report
  end
  
  private
  
  def setup_ci_specific_variables
    if @is_ci
      # Set CI-specific Flutter variables
      ENV['FLUTTER_CI'] = 'true'
      ENV['PUB_CACHE'] = File.join(Dir.home, '.pub-cache') unless ENV['PUB_CACHE']
      
      # Disable interactive prompts
      ENV['FLUTTER_SUPPRESS_ANALYTICS'] = 'true'
      ENV['PUB_HOSTED_URL'] = 'https://pub.dartlang.org'
    end
    
    if @github_actions
      # GitHub Actions specific variables
      ENV['GITHUB_WORKSPACE'] ||= Dir.pwd
      ENV['RUNNER_TEMP'] ||= '/tmp'
    end
  end
  
  def setup_build_metadata_variables
    # Set build number from CI if available
    if ENV['GITHUB_RUN_NUMBER']
      ENV['BUILD_NUMBER'] = ENV['GITHUB_RUN_NUMBER']
    elsif ENV['BUILD_NUMBER'].nil?
      ENV['BUILD_NUMBER'] = '1'
    end
    
    # Set commit information
    if ENV['GITHUB_SHA']
      ENV['COMMIT_SHA'] = ENV['GITHUB_SHA']
      ENV['COMMIT_SHORT_SHA'] = ENV['GITHUB_SHA'][0..7]
    end
    
    # Set branch information
    if ENV['GITHUB_REF_NAME']
      ENV['BRANCH_NAME'] = ENV['GITHUB_REF_NAME']
    end
  end
  
  def validate_required_variables(config)
    required_vars = [
      'ENVIRONMENT',
      'BUILD_TYPE',
      'API_BASE_URL',
      'WEBSOCKET_URL'
    ]
    
    missing_vars = []
    required_vars.each do |var|
      if ENV[var].nil? || ENV[var].empty?
        missing_vars << var
      end
    end
    
    unless missing_vars.empty?
      UI.user_error!("Missing required environment variables: #{missing_vars.join(', ')}")
    end
  end
  
  def validate_github_actions_requirements
    required_github_vars = [
      'GITHUB_WORKSPACE',
      'GITHUB_REPOSITORY',
      'GITHUB_RUN_ID',
      'GITHUB_RUN_NUMBER'
    ]
    
    missing_vars = []
    required_github_vars.each do |var|
      if ENV[var].nil?
        missing_vars << var
      end
    end
    
    unless missing_vars.empty?
      UI.user_error!("Missing GitHub Actions variables: #{missing_vars.join(', ')}")
    end
  end
  
  def self.detect_ci_platform
    return 'github_actions' if ENV['GITHUB_ACTIONS'] == 'true'
    return 'gitlab_ci' if ENV['GITLAB_CI'] == 'true'
    return 'jenkins' if ENV['JENKINS_URL']
    return 'circleci' if ENV['CIRCLECI'] == 'true'
    return 'travis' if ENV['TRAVIS'] == 'true'
    return 'unknown'
  end
  
  def self.collect_build_info
    {
      build_number: ENV['BUILD_NUMBER'],
      commit_sha: ENV['COMMIT_SHA'],
      branch: ENV['BRANCH_NAME'],
      flutter_version: `flutter --version`.split("\n").first,
      dart_version: `dart --version`.split(" ")[3],
      fastlane_version: Fastlane::VERSION
    }
  end
  
  def self.collect_test_results
    # This would be populated by test runners
    {
      unit_tests: 'not_run',
      integration_tests: 'not_run',
      coverage: 'not_available'
    }
  end
  
  def self.collect_artifact_info
    build_dir = File.join(Dir.pwd, '..', '..', 'build')
    return {} unless Dir.exist?(build_dir)
    
    artifacts = []
    Dir.glob(File.join(build_dir, '**', '*')).each do |file|
      next unless File.file?(file)
      next unless file.match?(/\.(apk|aab|ipa)$/)
      
      artifacts << {
        path: file,
        size: File.size(file),
        modified: File.mtime(file).iso8601
      }
    end
    
    { artifacts: artifacts, count: artifacts.length }
  end
  
  def self.collect_security_info
    {
      signing_validated: false,  # Would be set by security audit
      certificate_valid: false, # Would be set by certificate validation
      secrets_secure: false     # Would be set by secrets validation
    }
  end
end