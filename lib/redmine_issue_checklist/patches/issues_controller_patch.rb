module RedmineIssueChecklist
  module Patches
    module IssuesControllerPatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceMethods
      end

      module InstanceMethods
        def build_new_issue_from_params
          super
          if User.current.allowed_to?(:edit_checklists, @issue.project)
            @issue.update_checklist_items(params[:check_list_items])
          end
        end
      end
    end
  end
end

unless IssuesController.included_modules.include? RedmineIssueChecklist::Patches::IssuesControllerPatch
  IssuesController.send :include, RedmineIssueChecklist::Patches::IssuesControllerPatch
end
