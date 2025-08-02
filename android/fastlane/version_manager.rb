require 'yaml'
require 'json'

class VersionManager
  def initialize(environment, config)
    @environment = environment
    @config = config
    @project_root = File.join(Dir.pwd, '..', '..')
  end

  # Increment build number for the current build
  def increment_build_number
    UI.header("🔄 Incrementing build number")
    
    current_version = get_current_version
    new_build_number = current_version[:build_number] + 1
    
    UI.message("Current build number: #{current_version[:build_number]}")
    UI.message("New build number: #{new_build_number}")
    
    update_version_files(new_build_number)
    commit_version_changes(new_build_number)
    
    UI.success("✅ Build number incremented to #{new_build_number}")
    new_build_number
  end

  # Update version name according to semantic versioning
  def update_version_name(version_name)
    UI.header("🔄 Updating version name to #{version_name}")
    
    unless valid_version_format?(version_name)
      UI.user_error!("Invalid version format: #{version_name}. Expected format: X.Y.Z")
    end
    
    current_version = get_current_version
    new_version = {
      version_name: version_name,
      build_number: current_version[:build_number]
    }
    
    update_version_files(new_version[:build_number], new_version[:version_name])
    commit_version_changes(new_version[:build_number], new_version[:version_name])
    
    UI.success("✅ Version updated to #{version_name}")
    new_version
  end

  # Increment patch version (1.0.0 -> 1.0.1)
  def increment_patch
    current_version = get_current_version
    version_parts = current_version[:version_name].split('.')
    new_patch = version_parts[2].to_i + 1
    new_version = "#{version_parts[0]}.#{version_parts[1]}.#{new_patch}"
    
    update_version_name(new_version)
  end

  # Increment minor version (1.0.0 -> 1.1.0)
  def increment_minor
    current_version = get_current_version
    version_parts = current_version[:version_name].split('.')
    new_minor = version_parts[1].to_i + 1
    new_version = "#{version_parts[0]}.#{new_minor}.0"
    
    update_version_name(new_version)
  end

  # Increment major version (1.0.0 -> 2.0.0)
  def increment_major
    current_version = get_current_version
    version_parts = current_version[:version_name].split('.')
    new_major = version_parts[0].to_i + 1
    new_version = "#{new_major}.0.0"
    
    update_version_name(new_version)
  end

  # Create Git tag for the current version
  def create_tag(tag_message = nil)
    UI.header("🏷️ Creating Git tag")
    
    current_version = get_current_version
    tag_name = "v#{current_version[:version_name]}"
    message = tag_message || "Release version #{current_version[:version_name]}"
    
    begin
      # Create annotated tag
      sh("git tag -a #{tag_name} -m \"#{message}\"")
      UI.success("✅ Created tag: #{tag_name}")
      
      # Push tag to remote
      sh("git push origin #{tag_name}")
      UI.success("✅ Pushed tag to remote")
      
      tag_name
    rescue => e
      UI.error("❌ Failed to create tag: #{e.message}")
      raise e
    end
  end

  # Get current version information
  def get_current_version
    pubspec_path = File.join(@project_root, 'pubspec.yaml')
    
    unless File.exist?(pubspec_path)
      UI.user_error!("pubspec.yaml not found at #{pubspec_path}")
    end
    
    begin
      content = File.read(pubspec_path)
      yaml = YAML.load(content)
      version_string = yaml['version']
      
      if version_string.nil?
        UI.user_error!("Version not found in pubspec.yaml")
      end
      
      parse_version_string(version_string)
    rescue => e
      UI.user_error!("Failed to read version from pubspec.yaml: #{e.message}")
    end
  end

  # Show current version information
  def show_current_version
    UI.header("📋 Current version information")
    
    current_version = get_current_version
    UI.message("Version Name: #{current_version[:version_name]}")
    UI.message("Build Number: #{current_version[:build_number]}")
    UI.message("Full Version: #{current_version[:version_name]}+#{current_version[:build_number]}")
    
    # Get Git information
    begin
      commit_hash = sh("git rev-parse HEAD").strip
      branch = sh("git rev-parse --abbrev-ref HEAD").strip
      
      UI.message("Git Commit: #{commit_hash[0..7]}")
      UI.message("Git Branch: #{branch}")
    rescue => e
      UI.message("Git Info: Not available")
    end
  end

  private

  # Parse version string from pubspec.yaml (e.g., "1.2.3+4")
  def parse_version_string(version_string)
    if version_string.include?('+')
      parts = version_string.split('+')
      version_name = parts[0]
      build_number = parts[1].to_i
    else
      version_name = version_string
      build_number = 1
    end
    
    {
      version_name: version_name,
      build_number: build_number
    }
  end

  # Validate version format (X.Y.Z)
  def valid_version_format?(version)
    version.match?(/^\d+\.\d+\.\d+$/)
  end

  # Update version in all configuration files
  def update_version_files(build_number, version_name = nil)
    update_pubspec_yaml(build_number, version_name)
    update_android_build_gradle(build_number, version_name)
    update_ios_info_plist(build_number, version_name)
  end

  # Update version in pubspec.yaml
  def update_pubspec_yaml(build_number, version_name = nil)
    pubspec_path = File.join(@project_root, 'pubspec.yaml')
    content = File.read(pubspec_path)
    lines = content.split("\n")
    
    current_version = get_current_version
    new_version_name = version_name || current_version[:version_name]
    new_version_string = "#{new_version_name}+#{build_number}"
    
    lines.each_with_index do |line, index|
      if line.strip.start_with?('version:')
        lines[index] = "version: #{new_version_string}"
        break
      end
    end
    
    File.write(pubspec_path, lines.join("\n"))
    UI.message("✅ Updated pubspec.yaml version to #{new_version_string}")
  end

  # Update version in Android build.gradle
  def update_android_build_gradle(build_number, version_name = nil)
    gradle_path = File.join(@project_root, 'android', 'app', 'build.gradle')
    
    unless File.exist?(gradle_path)
      UI.message("⚠️ Android build.gradle not found, skipping Android version update")
      return
    end
    
    content = File.read(gradle_path)
    lines = content.split("\n")
    
    current_version = get_current_version
    new_version_name = version_name || current_version[:version_name]
    
    lines.each_with_index do |line, index|
      line_stripped = line.strip
      if line_stripped.start_with?('versionCode')
        lines[index] = "        versionCode #{build_number}"
      elsif line_stripped.start_with?('versionName')
        lines[index] = "        versionName \"#{new_version_name}\""
      end
    end
    
    File.write(gradle_path, lines.join("\n"))
    UI.message("✅ Updated Android build.gradle version to #{new_version_name} (#{build_number})")
  end

  # Update version in iOS Info.plist
  def update_ios_info_plist(build_number, version_name = nil)
    plist_path = File.join(@project_root, 'ios', 'Runner', 'Info.plist')
    
    unless File.exist?(plist_path)
      UI.message("⚠️ iOS Info.plist not found, skipping iOS version update")
      return
    end
    
    content = File.read(plist_path)
    lines = content.split("\n")
    
    current_version = get_current_version
    new_version_name = version_name || current_version[:version_name]
    
    lines.each_with_index do |line, index|
      if line.include?('<key>CFBundleShortVersionString</key>')
        if index + 1 < lines.length
          lines[index + 1] = "\t<string>#{new_version_name}</string>"
        end
      elsif line.include?('<key>CFBundleVersion</key>')
        if index + 1 < lines.length
          lines[index + 1] = "\t<string>#{build_number}</string>"
        end
      end
    end
    
    File.write(plist_path, lines.join("\n"))
    UI.message("✅ Updated iOS Info.plist version to #{new_version_name} (#{build_number})")
  end

  # Commit version changes to Git
  def commit_version_changes(build_number, version_name = nil)
    UI.header("📝 Committing version changes")
    
    begin
      # Check if we're in a Git repository
      sh("git rev-parse --git-dir")
      
      current_version = get_current_version
      new_version_name = version_name || current_version[:version_name]
      
      # Add modified files
      sh("git add pubspec.yaml")
      sh("git add android/app/build.gradle")
      sh("git add ios/Runner/Info.plist")
      
      # Create commit message
      if version_name
        commit_message = "chore: update version to #{new_version_name}+#{build_number}"
      else
        commit_message = "chore: increment build number to #{build_number}"
      end
      
      # Commit changes
      sh("git commit -m \"#{commit_message}\"")
      UI.success("✅ Committed version changes: #{commit_message}")
      
    rescue => e
      UI.message("⚠️ Not in a Git repository or Git operation failed: #{e.message}")
    end
  end
end

# Fastlane actions for version management
module Fastlane
  module Actions
    class IncrementBuildNumberAction < Action
      def self.run(params)
        environment = params[:environment] || "development"
        config = ConfigLoader.load_environment_config(environment)
        
        version_manager = VersionManager.new(environment, config)
        version_manager.increment_build_number
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :environment, env_name: "FL_ENVIRONMENT", description: "Environment name", optional: true, default_value: "development")
        ]
      end

      def self.description
        "Increment build number"
      end

      def self.authors
        ["Version Manager"]
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end

    class UpdateVersionAction < Action
      def self.run(params)
        environment = params[:environment] || "development"
        version = params[:version]
        config = ConfigLoader.load_environment_config(environment)
        
        unless version
          UI.user_error!("Version parameter is required")
        end
        
        version_manager = VersionManager.new(environment, config)
        version_manager.update_version_name(version)
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :environment, env_name: "FL_ENVIRONMENT", description: "Environment name", optional: true, default_value: "development"),
          FastlaneCore::ConfigItem.new(key: :version, env_name: "FL_VERSION", description: "Version string (e.g., 1.2.3)", optional: false)
        ]
      end

      def self.description
        "Update version name"
      end

      def self.authors
        ["Version Manager"]
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end

    class CreateTagAction < Action
      def self.run(params)
        environment = params[:environment] || "development"
        tag_message = params[:tag_message]
        config = ConfigLoader.load_environment_config(environment)
        
        version_manager = VersionManager.new(environment, config)
        version_manager.create_tag(tag_message)
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :environment, env_name: "FL_ENVIRONMENT", description: "Environment name", optional: true, default_value: "development"),
          FastlaneCore::ConfigItem.new(key: :tag_message, env_name: "FL_TAG_MESSAGE", description: "Tag message", optional: true)
        ]
      end

      def self.description
        "Create Git tag for current version"
      end

      def self.authors
        ["Version Manager"]
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end

    class ShowVersionAction < Action
      def self.run(params)
        environment = params[:environment] || "development"
        config = ConfigLoader.load_environment_config(environment)
        
        version_manager = VersionManager.new(environment, config)
        version_manager.show_current_version
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :environment, env_name: "FL_ENVIRONMENT", description: "Environment name", optional: true, default_value: "development")
        ]
      end

      def self.description
        "Show current version information"
      end

      def self.authors
        ["Version Manager"]
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end
  end
end 