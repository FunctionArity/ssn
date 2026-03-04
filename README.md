<p align="center">
 <img src="app/assets/images/icon.svg" width="80" height="80" alt="Servicio Sacerdotal Nocturno">  
</p>

# Servicio Sacerdotal Nocturno

Sistema de gestión para la asignación y seguimiento de guardias y turnos nocturnos del servicio sacerdotal, asegurando una cobertura continua y organizada.

## Módulos

- **Guardias** — Organización y seguimiento de turnos nocturnos
- **Sacerdotes** — Coordinación de disponibilidad y asignaciones
- **Servicios** — Gestión de servicios realizados

## Requisitos

- Ruby 4.0.1
- Rails 8.1
- PostgreSQL

## Configuración

```bash
bundle install
rails db:create db:migrate db:seed
```

## Servidor de desarrollo

```bash
bin/dev
```

## Tests

```bash
bundle exec rails test
bundle exec rails test:system
```
