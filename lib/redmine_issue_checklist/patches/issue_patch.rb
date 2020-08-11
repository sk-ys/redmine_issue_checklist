module RedmineIssueChecklist
  module Patches

    module IssuePatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceMethods
        has_many :checklist, class_name: 'IssueChecklist', dependent: :destroy
      end

      module InstanceMethods
        def copy_from(arg, options = {})
          ret = super
          return ret unless self.checklist.empty?
          issue = @copied_from || (arg.is_a?(Issue) ? arg : Issue.visible.find(arg))
          @issue_checklist_copied = issue.checklist.map do |c|
            attrs = c.attributes.symbolize_keys
            # Append for programmatic use, e.g. in issue.copy
            self.checklist << IssueChecklist.new(attrs.except(:id).merge is_done: false)
            # Save params-like slice for processing in update_checklist_items
            attrs.slice(:subject).merge is_done: false
          end
          ret
        end

        def update_checklist_items(checklist_items, create_journal = false)
          checklist_items ||= []

          old_checklist = checklist.collect(&:info).join(', ')

          existing = checklist_items.map { |c| c[:subject] }.to_set
          copied = (@issue_checklist_copied || []).reject { |c| existing.include? c[:subject] }
          checklist_items.unshift *copied

          checklist.destroy_all
          checklist << checklist_items.collect do |cli|
            IssueChecklist.new(is_done: cli[:is_done], subject: cli[:subject])
          end

          new_checklist = checklist.collect(&:info).join(', ')

          if current_journal && create_journal && (new_checklist != old_checklist)
            current_journal.details << JournalDetail.new(
                property: 'attr',
                prop_key: 'checklist',
                old_value: old_checklist,
                value: new_checklist)
          end
        end

      end

    end

  end
end


unless Issue.included_modules.include?(RedmineIssueChecklist::Patches::IssuePatch)
  Issue.send(:include, RedmineIssueChecklist::Patches::IssuePatch)
end
