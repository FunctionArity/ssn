class Doc::FederacionController < ApplicationController
  skip_before_action :authenticate_user!
  layout "doc"

  SECTIONS = [
    [ "que-es", "¿Qué es el Servicio?" ],
    [ "historia", "Historia y fundación" ],
    [ "estructura", "Finalidad y estructura" ],
    [ "servicios", "Los Servicios" ],
    [ "expansion", "Expansión" ],
    [ "testimonios", "Testimonios" ],
    [ "iglesia", "Reconocida por la Iglesia" ],
    [ "vida-espiritual", "Vida espiritual" ],
    [ "contacto", "Contacto" ],
    [ "carta", "Carta del Papa Francisco" ]
  ].freeze

  def index
    @sections = SECTIONS
    @headquarters = Headquarter.order(:city)
  end
end
