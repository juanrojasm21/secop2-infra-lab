
## Primeros pasos

### 1. Ejecutar bootstrap (solo la primera vez)

```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

### 2. Inicializar Terraform

```bash
terraform init
```

### 3. Desplegar

```bash
terraform apply -var-file="dev.tfvars" -var="db_password=TuPassword"
```

### 4. Destruir al terminar

```bash
terraform destroy -var-file="dev.tfvars" -var="db_password=TuPassword"
