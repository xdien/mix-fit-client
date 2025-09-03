require 'json'
require 'time'

class VersionHistoryManager
  def initialize(project_root)
    @project_root = project_root
    @history_file = File.join(@project_root, 'version_history.json')
  end

  # Record a version change in history
  def record_version_change(old_version, new_version, change_type, environment, commit_hash = nil)
    history = load_history
    
    entry = {
      'timestamp' => Time.now.iso8601,
      'old_version' => old_version,
      'new_version' => new_version,
      'change_type' => change_type, # 'build_increment', 'patch', 'minor', 'major', 'manual'
      'environment' => environment,
      'commit_hash' => commit_hash || get_current_commit_hash,
      'branch' => get_current_branch
    }
    
    history['changes'] << entry
    history['last_updated'] = Time.now.iso8601
    
    save_history(history)
    
    UI.message("📝 Version change recorded: #{old_version} → #{new_version} (#{change_type})")
  end

  # Get version history
  def get_history(limit = nil)
    history = load_history
    changes = history['changes']
    
    if limit
      changes = changes.last(limit)
    end
    
    changes
  end

  # Get version statistics
  def get_statistics
    history = load_history
    changes = history['changes']
    
    stats = {
      'total_changes' => changes.length,
      'build_increments' => changes.count { |c| c['change_type'] == 'build_increment' },
      'patch_releases' => changes.count { |c| c['change_type'] == 'patch' },
      'minor_releases' => changes.count { |c| c['change_type'] == 'minor' },
      'major_releases' => changes.count { |c| c['change_type'] == 'major' },
      'manual_updates' => changes.count { |c| c['change_type'] == 'manual' },
      'first_recorded' => changes.first&.dig('timestamp'),
      'last_updated' => history['last_updated']
    }
    
    if changes.any?
      # Calculate average time between releases
      timestamps = changes.map { |c| Time.parse(c['timestamp']) }
      if timestamps.length > 1
        total_duration = timestamps.last - timestamps.first
        stats['average_days_between_changes'] = (total_duration / (timestamps.length - 1) / 86400).round(2)
      end
    end
    
    stats
  end

  # Generate changelog from version history
  def generate_changelog(since_version = nil)
    history = load_history
    changes = history['changes']
    
    if since_version
      # Find changes since the specified version
      since_index = changes.find_index { |c| c['new_version']['version_name'] == since_version }
      changes = changes[(since_index + 1)..-1] if since_index
    end
    
    changelog = "# Changelog\n\n"
    
    # Group by version name
    grouped_changes = changes.group_by { |c| c['new_version']['version_name'] }
    
    grouped_changes.each do |version, version_changes|
      changelog += "## Version #{version}\n\n"
      
      version_changes.each do |change|
        timestamp = Time.parse(change['timestamp']).strftime('%Y-%m-%d %H:%M')
        changelog += "- #{change['change_type'].capitalize} release on #{timestamp}"
        changelog += " (#{change['environment']})" if change['environment']
        changelog += " - Build #{change['new_version']['build_number']}"
        changelog += "\n"
      end
      
      changelog += "\n"
    end
    
    changelog
  end

  # Clean old history entries
  def cleanup_history(keep_days = 90)
    history = load_history
    cutoff_date = Time.now - (keep_days * 24 * 60 * 60)
    
    original_count = history['changes'].length
    history['changes'] = history['changes'].select do |change|
      Time.parse(change['timestamp']) > cutoff_date
    end
    
    removed_count = original_count - history['changes'].length
    
    if removed_count > 0
      save_history(history)
      UI.message("🧹 Cleaned up #{removed_count} old version history entries")
    end
    
    removed_count
  end

  # Export history to different formats
  def export_history(format = 'json', output_file = nil)
    history = load_history
    
    case format.downcase
    when 'json'
      content = JSON.pretty_generate(history)
      extension = '.json'
    when 'csv'
      content = generate_csv_export(history['changes'])
      extension = '.csv'
    when 'markdown'
      content = generate_changelog
      extension = '.md'
    else
      raise ArgumentError, "Unsupported export format: #{format}"
    end
    
    output_file ||= File.join(@project_root, "version_history_export_#{Time.now.strftime('%Y%m%d_%H%M%S')}#{extension}")
    
    File.write(output_file, content)
    UI.success("📤 Version history exported to #{output_file}")
    
    output_file
  end

  private

  def load_history
    if File.exist?(@history_file)
      begin
        JSON.parse(File.read(@history_file))
      rescue JSON::ParserError => e
        UI.error("⚠️ Failed to parse version history file: #{e.message}")
        create_empty_history
      end
    else
      create_empty_history
    end
  end

  def save_history(history)
    File.write(@history_file, JSON.pretty_generate(history))
  end

  def create_empty_history
    {
      'version' => '1.0',
      'created' => Time.now.iso8601,
      'last_updated' => Time.now.iso8601,
      'changes' => []
    }
  end

  def get_current_commit_hash
    begin
      `git rev-parse HEAD`.strip
    rescue
      nil
    end
  end

  def get_current_branch
    begin
      `git rev-parse --abbrev-ref HEAD`.strip
    rescue
      nil
    end
  end

  def generate_csv_export(changes)
    require 'csv'
    
    CSV.generate do |csv|
      # Header
      csv << ['Timestamp', 'Old Version', 'New Version', 'Change Type', 'Environment', 'Commit Hash', 'Branch']
      
      # Data rows
      changes.each do |change|
        csv << [
          change['timestamp'],
          "#{change['old_version']['version_name']}+#{change['old_version']['build_number']}",
          "#{change['new_version']['version_name']}+#{change['new_version']['build_number']}",
          change['change_type'],
          change['environment'],
          change['commit_hash'],
          change['branch']
        ]
      end
    end
  end
end