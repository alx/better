# Redmine - project management software
# Copyright (C) 2006-2011  See readme for details and license
#

class WorkflowsController < ApplicationController
  layout 'admin'

  before_filter :require_admin
  ssl_required :all

  def index # spec_me cover_me heckle_me
    @workflow_counts = Workflow.count_by_tracker_and_role
  end

  def edit # spec_me cover_me heckle_me
    @role = Role.find_by_id(params[:role_id])
    @tracker = Tracker.find_by_id(params[:tracker_id])

    if request.post?
      Workflow.destroy_all( ["role_id=? and tracker_id=?", @role.id, @tracker.id])
      (params[:issue_status] || []).each { |old, news|
        news.each { |new|
          @role.workflows.build(:tracker_id => @tracker.id, :old_status_id => old, :new_status_id => new)
        }
      }
      if @role.save
        flash.now[:success] = l(:notice_successful_update)
        redirect_to :action => 'edit', :role_id => @role, :tracker_id => @tracker
      end
    end
    @roles = Role.find(:all, :order => 'builtin, position')
    @trackers = Tracker.find(:all, :order => 'position')

    @used_statuses_only = (params[:used_statuses_only] == '0' ? false : true)
    if @tracker && @used_statuses_only && @tracker.issue_statuses.any?
      @statuses = @tracker.issue_statuses
    end
    @statuses ||= IssueStatus.find(:all, :order => 'position')
  end

  def copy # spec_me cover_me heckle_me
    @trackers = Tracker.find(:all, :order => 'position')
    @roles = Role.find(:all, :order => 'builtin, position')

    if params[:source_tracker_id].blank? || params[:source_tracker_id] == 'any'
      @source_tracker = nil
    else
      @source_tracker = Tracker.find_by_id(params[:source_tracker_id].to_i)
    end
    if params[:source_role_id].blank? || params[:source_role_id] == 'any'
      @source_role = nil
    else
      @source_role = Role.find_by_id(params[:source_role_id].to_i)
    end

    @target_trackers = params[:target_tracker_ids].blank? ? nil : Tracker.find_all_by_id(params[:target_tracker_ids])
    @target_roles = params[:target_role_ids].blank? ? nil : Role.find_all_by_id(params[:target_role_ids])

    if request.post?
      if params[:source_tracker_id].blank? || params[:source_role_id].blank? || (@source_tracker.nil? && @source_role.nil?)
        flash.now[:error] = l(:error_workflow_copy_source)
      elsif @target_trackers.nil? || @target_roles.nil?
        flash.now[:error] = l(:error_workflow_copy_target)
      else
        Workflow.copy(@source_tracker, @source_role, @target_trackers, @target_roles)
        flash.now[:success] = l(:notice_successful_update)
        redirect_to :action => 'copy', :source_tracker_id => @source_tracker, :source_role_id => @source_role
      end
    end
  end
end
