module RedmineNewIssueView
  module Patches
    module IssuesHelperPatch
      def self.included(base)
        base.class_eval do
          unloadable

          # This overrides the render_descendants_tree method from IssuesHelper
          # It ads the thead section and changes the listed columns
          def render_descendants_tree(issue)
            s = '<table class="list issues odd-even">'
            issue_list(issue.descendants.visible.preload(:status, :priority, :tracker, :assigned_to).sort_by(&:lft)) do |child, level|
              css = "issue issue-#{child.id} hascontextmenu #{child.css_classes}"
              css << " idnt idnt-#{level}" if level > 0
              s << content_tag('tr',
                     content_tag('td', check_box_tag("ids[]", child.id, false, :id => nil), :class => 'checkbox') +
                     content_tag('td', link_to_issue(child, :project => (issue.project_id != child.project_id)), :class => 'subject', :style => 'width: 50%') +
                     content_tag('td', h(child.status), :class => 'status') +
                     content_tag('td', link_to_user(child.assigned_to), :class => 'assigned_to') +
                     # These columns were added
                     content_tag('td', child.disabled_core_fields.include?('estimated_hours') ? "" : child.total_estimated_hours, class: "estimated-hours") +
                     content_tag('td', (User.current.allowed_to?(:view_time_entries, @project) && child.total_spent_hours > 0) ? child.total_spent_hours : '', class: "spent-time"),
                     # This column was removed
                    #  content_tag('td', child.disabled_core_fields.include?('done_ratio') ? '' : progress_bar(child.done_ratio), :class=> 'done_ratio'),
                     :class => css)
            end
            s << '</table>'
            s.html_safe
          end

        end
      end
    end
  end
end

patch = RedmineNewIssueView::Patches::IssuesHelperPatch
[IssuesHelper, IssueRelationsHelper].each do |base|
  base.send :include, patch unless base.included_modules.include? patch
end
