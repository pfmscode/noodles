class LibraryController < ApplicationController
  include ApplicationHelper
  include LibraryHelper

  before_filter :please_sign_in
  before_action :set_page, only: [:show, :update, :destroy, :archive, :unarchive]
  before_action :not_the_owner, only: [:show, :update, :destroy, :archive, :unarchive]

  def index
    @pages = current_user.pages.where(["archived_at IS#{' NOT' if params[:archive]} NULL"])
  end

  def show
  end

  def new
    @page = Page.new do |page|
      page.user = current_user
      page.color = 'white'
    end
    @page.generate_shared_id!
    @page.save!(validate: false)
    redirect_to page_path(@page)
  end

  def create
    @page = Page.new(page_params)

    respond_to do |format|
      if @page.save
        format.html { redirect_to @page }
        format.json { render json: @page, status: :created, location: @page }
      else
        format.html { render :new }
        format.json { render json: @page.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @page.update(page_params)
        format.html { redirect_to @page, notice: 'Changes saved.' }
        format.json { render :show, status: :ok, location: @page }
      else
        format.html { render :show }
        format.json { render json: @page.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @page.destroy
    respond_to do |format|
      format.html { redirect_to pages_url, notice: 'We\'ve tossed out that page. 🔥' }
      format.json { head :no_content }
    end
  end

  def archive
    @page.archived_at = Time.now
    @page.save
    render :archived
  end

  def unarchive
    @page.archived_at = nil
    @page.save
    render nothing: true
  end

  private

  def set_page
    @page = Page.find(params[:id] || params[:page_id])
    raise_not_found
  end

  def page_params
    params.require(:page).permit(:name, :content, :content_raw, :shared_id, :user_id, :color)
  end

  def raise_not_found
    raise ActiveRecord::RecordNotFound if @page.nil?
  end

  def not_the_owner
    if not_my_page?
      flash[:red] = 'That\'s not yours.'
      redirect_to root_url
    end
  end
end