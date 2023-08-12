require_dependency File.expand_path('../redmine_issue_checklist/hooks/views_issues_hook.rb', __FILE__)
require_dependency File.expand_path('../redmine_issue_checklist/hooks/model_issue_hook.rb', __FILE__)

zeitwerk_enabled = Rails.version > '6.0' && Rails.autoloaders.zeitwerk_enabled?
Rails.configuration.__send__(zeitwerk_enabled ? :after_initialize : :to_prepare) do
  require_dependency File.expand_path('../redmine_issue_checklist/patches/issue_patch.rb', __FILE__)
  require_dependency File.expand_path('../redmine_issue_checklist/patches/issues_controller_patch.rb', __FILE__)
end

module RedmineIssueChecklist

  def self.settings()
    Setting[:plugin_redmine_issue_checklist].blank? ? {} : Setting[:plugin_redmine_issue_checklist]
  end

end

