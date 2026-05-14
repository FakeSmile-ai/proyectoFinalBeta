# Estructura de carpetas para un proyecto Angular mediano (module-first)

proyecto Angular **mediano**, manteniendo un enfoque **module-first**, donde cada funcionalidad principal de la aplicación vive dentro de su propio módulo.

## Objetivos de esta estructura

- Organizar la aplicación por **features** o dominios.
- Mantener separada la lógica transversal de la lógica de negocio.
- Facilitar el **lazy loading**.
- Evitar una estructura global por tipo (`components/`, `services/`, `models/`) que escale mal.
- Mantener una arquitectura clara y mantenible.

## Estructura general

```txt
src/
└── app/
    ├── app.module.ts
    ├── app-routing.module.ts
    ├── app.component.ts
    │
    ├── core/
    │   ├── core.module.ts
    │   ├── guards/
    │   ├── interceptors/
    │   ├── services/
    │   ├── layout/
    │   └── types/
    │
    ├── shared/
    │   ├── shared.module.ts
    │   ├── components/
    │   ├── directives/
    │   ├── pipes/
    │   └── utils/
    │
    ├── shell/
    │   ├── shell.module.ts
    │   ├── shell-routing.module.ts
    │   ├── containers/
    │   │   └── main-layout/
    │   ├── components/
    │   │   ├── header/
    │   │   ├── sidebar/
    │   │   └── footer/
    │   └── models/
    │
    └── features/
        ├── auth/
        │   ├── auth.module.ts
        │   ├── auth-routing.module.ts
        │   ├── pages/
        │   │   ├── login/
        │   │   └── recovery/
        │   ├── components/
        │   ├── services/
        │   ├── models/
        │   └── store/
        │
        ├── users/
        │   ├── users.module.ts
        │   ├── users-routing.module.ts
        │   ├── pages/
        │   │   ├── users-list/
        │   │   └── user-detail/
        │   ├── components/
        │   ├── services/
        │   ├── models/
        │   └── store/
        │
        └── dashboard/
            ├── dashboard.module.ts
            ├── dashboard-routing.module.ts
            ├── pages/
            ├── components/
            ├── services/
            ├── models/
            └── store/
```

---

## Descripción de cada carpeta

### `app/`

Es el punto de entrada de la aplicación. Aquí viven el `AppModule`, el routing raíz y el componente principal.

### `core/`

Contiene piezas **globales y transversales** a toda la aplicación.

Ejemplos:

- `guards/`: guards de autenticación o autorización.
- `interceptors/`: interceptores HTTP.
- `services/`: servicios singleton globales.
- `layout/`: piezas base de layout si aplican a toda la app.
- `types/`: tipos globales o contratos compartidos a nivel aplicación.

> Regla práctica: si algo existe una sola vez y aplica a toda la aplicación, probablemente pertenece a `core/`.

### `shared/`

Contiene elementos **reutilizables** entre varias features.

Ejemplos:

- `components/`: botones, tablas, modales, cards reutilizables.
- `directives/`: directivas compartidas.
- `pipes/`: pipes reutilizables.
- `utils/`: helpers puros, adaptadores o funciones compartidas.

> Regla práctica: si algo se usa en varias features y no pertenece al dominio de negocio, va en `shared/`.

### `shell/`

Representa el **cascarón visual** de la aplicación.

Aquí vive la estructura general del layout:

- `header`
- `sidebar`
- `footer`
- componente principal con `router-outlet`
- layout para usuarios autenticados o públicos

Ejemplo de responsabilidad del shell:

- decidir cómo se ve la app
- definir dónde se renderizan las features
- manejar navegación estructural

> Regla práctica: `shell/` define **cómo se ve la app**, mientras `features/` define **qué hace la app**.

### `features/`

Es la carpeta principal de negocio. Cada subcarpeta representa una **feature** o dominio funcional.

Cada feature debería tener, como mínimo:

- su módulo
- su routing
- sus páginas
- sus componentes internos
- sus servicios
- sus modelos
- su estado, si aplica

---

## Estructura interna recomendada para una feature

Ejemplo con `orders/`:

```txt
features/
└── orders/
    ├── orders.module.ts
    ├── orders-routing.module.ts
    ├── pages/
    │   ├── orders-list/
    │   └── order-detail/
    ├── components/
    │   ├── order-filters/
    │   ├── order-table/
    │   └── order-summary-card/
    ├── services/
    │   ├── orders-api.service.ts
    │   └── orders-facade.service.ts
    ├── models/
    │   ├── order.model.ts
    │   └── order-filter.model.ts
    ├── store/
    │   ├── orders.actions.ts
    │   ├── orders.reducer.ts
    │   ├── orders.selectors.ts
    │   └── orders.effects.ts
    └── utils/
        └── order-mapper.ts
```

---

## Convenciones recomendadas

### `pages/`

Componentes que representan vistas completas y normalmente están asociadas a una ruta.

Ejemplos:

- `users-list-page`
- `user-detail-page`
- `dashboard-home-page`

### `components/`

Componentes internos de la feature que ayudan a construir las páginas.

Ejemplos:

- filtros
- tablas
- formularios
- cards
- widgets propios de esa feature

### `services/`

Servicios propios de la feature.

Ejemplos:

- acceso a API
- facades
- transformaciones de datos
- coordinación de lógica de aplicación

### `models/`

Interfaces, tipos y modelos exclusivos de la feature.

### `store/`

Estado local o modular de la feature.

Puede contener:

- actions
- reducers
- selectors
- effects
- facades
- signal stores

---

## Qué evitar

Evita una estructura global como esta:

```txt
app/
├── components/
├── services/
├── models/
├── pages/
├── guards/
└── pipes/
```

Este enfoque mezcla toda la aplicación por tipo técnico y hace que el proyecto escale mal.

Problemas comunes:

- carpetas demasiado grandes
- dependencias cruzadas difíciles de seguir
- poca cohesión por dominio
- mantenimiento más costoso

---

## Reglas prácticas para decidir dónde va cada cosa

- Si afecta a toda la app: `core/`
- Si se reutiliza entre varias features: `shared/`
- Si forma parte del layout global: `shell/`
- Si pertenece a un dominio funcional: `features/<nombre-feature>/`

---

## Recomendación final

Para un Angular mediano con enfoque module-first:

1. Usa `AppModule` como raíz.
2. Crea un módulo por feature.
3. Usa `RoutingModule` por feature.
4. Aplica lazy loading a features grandes.
5. Mantén `core/` pequeño y realmente global.
6. Usa `shared/` solo para reutilización real.
7. Mantén cada feature autocontenida.

---

## Ejemplo resumido

```txt
app/
├── core/
├── shared/
├── shell/
└── features/
    ├── auth/
    ├── users/
    ├── dashboard/
    └── orders/
```

Esta estructura suele ser suficientemente flexible para crecer sin perder claridad.
