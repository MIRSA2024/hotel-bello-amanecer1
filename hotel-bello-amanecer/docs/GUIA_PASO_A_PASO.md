cd /c/Users/mirth/Downloads/hotel-bello-amanecer

git init -b main
git config user.name "Tu Nombre"
git config user.email "tu-correo@ejemplo.com"

git statusgit init -b main
git add .
git status# Guía paso a paso: de cero a las 8 capturas del informe

Esta guía te lleva desde "no tengo nada" hasta tener las capturas de las Figuras **6, 7, 8, 9, 10, 12, 13 y 14**
dentro del informe APF1. Las capturas tienen que ser **reales** (tomadas por ti de tu propio laboratorio): el pie de
cada figura dice "Captura de la consola de AWS / terminal del equipo". Aquí tienes todo el código para generarlas.

**Tiempo estimado:** 3 a 4 horas la primera vez (casi todo es esperar a que AWS cree cosas).
**Costo:** el entorno completo consume unos 0,2 USD por hora de los créditos del laboratorio (NAT Gateway, ALB, RDS
Multi-AZ y 2 nodos EC2). Haz todo en una sola sesión y **destruye al terminar** (Parte 9).

---

## Alternativa: no puedo instalar nada → usa GitHub Codespaces (todo en el navegador)

Codespaces es una computadora Linux en la nube, con Docker y terminal, que se abre en una pestaña del navegador.
Necesitas solo una cuenta de GitHub. (El plan gratuito incluye una cantidad mensual de horas, unas 60 con la máquina
básica; revisa el saldo en GitHub → Settings → Billing. Esta guía necesita unas 4-6 horas.)
Con esto **te saltas la Parte 0 y los pasos de instalación**; el resto de las partes se hacen igual, pero dentro de Codespaces.

1. En https://github.com crea el repositorio `hotel-bello-amanecer` **marcando "Add a README file"**.
2. En el repositorio: botón verde **Code** → pestaña **Codespaces** → **Create codespace on main**. Espera a que cargue (VS Code en el navegador).
3. Arrastra `hotel-bello-amanecer.zip` desde tu computadora al panel izquierdo (Explorer) y en la terminal de abajo ejecuta:

```bash
unzip -q hotel-bello-amanecer.zip
cp -r hotel-bello-amanecer/. . && rm -rf hotel-bello-amanecer hotel-bello-amanecer.zip
bash scripts/setup-codespaces.sh        # instala Terraform, AWS CLI y python-docx (2-3 min)
git add . && git commit -m "feat: estructura inicial del proyecto" && git push
```

   (Codespaces ya está conectado a tu GitHub: no pide contraseña. Con esto terminaste la Parte 1.)
4. Sigue desde la **Parte 2** (Docker Compose). Notas para Codespaces:
   - Para abrir el frontend (http://localhost:8081) usa la pestaña **Ports** de abajo: clic en el globo junto al puerto 8081.
   - **Parte 3:** las credenciales de AWS se pegan con `mkdir -p ~/.aws && code ~/.aws/credentials`.
   - Las capturas las sacas igual (`Windows + Shift + S`) de la pestaña del navegador.
   - **Para subir las capturas:** arrástralas a la carpeta `docs/evidencias/` del panel Explorer.
   - **Parte 8:** el script se ejecuta en la terminal de Codespaces; luego haz clic derecho sobre `docs/APF_1_final.docx` → **Download**.
5. Al terminar, la Parte 9 (destruir) y luego apaga el Codespace: https://github.com/codespaces → `...` → **Stop codespace**.

Si Codespaces no te funciona, la otra opción sin instalar es **AWS CloudShell** (el icono `>_` de la consola de AWS): ya trae AWS CLI y Git,
y las credenciales son automáticas; tendrías que instalar Terraform ahí (`scripts/setup-codespaces.sh` también sirve). Docker en CloudShell
puede no estar disponible en tu laboratorio; en ese caso las imágenes (`push-images.sh`) sí requieren Codespaces.

---

## Parte 0. Qué vas a instalar (una sola vez)

Si usas Windows, instala estos programas y reinicia el equipo al final:

| Programa | Para qué | Cómo |
|---|---|---|
| Git para Windows | Subir el código a GitHub. Incluye **Git Bash**, la terminal donde ejecutarás todo | https://git-scm.com/download/win |
| Docker Desktop | Levantar los contenedores | https://www.docker.com/products/docker-desktop/ |
| AWS CLI v2 | Hablar con AWS desde la terminal | https://aws.amazon.com/cli/ |
| Terraform | Crear la infraestructura | https://developer.hashicorp.com/terraform/install (o `winget install Hashicorp.Terraform`) |
| Python 3 (opcional) | Insertar las capturas en el Word automáticamente | https://www.python.org/downloads/ |

Abre **Git Bash** (menú Inicio → "Git Bash") y comprueba que todo responde:

```bash
git --version
docker --version
aws --version
terraform --version
```

> **Todos los comandos de esta guía se ejecutan en Git Bash**, dentro de la carpeta del proyecto.

---

## Parte 1. Subir el proyecto a GitHub

1. Crea una cuenta en https://github.com (si no tienes).
2. Crea un repositorio nuevo: botón **New** → nombre `hotel-bello-amanecer` → **no** marques "Add a README" → **Create repository**.
3. Descomprime `hotel-bello-amanecer.zip` (por ejemplo en `C:\proyectos\`) y en Git Bash:

```bash
cd /c/proyectos/hotel-bello-amanecer
git init -b main
git config user.name  "Tu Nombre"
git config user.email "tu-correo@ejemplo.com"
git add .
git status          # revisa que NO aparezcan .env ni archivos .tfstate
git commit -m "feat: estructura inicial del proyecto Hotel Bello Amanecer"
git remote add origin https://github.com/TU_USUARIO/hotel-bello-amanecer.git
git push -u origin main
```

La primera vez se abre el navegador para que inicies sesión en GitHub; acepta.

4. Crea la rama de integración (convención del informe, Tabla 24):

```bash
git switch -c develop
git push -u origin develop
git switch main
```

5. Guarda la URL `https://github.com/TU_USUARIO/hotel-bello-amanecer`: va en la sección 6.4 del informe (la inserta el script de la Parte 8).

---

## Parte 2. Levantar todo en tu computadora → **Figura 9**

1. Prepara las variables locales (el archivo `.env` no se sube a GitHub):

```bash
cp .env.example .env
```

Abre `.env` con el Bloc de notas y cambia `DB_PASSWORD` por cualquier clave de prueba.

2. Abre **Docker Desktop** y espera a que diga "Engine running". Luego:

```bash
docker compose up -d --build
```

La primera vez tarda entre 5 y 15 minutos (descarga imágenes y compila Java y Angular).

3. Comprueba el estado (repite hasta que los servicios digan `healthy`; el emulador SQS y PostgreSQL pueden decir solo `Up`):

```bash
docker compose ps
```

4. Genera actividad entre los contenedores:

```bash
./scripts/smoke-test.sh
docker compose logs --tail 12 api-reservas consumer-pagos servicio-notificaciones
```

Verás que la reserva nace `PENDIENTE` y pasa a `CONFIRMADA`, y en el log de notificaciones aparece `[CORREO SIMULADO]`.
(Con una probabilidad del 10 % la pasarela simulada la rechaza: es parte del diseño. Repite si te sale `RECHAZADA` y quieres ver el correo.)

5. Abre http://localhost:8081 para probar la interfaz.

### 📸 Figura 9: `figura09.png`

Una sola captura de la terminal que muestre, **juntos**: el resultado de `docker compose ps` (servicios `Up` / `healthy`)
y debajo el `docker compose logs` con la comunicación entre contenedores. Haz la ventana de Git Bash grande antes de capturar.
Si no cabe todo, saca dos capturas y nómbralas `figura09_1.png` (ps) y `figura09_2.png` (logs).

> **Cómo capturar:** `Windows + Shift + S` → seleccionar área → pega en Paint o guarda desde la notificación → *Guardar como* PNG en `docs/evidencias/`.

---

## Parte 3. Conectarte a AWS Academy

1. Entra a tu curso en AWS Academy → **Learner Lab** → **Start Lab**. Espera a que el círculo junto a "AWS" se ponga **verde**.
2. Arriba a la derecha pulsa **AWS Details** → **AWS CLI: Show** → copia las tres líneas (`aws_access_key_id`, `aws_secret_access_key`, `aws_session_token`).
3. En Git Bash:

```bash
mkdir -p ~/.aws
notepad ~/.aws/credentials      # pega el contenido tal cual (empieza con [default])
aws configure set region us-east-1
aws sts get-caller-identity     # debe mostrar tu cuenta; si da error, las credenciales están mal
```

> ⚠️ Las credenciales **caducan** cuando termina la sesión del laboratorio (unas 4 horas). Si ves `ExpiredToken`, vuelve a copiarlas.
> ⚠️ **Nunca** captures ni subas el contenido de `~/.aws/credentials`.

---

## Parte 4. Crear la infraestructura con Terraform → **Figura 10**

El orden es `network → security → data → compute`. Para tener buenas capturas para la Figura 10, haz el primer módulo a mano:

```bash
cd infra/network
terraform init
terraform plan -out tfplan
```

### 📸 Figura 10 (parte 1): `figura10_1.png`
Captura del final de `terraform plan`, donde aparece la línea **`Plan: N to add, 0 to change, 0 to destroy.`**

```bash
terraform apply tfplan
```

### 📸 Figura 10 (parte 2): `figura10_2.png`
Captura del final del `apply`, donde aparece **`Apply complete! Resources: N added`** y los `Outputs`.

Después, despliega los otros tres módulos con el script (no hace falta capturarlos):

```bash
cd ../..
./infra/deploy.sh security data compute
```

⏱ El módulo `data` tarda **15 a 20 minutos** (RDS Multi-AZ). Mientras esperas, ve a la Parte 5.

**Si Terraform da error**, copia el mensaje completo y pégamelo. Los dos más probables en un laboratorio:

| Error | Solución |
|---|---|
| RDS: Multi-AZ no permitido | `cd infra/data && terraform apply -var="db_multi_az=false"` (y anótalo en la sección de limitaciones del informe) |
| RDS: no puede crear el secreto administrado | `terraform apply -var="use_managed_master_password=false"` (es el "plan B" que ya describe la nota del informe) |
| `ExpiredToken` / `AuthFailure` | Volver a copiar las credenciales (Parte 3) |

---

## Parte 5. Publicar las imágenes y arrancar los servicios

Cuando `infra/deploy.sh` termine (los 4 módulos):

```bash
./scripts/push-images.sh      # construye y sube las 4 imágenes a ECR (10-15 min la primera vez)
./ecs/deploy-services.sh      # crea los servicios ECS; al final imprime la URL del ALB
```

Si termina con "Aún no están estables", espera 3-5 minutos y revisa en la consola: **ECS → Clusters → hba-ecs-cluster → Services → pestaña Events**.

Prueba la aplicación (el certificado es autofirmado: el navegador avisará, acepta continuar):

```bash
./scripts/smoke-test.sh https://TU-ALB.us-east-1.elb.amazonaws.com
```

---

## Parte 6. Las capturas de la consola de AWS

**Antes de cada captura:** comprueba arriba a la derecha que la región sea **N. Virginia (us-east-1)**, haz zoom del navegador al 80 % si no cabe, y ten la ventana lo más completa posible.

### 📸 Figura 6: `figura06.png`: VPC, subredes y rutas
**Consola → VPC → Your VPCs → `hba-vpc` → pestaña *Resource map*.**
Debe verse: las 6 subredes en dos zonas, las 3 tablas de ruteo (`hba-rt-public`, `hba-rt-private-app`, `hba-rt-isolated`), el Internet Gateway, la NAT Gateway y el endpoint de S3.

### 📸 Figura 7: `figura07_1.png`, `figura07_2.png`, `figura07_3.png`: cómputo operativo
Tres capturas apiladas:
1. **EC2 → Instances:** las dos instancias `hba-ecs-node` en estado *Running*. Añade las columnas *Subnet ID* y *Public IPv4 address* (⚙ de la tabla): la IP pública debe estar vacía, porque están en subredes privadas.
2. **ECS → Clusters → `hba-ecs-cluster` → pestaña Services:** los 4 servicios con sus tareas en *Running* (p. ej. 2/2, 2/2, 1/1, 1/1).
3. **EC2 → Target Groups → `hba-tg-api`** (y luego `hba-tg-frontend`) → pestaña *Targets*: todos en **Healthy**.

### 📸 Figura 8: `figura08_1.png`, `figura08_2.png`, `figura08_3.png`: almacenamiento y BD
1. **S3 → bucket `hba-media-…` → pestaña Properties:** *Bucket Versioning = Enabled* y, más abajo, *Default encryption = SSE-KMS*. (Y en *Permissions*, *Block all public access = On*, si cabe.)
2. **RDS → Databases → `hba-db-principal`:** pestaña *Configuration* (Multi-AZ = Yes, Encryption = Enabled).
3. Misma BD, pestaña *Connectivity & security* (Publicly accessible = **No**) o *Maintenance & backups* (Backup retention = 7 days).

### 📸 Figura 12: `figura12_1.png` … `figura12_6.png`: Security Groups
**EC2 → Security Groups.** Para cada uno de `hba-sg-alb`, `hba-sg-app`, `hba-sg-db`: abre el grupo y captura la pestaña **Inbound rules** y la pestaña **Outbound rules** (recorta solo las filas de reglas; son capturas pequeñas). `hba-sg-db` no tiene reglas de salida: la captura vacía es la evidencia.

### 📸 Figura 13: `figura13_1.png`, `figura13_2.png`: roles
1. **EC2 → Launch Templates → `hba-lt-ecs-…` → Details → Advanced details:** campo *IAM instance profile = LabInstanceProfile*.
2. **EC2 → Instances →** un nodo → pestaña **Security:** campo *IAM Role = LabRole*.
   (Opcional si el laboratorio te deja: **IAM → Roles → LabRole** con sus políticas.)

### 📸 Figura 14: `figura14_1.png` … `figura14_4.png`: cifrado y certificado
1. **Certificate Manager (ACM):** el certificado, *Type = Imported*, *Status = Issued*.
2. **EC2 → Load Balancers → `hba-alb` → pestaña Listeners and rules:** `HTTPS:443` con el certificado y la política `ELBSecurityPolicy-TLS13-1-2-2021-06`, y `HTTP:80` redirigiendo a HTTPS.
3. **SQS → `q-reservas` → pestaña Encryption:** *Amazon SQS key (SSE-SQS) = Enabled*.
4. (Si quieres reforzar) la captura de RDS con *Encryption = Enabled* ya está en la Figura 8.

---

## Parte 7. Guardar las capturas con el nombre correcto

Mueve cada imagen a la carpeta `docs/evidencias/` con los nombres exactos:

```
figura06.png
figura07_1.png  figura07_2.png  figura07_3.png
figura08_1.png  figura08_2.png  figura08_3.png
figura09.png
figura10_1.png  figura10_2.png
figura12_1.png  …  figura12_6.png
figura13_1.png  figura13_2.png
figura14_1.png  …  figura14_4.png
```

Cuando una figura tiene varias imágenes (`_1`, `_2`…), el script las apila en ese orden dentro del mismo recuadro.

---

## Parte 8. Insertar las capturas en el Word (automático)

```bash
pip install python-docx
python docs/insertar_capturas.py docs/APF_1.docx docs/evidencias docs/APF_1_final.docx \
    --repo-url https://github.com/TU_USUARIO/hotel-bello-amanecer
```

El script reemplaza cada recuadro "[Insertar captura de pantalla]" por tus imágenes, deja intactos el título y la fuente de cada figura, y pone la URL del repositorio en la sección 6.4. Si falta alguna imagen, te avisa y deja ese recuadro como estaba.

**¿Prefieres hacerlo a mano?** En Word: borra el recuadro naranja → *Insertar → Imágenes* → ajusta el ancho a 15,9 cm → centra.

Revisa el documento resultante: que cada imagen se lea, que la región `us-east-1` salga en la consola y que **no aparezcan claves ni tokens**.

Sube también la versión final al repositorio:

```bash
git add docs
git commit -m "docs: agregar evidencias y versión final del informe"
git push
```

---

## Parte 9. Apagar todo (no te olvides)

Mientras existan, la NAT Gateway, el ALB y RDS siguen gastando créditos aunque no uses nada.

```bash
./ecs/destroy-services.sh
./infra/destroy.sh
```

Luego revisa en la consola que no queden: **VPC → NAT Gateways**, **EC2 → Load Balancers**, **RDS → Databases**, **EC2 → Instances**. Para la próxima sesión basta con repetir las Partes 3 a 5 (el entorno se recrea desde el código, tal como dice el informe).

---

## Problemas frecuentes

| Síntoma | Qué hacer |
|---|---|
| `bash\r: No such file` / `bad interpreter` al ejecutar un `.sh` | Fin de línea de Windows: `sed -i 's/\r$//' infra/*.sh ecs/*.sh scripts/*.sh` |
| `docker compose` no existe | Prueba `docker-compose` (con guion) o actualiza Docker Desktop |
| Docker: "port is already allocated" | Cierra lo que use los puertos 8080/8081, o `docker compose down` |
| La imagen no compila (Maven o npm) | Copia las últimas 30 líneas del error y pégamelas |
| Servicio ECS en 0/2 tareas | ECS → servicio → *Events*. Casi siempre: imagen no publicada (repetir `push-images.sh`) o nodos aún registrándose (esperar) |
| Target group en *Unhealthy* | Espera 2-3 min (periodo de gracia). Si persiste, mira los logs en **CloudWatch → Log groups → /hba/api-reservas** |
| `ImmutableTag` / la etiqueta ya existe | Normal: el script omite lo que ya está en ECR. Para forzar, haz un commit nuevo (cambia la etiqueta) |
| Los dos nodos se llaman igual (`hba-ecs-node`) | Es normal: un Auto Scaling Group pone el mismo nombre. Si quieres `-a` y `-b`, renómbralos en la consola antes de capturar |
| Cualquier otro error | Copia el mensaje completo (no una foto parcial) y pégamelo |
