class Circle::TasksController < ApplicationController
  layout "internal"
  before_action :ensure_logged_in

  include HasCircle

  def index
    authorize! :read, current_circle

    tasks = current_circle.tasks.order('due_date asc')

    open_tasks   = tasks.not_completed
    closed_tasks = tasks.completed

    @tasks = OpenStruct.new(open: open_tasks.limit(10), closed: closed_tasks.limit(10))
  end

  def my
    authorize! :read, current_circle

    tasks = current_user.tasks.for_circle(current_circle).order('due_date asc')

    open_tasks   = tasks.not_completed
    closed_tasks = tasks.completed

    @tasks = OpenStruct.new(open: open_tasks.limit(10), closed: closed_tasks.limit(10))
  end



  def show
    authorize! :read, current_task
  end


  def new
    authorize! :create_task, current_circle
    @task = @circle.working_groups.first.tasks.build
  end


  def edit
    authorize! :update, current_task
  end


  def create
    working_group = current_circle.working_groups.find(params[:task][:working_group_id])
    authorize! :create_task, working_group

    outcome = Task::Create.run({user: current_user, circle: current_circle, working_group: working_group}, task_params)

    if outcome.success?
      redirect_to circle_task_path(current_circle, outcome.result), notice: t('flash.created', name: Task.model_name.human)

    else
      @task = Task.new(task_params)
      errors.add outcome.errors

      render :new
    end
  end


  def update
    working_group = current_circle.working_groups.find(params[:task][:working_group_id])

    authorize! :update, current_task
    authorize! :create_task, working_group

    outcome = Task::Update.run({
      user:          current_user,
      circle:        current_circle,
      working_group: working_group,
      task:          current_task
    }, task_params)

    if outcome.success?
      redirect_to circle_task_path(current_circle, outcome.result), notice: t('flash.updated', name: Task.model_name.human)

    else
      errors.add outcome.errors
      render :edit
    end
  end


  def destroy
    authorize! :destroy, current_task

    outcome = Task::Destroy.run(task: current_task, user: current_user)

    redirect_to circle_tasks_path(@circle), notice: t('flash.destroyed', name: Task.model_name.human)
  end


  def volunteer
    authorize! :volunteer, current_task

    outcome = Task::Volunteer.run(user: current_user, task: current_task)

    if outcome.success?
      redirect_to circle_task_path(current_circle, current_task), notice: t('tasks.flash.volunteered', name: current_task.name)
    else
      redirect_to circle_task_path(current_circle, current_task), alert: t('tasks.flash.volunteer_failed', name: current_task.name)
    end
  end


  def complete
    authorize! :complete, current_task

    outcome = Task::Complete.run(user: current_user, task: current_task)

    if outcome.success?
      redirect_to circle_task_path(current_circle, current_task), notice: t('tasks.flash.completed', name: current_task.name)
    else
      redirect_to circle_task_path(current_circle, current_task), alert: t('tasks.flash.complete_failed', name: current_task.name)
    end
  end


  helper_method def errors
    @errors ||= Errors.new
  end

  helper_method def current_task
    @task ||= Task.find(params[:id] || params[:task_id])
  end


  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def task_params
      params[:task].permit(:name, :description, :working_group_id, :due_date)
    end
end