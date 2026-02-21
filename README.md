# Snowflake Onboarding Framework con Terraform  
## Onboarding: de cero a una cuenta bien organizada

**Nelson** · Fundador y CDO · [Simov Labs](https://simov.io)

---

Este README es tu **guía paso a paso** para entender Snowflake y levantar una cuenta ordenada, segura y lista para equipos. No asumimos que ya sabes Snowflake; explicamos **qué es cada cosa**, **por qué la usamos** y **cuándo se aplica**. Al final habrás perdido el miedo a tocar la plataforma y tendrás un patrón claro para repetir en otros proyectos.

---

# Parte 1: Antes de tocar nada — Conceptos que necesitas

## 1.1 ¿Qué es Snowflake en una frase?

**Snowflake es una plataforma de datos en la nube** donde guardas datos (tablas), los consultas con SQL y los compartes de forma segura. A diferencia de un servidor que “apagas y encendes”, Snowflake separa **almacenamiento** (donde viven los datos) de **cómputo** (donde se ejecutan las consultas). Eso te permite escalar solo el cómputo cuando lo necesitas y pagar por uso.

**Por qué importa:** No tienes que dimensionar servidores de por vida; ajustas el “motor” según la carga. Eso reduce complejidad y coste.

---

## 1.2 La jerarquía de objetos: Account → Database → Schema → Table

Todo en Snowflake vive en una jerarquía clara. Conviene tenerla en la cabeza antes de ver código.

| Nivel      | Qué es en la práctica | Analogía rápida |
|-----------|------------------------|------------------|
| **Account** | Tu contrato con Snowflake; todo lo que creas vive aquí. | La “empresa” o “cuenta” en la nube. |
| **Database** | Un contenedor de alto nivel. Agrupa todo lo que pertenece a un dominio o producto. | Una “carpeta raíz” por área (por ejemplo: Finanzas, CRM). |
| **Schema** | Dentro de una base de datos, agrupa tablas, vistas y stages relacionados. | Subcarpetas por tema (por ejemplo: facturación, clientes). |
| **Table** | Donde realmente están los datos (filas y columnas). | El “archivo” de datos. |

**Por qué no usar solo una base de datos y el schema PUBLIC:**  
Si metes todo en una sola base y en `PUBLIC`, luego no puedes dar permisos finos (“solo finanzas”, “solo clientes”). Aquí usamos **una base por dominio** (ERP, CRM, SCM) y **schemas con nombre de negocio** (FINANCE, CUSTOMERS, LOGISTICS) para que los permisos y el orden sean claros desde el primer día.

**Beneficio:** Permisos por dominio/schema, nombres que cualquier persona del negocio entiende y menos riesgo de pisar objetos entre equipos.

---

## 1.3 Warehouses: el “motor” que ejecuta tus consultas

En Snowflake **los datos están guardados aparte del “motor” que ejecuta SQL**. Ese motor se llama **warehouse** (almacén de cómputo). Cada vez que ejecutas una query, Snowflake usa un warehouse; ese uso consume **créditos** y se factura.

**Por qué tener varios warehouses (ingestión, analítica, administración):**

- **Separar cargas:** ETL/cargas no compiten con reportes ni con tareas de mantenimiento.
- **Controlar coste:** Puedes dar warehouses pequeños (X-SMALL) a entornos de prueba y reservar tamaños mayores para producción.
- **Auto-suspend:** Si no hay consultas, el warehouse se apaga a los X segundos; no pagas por tiempo parado.

En este proyecto creamos tres por ambiente:

- **WH_INGESTION_*** — Cargas de datos, pipelines ETL (auto-suspend 60 s).
- **WH_ANALYTICS_*** — Consultas analíticas, dashboards (120 s).
- **WH_ADMIN_*** — Tareas administrativas, mantenimiento (30 s).

**Cuándo se “aplica”:** Cada vez que un usuario o un job ejecuta una query; el role del usuario debe tener **USAGE** sobre el warehouse que use.

---

## 1.4 Roles y permisos: por qué no damos permisos directos al usuario

Si diéramos a cada persona permisos directos sobre cada tabla, en cuanto haya 50 usuarios y 20 tablas sería un caos. Snowflake usa **roles**: un “carné” que agrupa permisos. Tú **asignas roles a usuarios**; los permisos los tienen los roles.

**Principio:** **Mínimo privilegio** — cada role solo debe tener lo necesario para su trabajo.

En este proyecto usamos dos capas:

1. **Object Roles (OR_*)** — Atados a **un schema concreto** (ej. solo `ERP_DEV.FINANCE`). Definen *qué* se puede hacer ahí: leer, escribir o administrar.
2. **Functional Roles (FR_*)** — Atados al **perfil del usuario** (analista, ingeniero, admin, solo lectura). Agrupan varios object roles.

**Flujo:** Usuario → tiene un Functional Role → ese FR “hereda” Object Roles → así el usuario termina con permisos sobre bases/schemas/tablas concretas.

**Beneficio:** Cambias permisos en el role y todos los usuarios con ese role se actualizan; no tocas usuario por usuario.

---

## 1.5 Políticas de seguridad: qué son, cuándo se aplican y por qué

Aquí es donde suele haber más dudas. En Snowflake hay dos tipos de “políticas” que tocamos: **Password Policy** y **Authentication Policy (MFA)**. Son cosas distintas y se aplican en momentos distintos.

### Password Policy (política de contraseña)

**Qué es:** Un conjunto de reglas que Snowflake aplica a las **contraseñas** de los usuarios: longitud, complejidad, intentos fallidos, historial.

**Cuándo se aplica:**

- Cuando un **usuario cambia o establece su contraseña** (primera vez o cambio periódico): Snowflake comprueba que cumpla las reglas (longitud, mayúsculas, minúsculas, números, especiales, no repetir las últimas N).
- Cuando un **usuario intenta iniciar sesión**: si falla X veces seguidas, la cuenta se bloquea durante Y minutos (protección ante fuerza bruta).

**A quién afecta:** A todos los usuarios a los que se les haya asignado esa política. En este proyecto la política se **asocia a la cuenta** como política por defecto, así que afecta a todos los usuarios que usen autenticación por contraseña (salvo que les asignes otra política explícita).

**Qué creamos y por qué:**

| Regla              | Valor en este proyecto | Razón |
|--------------------|------------------------|--------|
| Longitud mínima    | 12 caracteres          | Más difícil de adivinar o atacar por fuerza bruta. |
| Mayúsculas / minúsculas / números / especiales | Al menos 1 de cada tipo | Evita contraseñas triviales tipo “password123”. |
| Intentos fallidos  | 5                      | Tras 5 fallos, bloqueo temporal (15 min) para limitar ataques. |
| Historial          | 5 contraseñas          | No se puede reutilizar ninguna de las últimas 5 (evita rotar y volver a la misma). |

**Resumen:** La Password Policy **no decide si puedes o no entrar** (eso lo hace el usuario/contraseña correctos); **obliga a que las contraseñas sean fuertes y limita los intentos de login**.

---

### Authentication Policy y MFA (autenticación multifactor)

**Qué es:** Una política a nivel de **cuenta o usuario** que dice **cómo** puede autenticarse alguien: solo contraseña, o contraseña + segundo factor (MFA: app, SMS, etc.).

**Cuándo se aplica:** En el momento del **login**. Snowflake comprueba si la política exige MFA; si sí, el usuario debe haber activado su segundo factor; si no, no puede entrar.

**A quién afecta:** Puede ser la cuenta entera (todos los usuarios) o usuarios concretos, según cómo la configures.

**Qué hacemos en este proyecto:** El código Terraform **no crea** la Authentication Policy (el provider puede no exponerla aún). En el módulo `security` está **documentado** cómo activar MFA:

- **Desde la UI:** Admin → Security → Authentication Policy → crear política con MFA obligatorio.
- **Desde SQL (ACCOUNTADMIN):**  
  `CREATE AUTHENTICATION POLICY ... MFA_ENROLLMENT = 'REQUIRED';`  
  y asociarla a la cuenta.

**Cómo un usuario activa su MFA:** En Snowsight: perfil (arriba derecha) → **Security** → **Multi-Factor Auth** → **Enroll** y seguir los pasos (app autenticadora, etc.).

**Resumen:** La **Password Policy** regula la **calidad de la contraseña**. La **Authentication Policy (MFA)** regula **si hace falta un segundo factor además de la contraseña** al entrar. Las dos se complementan.

---

# Parte 2: Qué hace este proyecto (el viaje completo)

Este repositorio es un **framework de onboarding** que, con Terraform, crea de forma repetible en tu cuenta Snowflake:

1. **Bases de datos** por dominio (ERP, CRM, SCM) y ambiente (DEV, UAT, PROD), con schemas y tablas ya definidas.
2. **Warehouses** por propósito (ingestión, analítica, administración) en cada ambiente.
3. **Políticas de seguridad:** Password Policy aplicada a la cuenta y documentación para MFA.
4. **Modelo RBAC:** Object Roles por schema, Functional Roles por perfil y usuarios de ejemplo asignados.
5. **Script de datos ficticios** (opcional) para que puedas practicar SQL sin miedo.

Cada recurso en el código está comentado en español (qué hace, por qué existe y qué pasaría si no estuviera). El README te lleva de la mano en **conceptos** y **decisiones de diseño**; el código es el **tutorial técnico** línea a línea.

---

# Parte 3: Arquitectura en una imagen

La siguiente figura resume la jerarquía que creamos: cuentas → bases por dominio → schemas → tablas, warehouses por propósito, y encima la capa de roles y usuarios.

```
                    ┌─────────────────────────────────────────────────────────┐
                    │                    SNOWFLAKE ACCOUNT                      │
                    └─────────────────────────────────────────────────────────┘
                                              │
         ┌────────────────────────────────────┼────────────────────────────────────┐
         │                                    │                                    │
         ▼                                    ▼                                    ▼
┌─────────────────┐              ┌─────────────────┐              ┌─────────────────┐
│   ERP_<ENV>     │              │   CRM_<ENV>     │              │   SCM_<ENV>     │
│   └─ FINANCE    │              │   └─ CUSTOMERS  │              │   └─ LOGISTICS  │
│      ├─ INVOICES│              │      ├─ CONTACTS│              │      ├─ SHIPMENTS│
│      └─ COST_   │              │      └─ OPPORT.│              │      └─ SUPPLIERS│
│         CENTERS │              │                │              │                 │
└─────────────────┘              └─────────────────┘              └─────────────────┘
         │                                    │                                    │
         └────────────────────────────────────┼────────────────────────────────────┘
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    ▼                         ▼                         ▼
         ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
         │ WH_INGESTION_*   │    │ WH_ANALYTICS_*   │    │ WH_ADMIN_*       │
         └──────────────────┘    └──────────────────┘    └──────────────────┘
                                              │
                    Object Roles (por schema): OR_READ_* | OR_WRITE_* | OR_ADMIN_*
                                              │
                    Functional Roles: FR_DATA_ANALYST | FR_DATA_ENGINEER | FR_DATA_ADMIN | FR_READONLY
                                              │
                    Usuarios ejemplo: U_ANA_GARCIA | U_CARLOS_LOPEZ | U_MARIA_TORRES | U_PEDRO_RAMIREZ
```

---

# Parte 4: RBAC al detalle — Quién puede hacer qué

## 4.1 Object Roles (OR_*): permisos por schema

Cada **schema** de negocio tiene tres roles asociados. Así podemos dar “solo lectura”, “lectura y escritura” o “todo (incluido crear tablas)” sin mezclar permisos entre dominios.

| Role (ejemplo)           | Privilegios sobre ese schema |
|--------------------------|------------------------------|
| **OR_READ_…**            | USAGE en database y schema; **SELECT** en todas las tablas del schema. |
| **OR_WRITE_…**           | Todo lo de READ + **INSERT, UPDATE, DELETE** en las tablas. |
| **OR_ADMIN_…**           | Todo lo de WRITE + **CREATE TABLE / VIEW / STAGE** en el schema, **MODIFY** en la database, **USAGE** en el warehouse de administración. |

**Cuándo “se aplican”:** Cada vez que un usuario (a través de un role que tenga uno de estos OR_*) intenta hacer una operación sobre esa base/schema/tabla. Snowflake comprueba si el role activo del usuario tiene el privilegio necesario.

---

## 4.2 Functional Roles (FR_*): el perfil del usuario

Los Functional Roles **no tienen privilegios directos**; “heredan” Object Roles. Así, un solo FR agrupa varios OR_* y refleja el puesto o responsabilidad (analista, ingeniero, admin, solo lectura).

**Resumen por ambiente:**

- En **DEV y UAT** suele ser más permisivo (analistas pueden escribir, ingenieros pueden hacer DDL) para que el equipo pueda desarrollar y probar.
- En **PROD** se endurece: analistas solo leen, ingenieros solo escriben datos (no DDL arbitrario), y solo el perfil admin tiene control total.

| Functional Role   | En DEV / UAT (qué object roles hereda) | En PROD (qué object roles hereda) | Uso típico |
|------------------|----------------------------------------|-----------------------------------|------------|
| **FR_DATA_ANALYST**  | OR_WRITE en todos los schemas          | OR_READ en todos los schemas       | Analistas que en prod solo consultan; en dev/uat pueden cargar datos de prueba. |
| **FR_DATA_ENGINEER** | OR_ADMIN en todos los schemas          | OR_WRITE en todos los schemas      | Ingenieros que en prod solo modifican datos/ETL; en dev/uat pueden crear tablas. |
| **FR_DATA_ADMIN**    | OR_ADMIN en todos                      | OR_ADMIN en todos                  | Administradores de datos; acceso completo y a todos los warehouses. |
| **FR_READONLY**      | (opcional: OR_READ en dev/uat)         | OR_READ en todos los schemas       | Ejecutivos o stakeholders que solo consultan reportes en prod. |

**Flujo concreto:**  
Usuario `U_ANA_GARCIA` tiene role por defecto `FR_DATA_ANALYST`. En PROD, ese FR tiene asignados los roles `OR_READ_ERP_FINANCE_PROD`, `OR_READ_CRM_CUSTOMERS_PROD`, `OR_READ_SCM_LOGISTICS_PROD`. Por tanto, Ana puede hacer **solo SELECT** en esas bases/schemas/tablas, usando el warehouse que tenga por defecto.

---

## 4.3 Usuarios de ejemplo

Creamos cuatro usuarios ficticios para que puedas probar el RBAC sin tocar usuarios reales:

| Usuario           | Functional Role   | Default Warehouse   | Propósito de ejemplo |
|-------------------|-------------------|----------------------|-----------------------|
| U_ANA_GARCIA      | FR_DATA_ANALYST   | WH_ANALYTICS_*       | Probar permisos de analista (lectura en prod, escritura en dev/uat). |
| U_CARLOS_LOPEZ    | FR_DATA_ENGINEER  | WH_INGESTION_*       | Probar permisos de ingeniero (cargas, escritura). |
| U_MARIA_TORRES    | FR_DATA_ADMIN     | WH_ADMIN_*            | Probar permisos de administrador. |
| U_PEDRO_RAMIREZ   | FR_READONLY       | WH_ANALYTICS_*       | Probar permisos de solo lectura (ej. ejecutivo). |

Todos se crean con **must_change_password = true** para que el primer login sea seguro y alineado con la Password Policy.

---

# Parte 5: Convención de nombres — Por qué y cómo

Usamos **una convención estricta** para que cualquier persona (y cualquier script) sepa qué es cada objeto sin abrirlo.

| Tipo            | Patrón                               | Ejemplo                | Beneficio |
|-----------------|--------------------------------------|------------------------|-----------|
| Databases       | `<DOMINIO>_<AMBIENTE>`               | ERP_DEV, CRM_PROD      | Sabes dominio y ambiente de un vistazo. |
| Schemas         | Nombre de negocio (no PUBLIC)        | FINANCE, CUSTOMERS     | Permisos y organización claros. |
| Tablas          | Plural, descriptivo                   | INVOICES, CONTACTS     | Consistencia con estándares SQL. |
| Warehouses      | `WH_<PROPOSITO>_<AMBIENTE>`          | WH_ANALYTICS_DEV      | Propósito y ambiente visibles. |
| Object Roles    | `OR_<NIVEL>_<DOMINIO>_<SCHEMA>_<ENV>`| OR_READ_ERP_FINANCE_DEV | Sabes qué nivel y sobre qué schema aplica. |
| Functional Roles| `FR_<NOMBRE>`                        | FR_DATA_ANALYST       | Fácil mapear a equipos o perfiles. |
| Usuarios        | `U_<NOMBRE>_<APELLIDO>`              | U_JUAN_PEREZ          | Identificación rápida y evitas conflictos con roles. |

Todo en **mayúsculas** para objetos Snowflake (estándar común y legibilidad en listados).

---

# Parte 6: Prerrequisitos e instalación

## 6.1 Terraform

**Qué es:** Herramienta de “infraestructura como código”. Describe recursos (bases de datos, roles, etc.) en archivos; Terraform los crea o actualiza en Snowflake de forma repetible.

**Por qué lo usamos:** Para que el onboarding sea el mismo en cualquier cuenta y ambiente, sin depender de clics manuales en la UI.

- **Versión:** >= 1.0  
- **Instalación:**  
  - **Mac:** `brew install terraform`  
  - **Linux:** [terraform.io/downloads](https://www.terraform.io/downloads) o gestor de paquetes (`apt`, `yum`, etc.).  
  - **Windows:** Usar WSL2 e instalar Terraform dentro de Linux.

## 6.2 Cuenta Snowflake

Necesitas una **cuenta Snowflake** (trial o estándar) y un **usuario con rol SYSADMIN o ACCOUNTADMIN** para poder crear bases de datos, roles, warehouses y usuarios. Sin ese rol, Terraform no podrá aplicar los cambios.

---

# Parte 7: Cómo obtener las credenciales de Snowflake

Terraform se conecta a Snowflake con: **account**, **usuario**, **contraseña** y **role**. Nunca hardcodees la contraseña en archivos versionados.

1. **Account identifier**  
   En **Snowsight:** Admin → **Accounts** → copia el **Account identifier** (ej. `xy12345` o `xy12345.us-east-1`). Si la región va en el identifier, en `terraform.tfvars` puedes dejar `snowflake_region` vacío.

2. **Usuario y contraseña**  
   Usuario que tenga SYSADMIN (o ACCOUNTADMIN). Para no guardar la contraseña en disco:  
   `export TF_VAR_snowflake_password="tu_password"`  
   y no la pongas en `terraform.tfvars`.

3. **Role**  
   El role con el que Terraform ejecutará (por defecto `SYSADMIN`). Debe poder crear y modificar objetos en la cuenta.

---

# Parte 8: Ejecución paso a paso (qué hace cada comando)

Sigue estos pasos **desde la raíz del repo**, eligiendo un ambiente (dev, uat o prod).

### Paso 1: Entrar al ambiente

```bash
cd environments/dev   # o uat / prod
```

Cada carpeta (`dev`, `uat`, `prod`) es un **estado de Terraform independiente**: un `terraform.tfstate` distinto. Así puedes tener DEV, UAT y PROD en la misma cuenta (o en cuentas distintas) sin mezclar planes.

### Paso 2: Inicializar Terraform

```bash
terraform init
```

Descarga el provider de Snowflake y prepara el directorio. Solo hace falta una vez (o al cambiar de provider/versión).

### Paso 3: Configurar variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edita terraform.tfvars con tu account, user, password (o usa TF_VAR_snowflake_password) y role
```

Sin `terraform.tfvars` (o variables por `-var` / entorno), Terraform te pedirá los valores en el plan/apply.

### Paso 4: Ver el plan y aplicar

```bash
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

- **plan:** Muestra qué recursos se crearán o modificarán, sin cambiar nada.  
- **apply:** Crea o actualiza los recursos en Snowflake.  
Revisa el plan antes de aplicar; si algo no cuadra, no confirmes el apply.

### Paso 5: (Opcional) Cargar datos ficticios

Terraform crea las **tablas vacías**. Para tener datos con los que practicar:

- En **Snowsight:** Worksheets → pega el contenido de `scripts/seed_data.sql`.  
- Sustituye `ERP_DEV`, `CRM_DEV`, `SCM_DEV` por tu ambiente si usas UAT o PROD.  
- Ejecuta cada bloque `INSERT` con un role que tenga INSERT en ese schema (por ejemplo el que usaste para Terraform o un usuario con FR_DATA_ENGINEER / FR_DATA_ADMIN).

Así puedes hacer `SELECT`, probar joins entre ERP/CRM/SCM y entender cómo se relacionan los objetos sin miedo a romper nada.

---

# Parte 9: Cómo extender el proyecto

## 9.1 Agregar un nuevo dominio de negocio

**Concepto:** Un “dominio” es una base de datos + schema(s) + tablas que representan un área (p. ej. HR, Ventas). Para añadir uno nuevo:

1. **Módulo database**  
   En el `main.tf` del ambiente: define un `local` con las tablas (como `erp_tables` / `crm_tables`) y un `module "database_<dominio>"` con `dominio`, `schema_name`, `tables_config`.

2. **RBAC**  
   Añade el nuevo schema a la lista `schemas` del módulo `rbac` (database_name, schema_name, dominio, table_names) y, en el mapa de functional roles, incluye los object roles del nuevo dominio (OR_READ_*, OR_WRITE_*, OR_ADMIN_*) según quién deba acceder.

3. **Datos de ejemplo**  
   En `scripts/seed_data.sql` (o un script por ambiente) añade INSERTs para las nuevas tablas.

**Beneficio:** Mismo patrón que ERP/CRM/SCM; permisos y convenciones quedan coherentes.

## 9.2 Agregar un nuevo usuario

En el `main.tf` del ambiente, dentro del módulo `rbac`, en la variable `users`, añade un elemento con:

- `login_name` (convención `U_NOMBRE_APELLIDO`)  
- `default_role` (uno de los FR_*)  
- `default_warehouse` (nombre del WH_*, p. ej. del output del módulo warehouse)  
- `comment`

Ejemplo:

```hcl
{ login_name = "U_LUISA_FERNANDEZ", default_role = "FR_DATA_ANALYST", default_warehouse = module.warehouse.warehouse_names["ANALYTICS"], comment = "Onboarding: Analista - ejemplo" }
```

Luego: `terraform plan` y `terraform apply` en ese ambiente.

---

# Parte 10: FAQ — Errores comunes y soluciones

| Problema | Qué suele pasar | Qué hacer |
|----------|------------------|-----------|
| `Invalid identifier` / `object does not exist` | El role con el que Terraform se conecta no tiene privilegios sobre ese objeto. | Conecta con un usuario que tenga SYSADMIN o ACCOUNTADMIN. |
| Password policy / attachment ya existe | La política o su asociación a la cuenta ya fue creada (por otro apply o por la UI). | Revisa en la UI; si quieres que Terraform la gestione, `terraform state rm ...` del recurso que corresponda y vuelve a aplicar (con cuidado en prod). |
| `snowflake_role` no existe / usar `snowflake_account_role` | En versiones nuevas del provider el recurso pasó a llamarse `snowflake_account_role`. | Revisa la [doc del provider](https://registry.terraform.io/providers/Snowflake-Labs/snowflake/latest/docs) y sustituye en el código. |
| Error al asignar role a usuario (`snowflake_grant_account_role`) | Algunas versiones usan `user_name` en lugar de `role_name` para el grantee. | Mira el recurso en el registry y ajusta los argumentos (p. ej. `user_name` = usuario, `role_name` = role otorgado). |
| State bloqueado o conflictos | Dos `apply` a la vez o state corrupto. | No ejecutes dos applies simultáneos en el mismo directorio; con backend remoto, revisa el bloqueo en el backend. |

---

# Parte 11: Glosario

- **Account:** La unidad de facturación y aislamiento en Snowflake; todo (databases, usuarios, warehouses) pertenece a una cuenta.  
- **Database:** Contenedor de alto nivel; agrupa schemas (y por tanto tablas, vistas, stages).  
- **Schema:** Dentro de una database, agrupa tablas, vistas, stages, etc.  
- **Warehouse:** Recurso de cómputo que ejecuta queries; consume créditos cuando está activo.  
- **Object Role (OR_*):** Role con privilegios sobre objetos concretos (database, schema, tablas); atado a un dominio/schema/ambiente.  
- **Functional Role (FR_*):** Role que agrupa uno o más object roles; se asocia al perfil del usuario (analista, ingeniero, admin, solo lectura).  
- **Grant:** Asignación de un privilegio a un role, o de un role a un usuario u otro role.  
- **Password Policy:** Reglas que Snowflake aplica a las contraseñas (longitud, complejidad, intentos fallidos, historial); se aplican al cambiar/establecer contraseña y al intentar login.  
- **Authentication Policy / MFA:** Reglas que exigen (o no) un segundo factor de autenticación al iniciar sesión; se aplican en el login.

---

# Parte 12: Estructura del repositorio

```
snowflake-onboarding/
├── .gitignore
├── README.md
├── versions.tf
├── scripts/
│   └── seed_data.sql
├── modules/
│   ├── database/
│   ├── warehouse/
│   ├── security/
│   └── rbac/
└── environments/
    ├── dev/
    ├── uat/
    └── prod/
```

- **modules:** Código reutilizable (database, warehouse, security, rbac); cada uno tiene `main.tf`, `variables.tf`, `outputs.tf` y comentarios en español.  
- **environments:** Cada subcarpeta es un “stack” (dev/uat/prod) con su propio `main.tf`, variables y `terraform.tfvars.example`.  
- **scripts/seed_data.sql:** INSERTs de ejemplo para practicar SQL tras el primer apply.

---

# Enlaces útiles

- [Snowflake – Create Database](https://docs.snowflake.com/en/sql-reference/sql/create-database)  
- [Snowflake – Access Control](https://docs.snowflake.com/en/user-guide/security-access-control)  
- [Snowflake – Password Policy](https://docs.snowflake.com/en/user-guide/security-password-policy)  
- [Snowflake – MFA](https://docs.snowflake.com/en/user-guide/security-mfa)  
- [Terraform – Snowflake Provider](https://registry.terraform.io/providers/Snowflake-Labs/snowflake/latest/docs)

---

Si algo no queda claro en tu equipo, puedes usar las secciones (por ejemplo “Políticas de seguridad” o “RBAC al detalle”) como material de onboarding interno.
