# The guard's PDF: /guard_info/:id shows the guard header with the PDF embedded,
# /guard_info/:id.pdf serves the file itself, /guard_info/:id/new previews it, and POST /guard_info/:id confirms it.
class GuardInfoController < ApplicationController
  before_action :set_guard

  def show
    respond_to do |format|
      format.html do
        @services_count = @guard.services.count
        @pdf_url = "#{guard_info_path(@guard, format: :pdf)}##{GuardPdf::VIEWER_ANCHOR}"
      end
      format.pdf do
        # The stored PDF once the guard is confirmed, otherwise one generated on the fly.
        if @guard.pdf_file.attached?
          redirect_to rails_blob_url(@guard.pdf_file, disposition: "inline")
        else
          send_data GuardPdf.new(@guard).render,
            filename: "guardia_#{@guard.id}.pdf",
            type: "application/pdf",
            disposition: "inline"
        end
      end
    end
  end

  # Preview of the PDF before confirming: services numbered from first_nro (default: last NRO + 1).
  def new
    if params[:first_nro].present?
      @first_nro = params[:first_nro].to_i
    else
      last_nro = Service.where.not(nro: nil).maximum(:nro)
      @first_nro = last_nro ? last_nro + 1 : 1
    end
    @services = @guard.services.completed.includes(:health_facility).order(due_date: :asc)
    @services.each_with_index { |s, i| s.nro = @first_nro + i }
  end

  # Confirms the preview: saves the services' NRO, stores the PDF and closes the guard.
  def create
    first_nro = params[:first_nro].to_i
    @guard.services.completed.order(due_date: :asc).each_with_index do |service, idx|
      service.update_column(:nro, first_nro + idx)
    end
    pdf_data = GuardPdf.new(@guard.reload).render
    # Stored in S3 as pdf_file/<guard id>/<random token>, like avatars.
    @guard.pdf_file.attach(
      io: StringIO.new(pdf_data),
      filename: "guardia_#{@guard.id}.pdf",
      content_type: "application/pdf",
      key: "#{@guard.id}/#{ActiveStorage::Blob.generate_unique_secure_token}"
    )
    @guard.closed!
    redirect_to guard_info_path(@guard)
  end

  private

  def set_guard
    @guard = Guard.find(params.expect(:id))
  end
end
