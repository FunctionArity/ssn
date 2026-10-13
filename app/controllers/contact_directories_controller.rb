class ContactDirectoriesController < ApplicationController
  before_action :set_headquarter
  before_action :set_contact_directory, only: %i[ show edit update destroy ]

  def show
    authorize @contact_directory
  end

  def new
    @contact_directory = @headquarter.contact_directories.new
    @contact_directory.contact_groups.build.contacts.build
    authorize @contact_directory
  end

  def edit
    authorize @contact_directory
  end

  def create
    @contact_directory = @headquarter.contact_directories.new(contact_directory_params)
    authorize @contact_directory

    if @contact_directory.save
      redirect_to [ @headquarter, @contact_directory ], notice: t("contact_directories.notices.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @contact_directory

    if @contact_directory.update(contact_directory_params)
      redirect_to [ @headquarter, @contact_directory ], notice: t("contact_directories.notices.updated"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @contact_directory
    @contact_directory.destroy!
    redirect_to @headquarter, notice: t("contact_directories.notices.destroyed"), status: :see_other
  end

  private

  def set_headquarter
    @headquarter = Headquarter.friendly.find(params.expect(:headquarter_id))
  end

  def set_contact_directory
    @contact_directory = @headquarter.contact_directories.includes(contact_groups: :contacts).find(params.expect(:id))
  end

  def contact_directory_params
    params.expect(contact_directory: [
      :title, :description, :group_label, :updated_on, :visibility,
      contact_groups_attributes: [ [
        :id, :name, :notes, :_destroy,
        contacts_attributes: [ [ :id, :name, :detail, :phone, :email, :_destroy ] ]
      ] ]
    ])
  end
end
