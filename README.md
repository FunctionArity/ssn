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

## Tecnologías

### Backend

- **Ruby 4.0.1** y **Rails 8.1**
- **PostgreSQL 17** — Base de datos
- **Puma** y **Thruster** — Servidor de aplicación y proxy HTTP
- **Solid Queue**, **Solid Cache** y **Solid Cable** — Trabajos en segundo plano, caché y WebSockets sobre la base de datos
- **Devise** y **devise_invitable** — Autenticación e invitación de usuarios
- **Pundit** — Autorización por roles
- **Pretender** — Impersonación de usuarios
- **PaperTrail** — Historial de cambios
- **FriendlyId** y **acts_as_list** — URLs legibles y orden de registros
- **Prawn**, **prawn-table** y **prawn-svg** — Generación de PDF
- **Active Storage**, **image_processing** y **ruby-vips** — Archivos y procesamiento de imágenes

### Frontend

- **Hotwire** (**Turbo** y **Stimulus**) — Interactividad y actualizaciones en vivo
- **Tailwind CSS 4** — Estilos
- **esbuild** y **Propshaft** — Empaquetado de JavaScript y assets
- **Lexxy** — Editor de texto enriquecido
- **Cropper.js** — Recorte de avatares
- **Phosphor Icons** — Íconos
- **Google Maps JavaScript API** — Mapas y geocodificación de direcciones

### Infraestructura y servicios

- **Kamal** y **Docker** — Despliegue en contenedores, con imágenes en Docker Hub
- **Amazon S3** — Archivos (avatares y PDF, con subida directa desde el navegador) y copias de seguridad de la base de datos
- **Terraform** — Usuario IAM y buckets de S3 (`infra/terraform`)
- **Cloudflare** — DNS y redirecciones
- **Resend** — Envío de correos (SMTP)
- **Honeybadger** — Monitoreo de errores

### Calidad y tests

- **Minitest**, **Capybara** y **Selenium** — Tests unitarios, de integración y de sistema
- **SimpleCov** y **Faker** — Cobertura y datos de prueba
- **RuboCop** (rubocop-rails-omakase) — Estilo de código
- **Brakeman** y **bundler-audit** — Análisis de seguridad
- **GitHub Actions** y **Dependabot** — Integración continua y actualización de dependencias
