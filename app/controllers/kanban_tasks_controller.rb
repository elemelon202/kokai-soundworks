class KanbanTasksController < ApplicationController
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized
  before_action :set_band
  before_action :authorize_band_member
  before_action :set_task, only: [:update, :destroy]


  def index
    @tasks = @band.kanban_tasks.ordered.includes(:assigned_to, :created_by)
  end

  def create
    @task = @band.kanban_tasks.new(task_params)
    @task.created_by = current_user

    if @task.save
      redirect_to band_kanban_tasks_path(@band), notice: "Task created."
    else
      redirect_to band_kanban_tasks_path(@band, alert: @task.errors.full_messages.join(", "))
    end
  end

  def update
    if @task.update(task_params)
      respond_to do |format|
        format.html { redirect_to band_kanban_tasks_path(@band) }
        format.turbo_stream { redirect_to band_kanban_tasks_path(@band) }
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.html { redirect_to band_kanban_tasks_path(@band), alert: @task.errors.full_messages.join(", ") }
        format.turbo_stream { redirect_to band_kanban_tasks_path(@band), alert: @task.errors.full_messages.join(", ") }
        format.json { render json: { success: false, errors: @task.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @task.destroy
    redirect_to band_kanban_tasks_path(@band), notice: "Task deleted."
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_task
    @task = @band.kanban_tasks.find(params[:id])
  end

  def authorize_band_member
    unless current_user&.musician && @band.musicians.include?(current_user.musician)
      redirect_to band_path(@band), alert: "You must be a band member."
    end
  end

  def task_params
    params.require(:kanban_task).permit(:name, :description, :status, :task_type, :deadline, :assigned_to_id, :position)
  end
end
