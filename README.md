<p align="center">
 <img src="app/assets/images/icon.svg" width="80" height="80" alt="Servicio Sacerdotal Nocturno">  
</p>

# Servicio Sacerdotal Nocturno

Sistema de gestión para la asignación y seguimiento de guardias y turnos nocturnos del servicio sacerdotal, asegurando una cobertura continua y organizada.

## Qué es el SSN

El **Servicio Sacerdotal Nocturno (SSN)**, también llamado Servicio Sacerdotal de Urgencia (SSU) en algunas diócesis, es una obra de misericordia de la Iglesia católica en la Argentina. Es una familia de sacerdotes y laicos que, noche a noche y en forma gratuita, acompaña a los enfermos en una hora de urgencia espiritual, especialmente cuando se pide la Unción de los Enfermos y, si corresponde, el Viático.

Cada noche, un sacerdote, un vocal y un grupo de guardianes se turnan para responder al llamado de una familia, un hospital o un centro de salud, a cualquier hora y sin costo.

La obra nació en Córdoba el 26 de octubre de 1952, cuando el Dr. Armando César Sánchez no encontró un sacerdote para su padre gravemente enfermo y advirtió que había farmacias y hospitales de guardia, pero ningún sacerdote disponible de noche. Hoy cada Servicio depende de su autoridad diocesana, y desde 1982 todos están unidos en la Federación Argentina del Servicio Sacerdotal de Urgencia y Nocturno (FSSUN), reconocida por la Conferencia Episcopal Argentina.

## Para qué sirve esta aplicación

Organiza el trabajo de cada Servicio: las guardias de cada noche con su sacerdote, vocal y guardianes; el registro de cada servicio (enfermo, quien solicita, centro de salud, sacramentos) y la planilla en PDF al cerrar la guardia. También tiene un sitio público con las sedes del país, su contacto y la historia de la obra, para que cualquiera pueda encontrar cómo pedir un sacerdote de urgencia.

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

## Import sample data
```
bundle exec rails runner db/seeds/services.rb
```
Defaults to today's day of month; pass `DAY=<n>` to target a different guard, e.g. `DAY=15 bundle exec rails runner db/seeds/services.rb`.

### DNS Domain
https://ap.www.namecheap.com/