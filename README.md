<p align="center">
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="80" height="80">
    <defs>
      <radialGradient id="enamelGrad" cx="42%" cy="38%" r="58%">
        <stop offset="0%"   stop-color="#f5edb0"/>
        <stop offset="55%"  stop-color="#e8d97a"/>
        <stop offset="85%"  stop-color="#d4c05a"/>
        <stop offset="100%" stop-color="#b8a040"/>
      </radialGradient>
      <radialGradient id="rimGrad" cx="40%" cy="35%" r="60%">
        <stop offset="0%"   stop-color="#e8c96a"/>
        <stop offset="40%"  stop-color="#c8a030"/>
        <stop offset="75%"  stop-color="#a07820"/>
        <stop offset="100%" stop-color="#7a5810"/>
      </radialGradient>
      <filter id="shadow" x="-10%" y="-10%" width="120%" height="120%">
        <feDropShadow dx="2" dy="3" stdDeviation="4" flood-color="#00000055"/>
      </filter>
    </defs>
    <circle cx="100" cy="100" r="96" fill="url(#rimGrad)" filter="url(#shadow)"/>
    <circle cx="100" cy="100" r="92" fill="none" stroke="#f0d060" stroke-width="1.5" opacity="0.5"/>
    <circle cx="100" cy="100" r="88" fill="url(#enamelGrad)"/>
    <ellipse cx="82" cy="72" rx="28" ry="18" fill="white" opacity="0.18"/>
    <g fill="#2a2218" opacity="0.88">
      <rect x="91" y="56" width="18" height="52" rx="3" ry="3"/>
      <rect x="78" y="70" width="44" height="18" rx="3" ry="3"/>
    </g>
    <circle cx="100" cy="100" r="88" fill="none" stroke="#8a6a10" stroke-width="3" opacity="0.25"/>
  </svg>
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
