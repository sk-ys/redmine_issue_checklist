module RedmineIssueChecklist
  module Patches

    module IssuePatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceMethods
        has_many :checklist, class_name: 'IssueChecklist', dependent: :destroy
      end

      module InstanceMethods
        def copy_from(arg, options={})
          super(arg, options)
          issue          = arg.is_a?(Issue) ? arg : Issue.visible.find(arg)
          self.checklist = issue.checklist.map { |cl| cl.dup }
          self.checklist.each do |object|
            object.is_done = nil
          end
          self
        end

        def update_checklist_items(checklist_items, create_journal = false)
          checklist_items ||= []

          old_checklist = checklist.collect(&:info).join(', ')

          checklist.destroy_all
          checklist << checklist_items.uniq.collect do |cli|
            IssueChecklist.new(is_done: cli[:is_done], subject: cli[:subject])
          end

          new_checklist = checklist.collect(&:info).join(', ')

          if current_journal && create_journal && (new_checklist != old_checklist)
            current_journal.details << JournalDetail.new(
              property:  'attr',
              prop_key:  'checklist',
              old_value: old_checklist,
              value:     new_checklist)
          end
        end

      end

    end

  end
end


unless Issue.included_modules.include?(RedmineIssueChecklist::Patches::IssuePatch)
  Issue.send(:include, RedmineIssueChecklist::Patches::IssuePatch)
end
