class TasksController < ApplicationController
  include Validation

  before_action :need_admin

  def show
    @jid = params[:jid]
    @text = File.read(params[:file_path]).split("\n").join('<br>')
  end

  def new
    @task = Task.new
  end

  def create
    task = Task.new(task_params)
    jid = InvokeTaskWorker.perform_async(task.name, task.user_ids)
    redirect_to task_path(jid: jid, file_path: task.file_path)
  end

  private

  def task_params
    params.fetch(:task, {}).permit(:name, :user_ids)
  end
end
