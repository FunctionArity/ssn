day = ENV["DAY"].to_i

if day.zero?
  puts "Usage: DAY=<day_number> bundle exec rails runner db/seeds/services.rb"
  exit 1
end

guard_setup = GuardSetup.find_by(day_number: day)

unless guard_setup
  puts "No guard setup found for day #{day}. Available days: #{GuardSetup.order(:day_number).pluck(:day_number).join(', ')}"
  exit 1
end

guard = Guard.where(day_number: day).order(due_date: :desc).first

if guard
  puts "Found existing guard for day #{day} (#{guard.due_date})."
else
  svc = CreateGuardFromSetupService.new(guard_setup.id)
  guard = svc.call
  guard.priest ||= User.priests.first
  guard.save!
  puts "Created new guard for day #{day} (#{guard.due_date})."
end

created_by = User.find_by(email: "pablorodriguez.ar@gmail.com") || User.first

unless created_by
  puts "No user found to assign as created_by."
  exit 1
end

health_facilities = HealthFacility.all.to_a

NAMES = [
  "María Luisa Fernández", "Roberto Carlos Gómez", "Ana Beatriz Molina",
  "Jorge Eduardo Pérez", "Susana Beatriz Álvarez", "Carlos Alberto Rodríguez",
  "Graciela Noemí Torres", "Héctor Manuel Díaz", "Norma Beatriz Sánchez",
  "Oscar Rubén Martínez", "Elena Isabel Castro", "Miguel Ángel López",
  "Rosa María Gutiérrez", "Alberto Horacio Romero", "Estela Carmen Flores"
].freeze

CALLER_NAMES = [
  "Juan Pablo Fernández", "Claudia Gómez", "Marcelo Molina",
  "Verónica Pérez", "Diego Álvarez", "Silvia Rodríguez",
  "Fabián Torres", "Gabriela Díaz", "Lucía Sánchez",
  "Pablo Martínez", "Daniela Castro", "Sergio López"
].freeze

RELATIONSHIPS = %w[hijo/a hija nieto/a esposo/a hermano/a sobrina/o vecino/a].freeze

PATHOLOGIES = [
  "ACV isquémico", "Insuficiencia cardíaca", "EPOC", "Diabetes tipo 2",
  "Cáncer de colon", "Parkinson", "Alzheimer", "Fractura de cadera",
  "Neumonía", "Arritmia cardíaca", "Insuficiencia renal crónica"
].freeze

HEALTH_STATUSES = [
  "Grave", "Estable", "Muy grave", "Delicado", "Terminal", "Crítico"
].freeze

SACRAMENTS = [
  "Unción de los Enfermos", "Viático", "Unción y Viático",
  "Confesión", "Confesión y Unción"
].freeze

PLACES = %w[Sala Guardia UCI UTI Domicilio].freeze

GODOY_CRUZ_ADDRESSES = [
  "Av. San Martín 2350, Godoy Cruz, Mendoza",
  "Calle Belgrano 780, Godoy Cruz, Mendoza",
  "Pellegrini 1120, Godoy Cruz, Mendoza",
  "Av. Costanera 460, Godoy Cruz, Mendoza",
  "Mitre 945, Godoy Cruz, Mendoza",
  "Paso de los Andes 1680, Godoy Cruz, Mendoza",
  "Rondeau 530, Godoy Cruz, Mendoza",
  "Calle Rivadavia 2100, Godoy Cruz, Mendoza",
].freeze

COMMENTS = [
  "La familia solicita urgencia en la visita.",
  "Paciente consciente, solicita los sacramentos con devoción.",
  "Se coordina con enfermería para el ingreso.",
  "Familiar acompaña durante toda la visita.",
  nil, nil
].freeze

services_data = [
  { status: :pending,   has_facility: true  },
  { status: :pending,   has_facility: false },
  { status: :completed, has_facility: true  },
  { status: :pending,   has_facility: true  },
  { status: :completed, has_facility: false },
  { status: :pending,   has_facility: false },
  { status: :completed, has_facility: true  },
  { status: :pending,   has_facility: false },
]

created = 0

services_data.each_with_index do |data, i|
  facility = data[:has_facility] ? health_facilities.sample : nil

  Service.create!(
    guard:                 guard,
    created_by:            created_by,
    full_name:             NAMES[i % NAMES.size],
    age:                   rand(55..95),
    due_date:              guard.due_date,
    status:                data[:status],
    caller_full_name:      CALLER_NAMES[i % CALLER_NAMES.size],
    caller_phone:          "0261 4#{rand(10..99)}-#{rand(1000..9999)}",
    caller_relationship:   RELATIONSHIPS.sample,
    pathology:             PATHOLOGIES.sample,
    health_status:         HEALTH_STATUSES.sample,
    sacraments:            SACRAMENTS.sample,
    health_facility:       facility,
    health_facility_place: facility ? PLACES.sample : nil,
    address:               facility ? nil : GODOY_CRUZ_ADDRESSES.sample,
    comments:              COMMENTS.sample
  )

  created += 1
end

puts "Created #{created} services for guard day #{guard.day_number} (#{guard.due_date})."
