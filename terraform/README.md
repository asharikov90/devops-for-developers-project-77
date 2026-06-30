# Timeweb Cloud Terraform

Terraform-конфигурация восстановлена по скриншотам панели Timeweb Cloud.

## Что описано

- VPC `rasp-network` с подсетью `192.168.0.0/24`.
- VM `rasp-vds`: Ubuntu 26.04, `1 CPU`, `1 GB RAM`, `15 GB NVMe`, `1000 Мбит/с`, private IP `192.168.0.5`.
- VM `rasp-vds-2`: второй backend с теми же параметрами, private IP `192.168.0.7`.
- Load Balancer `rasp-lb`: HTTP/HTTPS балансировка на оба backend-сервера.
- Опциональная DNS A-запись в существующей Timeweb DNS-зоне на публичный IP балансировщика.
- PostgreSQL `rasp-postgres`: PostgreSQL 17-compatible preset, `1 CPU`, `1 GB RAM`, `8 GB NVMe`, private network, user `gen_user`, databases `app` and `default_db`.
- Firewall `VM`: inbound `22`, `80`, `443`, outbound TCP для обоих серверов.
- Firewall `Postgres`: inbound `5432`.

Мониторинг `rasp-check` не добавлен: в Terraform-провайдере Timeweb Cloud нет ресурса для мониторинга доступности.

Локация по умолчанию — `ru-3`: в текущем API Timeweb именно в ней доступен PostgreSQL-пресет `Cloud DB 1/1/8`, соответствующий скриншотам.

## Подготовка

```sh
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Заполните `terraform.tfvars`: `ssh_public_key` и `db_password`.

Если DNS-зона управляется в Timeweb Cloud, заполните:

```hcl
dns_zone_name   = "example.com"
dns_record_name = "rasp"
```

Если DNS создавать не нужно, оставьте обе переменные пустыми.

Провайдер читает API-токен из переменной окружения:

```sh
export TWC_TOKEN="..."
```

Не записывайте `TWC_TOKEN` в `terraform.tfvars`: этот файл предназначен для переменных проекта, а токен провайдера безопаснее передавать через окружение или секреты CI/CD.

## Создание новой инфраструктуры

```sh
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

После `apply` можно обновить Ansible inventory из output:

```sh
terraform output -raw ansible_inventory > ../ansible/inventory.ini
```

Для backend используется S3-compatible remote state. Скопируйте пример и заполните bucket/ключи:

```sh
cp backend.hcl.example backend.hcl
```

`backend.hcl` не нужно коммитить: секреты и локальные `.tfvars` уже исключены в `.gitignore`.

## Подключение существующей инфраструктуры

Если нужно взять под управление уже созданные в панели ресурсы, сначала получите numeric ID из URL каждого объекта в Timeweb Cloud и выполните импорты:

```sh
terraform import 'twc_server.rasp_vds' '<server_id>'
terraform import 'twc_server.rasp_vds_2' '<second_server_id>'
terraform import 'twc_vpc.rasp' '<vpc_id>'
terraform import 'twc_lb.rasp' '<load_balancer_id>'
terraform import 'twc_lb_rule.http' '<load_balancer_http_rule_id>'
terraform import 'twc_lb_rule.https' '<load_balancer_https_rule_id>'
terraform import 'twc_database_cluster.rasp_postgres' '<database_cluster_id>'
terraform import 'twc_database_instance.app' '<app_database_id>'
terraform import 'twc_database_instance.default_db' '<default_db_database_id>'
terraform import 'twc_database_user.gen_user' '<database_user_id>'
terraform import 'twc_firewall.vm' '<vm_firewall_id>'
terraform import 'twc_firewall_rule.vm_ingress_https' '<vm_https_rule_id>'
terraform import 'twc_firewall_rule.vm_ingress_http' '<vm_http_rule_id>'
terraform import 'twc_firewall_rule.vm_ingress_ssh' '<vm_ssh_rule_id>'
terraform import 'twc_firewall_rule.vm_egress_tcp' '<vm_egress_tcp_rule_id>'
terraform import 'twc_firewall.postgres' '<postgres_firewall_id>'
terraform import 'twc_firewall_rule.postgres_ingress' '<postgres_ingress_rule_id>'
```

Если DNS-запись уже существует и управляется в Timeweb, импортируйте ее отдельно:

```sh
terraform import 'twc_dns_rr.app[0]' '<dns_rr_id>'
```

После импорта выполните:

```sh
terraform plan
```

Если план показывает пересоздание из-за полей, которые Timeweb API не возвращает или возвращает иначе, нужно точечно подстроить значения в `.tf` файлах под импортированное состояние.
