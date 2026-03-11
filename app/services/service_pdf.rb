require "prawn"
require "prawn-svg"

class ServicePdf
  MARGIN      = [ 18, 25, 18, 25 ].freeze
  LABEL_SIZE  = 10
  VALUE_SIZE  = 11
  LINE_HEIGHT = 26
  LOGO_SIZE   = 45
  HEADER_H    = LOGO_SIZE + 6   # header block height

  def initialize(service)
    @service = service
  end

  def render
    pdf = Prawn::Document.new(
      page_size:   "A4",
      page_layout: :portrait,
      margin:      MARGIN
    )
    generate(pdf)
    pdf.render
  end

  private

  def generate(pdf)
    w   = pdf.bounds.width
    top = pdf.bounds.top

    build_header(pdf, w, top)

    sep_y = top - HEADER_H
    pdf.stroke_color "000000"
    pdf.line_width 0.75
    pdf.stroke { pdf.horizontal_line 0, w, at: sep_y }

    build_fields(pdf, w, sep_y - 16)
  end

  def build_header(pdf, w, top)
    svg_path = Rails.root.join("app/assets/images/icon.svg")
    if File.exist?(svg_path)
      pdf.svg(File.read(svg_path), at: [ 0, top ], width: LOGO_SIZE, height: LOGO_SIZE)
    end

    # Center: SERVICIO SACERDOTAL NOCTURNO + service number
    cx = LOGO_SIZE + 8
    cw = w - cx - 145
    pdf.bounding_box([ cx, top ], width: cw, height: LOGO_SIZE) do
      pdf.move_down 4
      pdf.text "SERVICIO SACERDOTAL NOCTURNO", size: 11, style: :bold, align: :center
      pdf.move_down 4
      pdf.text "Servicio ##{@service.id}", size: 9, align: :center, color: "555555"
    end

    # Right: FECHA DE GUARDIA + date value
    rx = w - 140
    pdf.bounding_box([ rx, top ], width: 140, height: LOGO_SIZE) do
      pdf.move_down 8
      pdf.text "FECHA DE GUARDIA", size: 9, style: :bold, align: :center
      pdf.move_down 8
      guard_date = @service.guard&.due_date
      date_str   = guard_date ? I18n.l(guard_date, format: :default) : "....../....../......"
      pdf.text date_str, size: 10, align: :center
    end
  end

  def build_fields(pdf, w, start_y)
    y = start_y

    # Row 1: Nombre y Apellido + Edad
    edad_w   = 70
    nombre_w = w - edad_w - 10
    field(pdf, 0,             y, nombre_w, "Nombre y Apellido:", @service.full_name)
    field(pdf, nombre_w + 10, y, edad_w,   "Edad:",              @service.age)

    y -= LINE_HEIGHT

    # Row 2: Hospital + Piso
    piso_w = 220
    hosp_w = w - piso_w - 10
    field(pdf, 0,          y, hosp_w, "Hospital:", @service.health_facility&.name)
    field(pdf, hosp_w + 10, y, piso_w, "Piso / Habitación / Cama / Lugar:",    @service.health_facility_place)

    y -= LINE_HEIGHT

    # Row 3: Domicilio
    field(pdf, 0, y, w, "Domicilio:", @service.address)

    y -= LINE_HEIGHT

    # Row 4: Patologia + Estado
    half = (w - 10) / 2
    field(pdf, 0,         y, half, "Patologia:", @service.pathology)
    field(pdf, half + 10, y, half, "Estado:",    @service.health_status)

    y -= LINE_HEIGHT

    # Row 5: Sacramento
    field(pdf, 0, y, w, "Sacramento:", @service.sacraments)

    y -= LINE_HEIGHT

    # Row 6: Solicito + Tel + Parentesco
    tel_w        = 125
    parentesco_w = 115
    solicito_w   = w - tel_w - parentesco_w - 20
    field(pdf, 0,                             y, solicito_w,   "Solicito:",    @service.caller_full_name)
    field(pdf, solicito_w + 10,               y, tel_w,        "Tel:",         @service.caller_phone)
    field(pdf, solicito_w + 10 + tel_w + 10, y, parentesco_w, "Parentesco:",  @service.caller_relationship)
  end

  def field(pdf, x, y, width, label, value)
    value_str = value.present? ? value.to_s : ""

    pdf.bounding_box([ x, y ], width: width, height: 16) do
      parts = [ { text: label, styles: [ :bold ], size: LABEL_SIZE } ]
      parts << { text: " #{value_str}", size: VALUE_SIZE } unless value_str.empty?
      pdf.formatted_text(parts)
    end

    pdf.save_graphics_state do
      pdf.stroke_color "aaaaaa"
      pdf.dash(1, space: 2)
      pdf.stroke { pdf.horizontal_line x, x + width, at: y - 14 }
    end
  end
end
