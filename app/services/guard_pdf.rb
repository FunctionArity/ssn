require "prawn"
require "prawn-svg"

class GuardPdf
  PAGE_MARGIN     = [ 30, 35, 30, 35 ].freeze
  SERVICES_PER_PAGE = 3
  LOGO_SIZE       = 40
  LABEL_SIZE      = 10
  VALUE_SIZE      = 11
  LINE_HEIGHT     = 24
  SECTION_GAP     = 40

  def initialize(guard)
    @guard = guard
  end

  def render
    pdf = Prawn::Document.new(
      page_size:   "A4",
      page_layout: :portrait,
      margin:      PAGE_MARGIN
    )
    generate(pdf)
    pdf.render
  end

  private

  def generate(pdf)
    services = @guard.services.includes(:health_facility).order(due_date: :asc)
    groups   = services.each_slice(SERVICES_PER_PAGE).to_a

    groups.each_with_index do |group, page_index|
      pdf.start_new_page if page_index > 0
      build_page(pdf, group, page_index + 1, groups.size)
    end

    if groups.empty?
      build_page_header(pdf, pdf.bounds.width, pdf.bounds.top)
      pdf.move_down 30
      pdf.text "No hay servicios registrados para esta guardia.",
               size: 10, align: :center, color: "888888"
    end
  end

  def build_page(pdf, services, page_num, total_pages)
    w   = pdf.bounds.width
    top = pdf.bounds.top

    header_bottom = build_page_header(pdf, w, top)

    # Separator
    pdf.stroke_color "000000"
    pdf.line_width 0.75
    pdf.stroke { pdf.horizontal_line 0, w, at: header_bottom }

    y = header_bottom - SECTION_GAP

    services.each_with_index do |service, idx|
      y = build_service_block(pdf, service, w, y)
      if idx < services.size - 1
        y -= SECTION_GAP / 2
        pdf.stroke_color "000000"
        pdf.line_width 0.75
        pdf.stroke { pdf.horizontal_line 0, w, at: y }
        y -= SECTION_GAP / 2
      end
    end

    # Page footer
    pdf.bounding_box([ 0, 20 ], width: w, height: 12) do
      pdf.text "Pág. #{page_num} / #{total_pages}",
               size: 8, align: :right, color: "888888"
    end
  end

  def build_page_header(pdf, w, top)
    svg_path = Rails.root.join("app/assets/images/icon.svg")
    if File.exist?(svg_path)
      pdf.svg(File.read(svg_path), at: [ 0, top ], width: LOGO_SIZE, height: LOGO_SIZE)
    end

    cx  = LOGO_SIZE + 8
    cw  = w - cx - 130
    pdf.bounding_box([ cx, top ], width: cw, height: LOGO_SIZE) do
      pdf.move_down 4
      pdf.text "SERVICIO SACERDOTAL NOCTURNO", size: 11, style: :bold, align: :center
      pdf.move_down 4
      pdf.text "Guardia ##{@guard.number}", size: 9, align: :center, color: "555555"
    end

    pdf.bounding_box([ w - 130, top ], width: 130, height: LOGO_SIZE) do
      pdf.move_down 6
      pdf.text "FECHA DE GUARDIA", size: 8, style: :bold, align: :center
      pdf.move_down 6
      date_str = I18n.l(@guard.due_date, format: :default)
      pdf.text date_str, size: 10, align: :center
    end

    top - LOGO_SIZE - 6
  end

  def build_service_block(pdf, service, w, start_y)
    y = start_y

    # Service title row
    service_label = service.nro.present? ? "NRO #{service.nro}" : "SERVICIO ##{service.id}"
    pdf.text_box service_label, at: [ 0, y ], width: w, height: 14,
                 size: 7, style: :bold, color: "6666aa", overflow: :truncate
    y -= 14

    # Row 1: Nombre y Apellido + Edad
    edad_w   = 60
    nombre_w = w - edad_w - 10
    field(pdf, 0,             y, nombre_w, "Nombre y Apellido:", service.full_name)
    field(pdf, nombre_w + 10, y, edad_w,   "Edad:",              service.age)
    y -= LINE_HEIGHT

    # Row 2: Hospital + Piso
    piso_w = 210
    hosp_w = w - piso_w - 10
    field(pdf, 0,            y, hosp_w, "Hospital:", service.health_facility&.name)
    field(pdf, hosp_w + 10,  y, piso_w, "Piso / Hab. / Cama:", service.health_facility_place)
    y -= LINE_HEIGHT

    # Row 3: Domicilio
    field(pdf, 0, y, w, "Domicilio:", service.address)
    y -= LINE_HEIGHT

    # Row 4: Patologia + Estado
    half = (w - 10) / 2
    field(pdf, 0,         y, half, "Patologia:", service.pathology)
    field(pdf, half + 10, y, half, "Estado:",    service.health_status)
    y -= LINE_HEIGHT

    # Row 5: Sacramento
    field(pdf, 0, y, w, "Sacramento:", service.sacraments)
    y -= LINE_HEIGHT

    # Row 6: Solicito + Tel + Parentesco
    tel_w        = 115
    parentesco_w = 105
    solicito_w   = w - tel_w - parentesco_w - 20
    field(pdf, 0,                                   y, solicito_w,   "Solicito:",   service.caller_full_name)
    field(pdf, solicito_w + 10,                     y, tel_w,        "Tel:",        service.caller_phone)
    field(pdf, solicito_w + 10 + tel_w + 10,        y, parentesco_w, "Parentesco:", service.caller_relationship)
    y -= LINE_HEIGHT

    y
  end

  def field(pdf, x, y, width, label, value)
    value_str = value.present? ? value.to_s : ""

    parts = [ { text: label, styles: [ :bold ], size: LABEL_SIZE } ]
    parts << { text: " #{value_str}", size: VALUE_SIZE } unless value_str.empty?
    pdf.formatted_text_box(parts, at: [ x, y ], width: width, height: 14, overflow: :truncate)

    pdf.save_graphics_state do
      pdf.stroke_color "aaaaaa"
      pdf.dash(1, space: 2)
      pdf.stroke { pdf.horizontal_line x, x + width, at: y - 12 }
    end
  end
end
