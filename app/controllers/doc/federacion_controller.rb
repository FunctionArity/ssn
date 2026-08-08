class Doc::FederacionController < ApplicationController
  skip_before_action :authenticate_user!
  layout "doc"

  SCHEDULE = [
    {
      label: "Viernes 28",
      items: [
        [ "15:00 hs", "Recepción, Acreditación y Alojamiento" ],
        [ "17:00 hs", "Recepción Solemne del Cristo Peregrino y de Ntra. Sra. de Lourdes" ],
        [ "19:00 hs", "Misa Apertura" ],
        [ "20:00 hs", "Bienvenida - Presentaciones. Apertura de la 44ª Asamblea Nacional" ],
        [ "21:30 hs", "Cena" ],
        [ "23:00 hs", "Descanso" ]
      ]
    },
    {
      label: "Sábado 29",
      items: [
        [ "8:00 hs", "Oración de la mañana" ],
        [ "8:30 hs", "Desayuno" ],
        [ "9:30 hs", "Reanudación asamblea - Formación de comisiones de trabajo" ],
        [ "12:30 hs", "Almuerzo" ],
        [ "13:30 hs", "Descanso" ],
        [ "15:00 hs", "Reanudación asamblea (comisiones de trabajo)" ],
        [ "19:30 hs", "Descanso - Break" ],
        [ "20:00 hs", "Rezo del Vía Lucis" ],
        [ "21:30 hs", "Cena y entrega de recordatorios" ],
        [ "24:00 hs", "Descanso" ]
      ]
    },
    {
      label: "Domingo 30",
      items: [
        [ "9:00 hs", "Oración de la mañana" ],
        [ "9:30 hs", "Desayuno" ],
        [ "10:30 hs", "Plenario y conclusiones de la 44ª Asamblea Nacional" ],
        [ "12:30 hs", "Misa" ],
        [ "13:30 hs", "Almuerzo" ],
        [ "15:30 hs", "Despedida" ]
      ]
    }
  ].freeze

  def index
    @schedule = SCHEDULE
  end
end
