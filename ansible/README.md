# rasp-deploy

Ansible-плейбук для деплоя приложения из GitLab Container Registry в Docker.

Плейбук поднимает:

- docker-сеть `rasp-network`;
- контейнер приложения `rasp-app`;
- контейнер nginx `rasp-nginx`;
- nginx-конфиг из шаблона `templates/nginx-default.conf.j2`;
- опционально certbot для выпуска и продления Let's Encrypt сертификата.
- опционально Datadog Agent как Docker-контейнер;
- генерацию `terraform/terraform.tfvars` из Ansible-переменных.

## Требования

На машине, с которой запускается деплой:

- Ansible;
- установленная коллекция `community.docker`;
- доступ к Ansible Vault с секретами registry.

На целевом сервере:

- Docker;
- пользователь, под которым подключается Ansible, должен иметь доступ к Docker daemon, например через группу `docker`;
- доступные порты `80` и `443`;
- DNS домена должен указывать на этот сервер до выпуска сертификата.

Установка Ansible-коллекций:

```bash
make install
```

## Основные файлы

- `playbook.yml` - основной Ansible playbook.
- `inventory.ini` - inventory с целевыми хостами.
- `group_vars/all.yml` - общие переменные nginx и certbot.
- `group_vars/webservers/vars.yml` - публичные переменные для образов и registry.
- `group_vars/webservers/vault.yml` - секреты Ansible Vault.
- `templates/nginx-default.conf.j2` - шаблон nginx-конфига.
- `templates/terraform.tfvars.j2` - шаблон переменных Terraform.
- `generate-terraform-vars.yml` - playbook для генерации `terraform.tfvars`.
- `templates/.env` - шаблон env-файла приложения, который монтируется в контейнер как `/app/.env.prod`.
- `Makefile` - короткие команды для установки зависимостей, HTTP/HTTPS-деплоя и первичного выпуска сертификата.

## Переменные

### Terraform variables

`terraform.tfvars` можно сгенерировать из Ansible:

```bash
make terraform-vars
```

Публичные значения задаются в `group_vars/all.yml`:

```yaml
terraform_project_name: "Общий проект"
terraform_location: ru-3
terraform_availability_zone: msk-1
terraform_ssh_public_key: "ssh-ed25519 AAAA..."
terraform_dns_zone_name: "example.com"
terraform_dns_record_name: "rasp"
```

Секрет БД лучше хранить в vault:

```yaml
vault_terraform_db_password: "change-me"
```

### Docker registry и образы

Эти переменные берутся из `group_vars/webservers/vars.yml` и обычно ссылаются на `vault.yml`:

```yaml
registry_url: "{{ vault_registry_url }}"
image_nginx: "{{ vault_image_nginx }}"
image_app: "{{ vault_image_app }}"
registry_user: "{{ vault_registry_user }}"
registry_password: "{{ vault_registry_token }}"
```

### Datadog

Datadog Agent запускается на каждом host из inventory, если включить флаг:

```bash
make deploy EXTRA_ARGS="-e datadog_enabled=true"
```

В `group_vars/webservers/vault.yml` должен быть API key:

```yaml
vault_datadog_api_key: ""
```

Остальные настройки находятся в `group_vars/all.yml`:

```yaml
datadog_site: datadoghq.eu
datadog_env: production
datadog_service: rasp
datadog_logs_enabled: true
datadog_apm_enabled: false
```

Контейнеры `rasp-app`, `rasp-front` и `rasp-nginx` получают Datadog service/env/version labels.

### Env-файл приложения

Шаблон env-файла находится в `templates/.env`:

```dotenv
YA_RASP_API_KEY="{{ app_ya_rasp_api_key }}"

DATABASE_URL="{{ app_database_url }}"

APP_SYNC_STATION_LIST={{ app_sync_station_list }}
```

Плейбук записывает файл на хост и монтирует его в контейнер приложения:

```yaml
app_host_env_dir: "{{ ansible_user_dir }}/.config/rasp/app"
app_container_owner_uid: 1000
app_container_owner_gid: 1000
```

На хосте файл создается с правами `0664`, root-права не нужны. В контейнере он доступен как `/app/.env.prod`. Перед генерацией нового файла плейбук удаляет существующий `.env.prod`, затем создает его заново из шаблона.

После запуска `rasp-app` плейбук выставляет владельца всего содержимого `/app` в контейнере:

```bash
chown -R 1000:1000 /app
```

Если env-файл был удален/изменен или владелец `/app` был исправлен, `rasp-app` автоматически перезапускается. `.env.prod` монтируется writable, чтобы команда `chown -R` могла обработать весь `/app`, включая bind-mounted env-файл.

Значения берутся из секретов Ansible Vault через `group_vars/webservers/vars.yml`:

```yaml
app_ya_rasp_api_key: "{{ vault_ya_rasp_api_key }}"
app_database_url: "{{ vault_database_url }}"
app_sync_station_list: "{{ vault_app_sync_station_list }}"
```

В `group_vars/webservers/vault.yml` должны быть значения:

```yaml
vault_ya_rasp_api_key: ""
vault_database_url: "postgresql://docker-rasp:*@docker-rasp-postgres:5432/app?serverVersion=18&charset=utf8"
vault_app_sync_station_list: 1
```

### Nginx

Задаются в `group_vars/all.yml`:

```yaml
app_domain: rasp.asharikov.ru
nginx_domain: "{{ app_domain }}"
nginx_php_host: php
nginx_ssl_enabled: false
nginx_host_config_dir: "{{ ansible_user_dir }}/.config/rasp/nginx/conf.d"
nginx_host_config_file: "{{ nginx_host_config_dir }}/default.conf"
nginx_container_config_file: /etc/nginx/conf.d/default.conf
```

- `app_domain` - основной домен приложения. Используется для nginx и как домен сертификата по умолчанию.
- `nginx_domain` - домен для `server_name` и пути к сертификату.
- `nginx_php_host` - имя upstream PHP-FPM контейнера внутри docker-сети. По умолчанию `php`, потому что `rasp-app` получает network alias `php`.
- `nginx_ssl_enabled` - включает HTTPS server block и редирект HTTP -> HTTPS.
- `nginx_host_config_dir` - директория на хосте, куда Ansible пишет nginx-конфиг. По умолчанию используется домашняя директория пользователя Ansible, root-права не требуются.
- `nginx_container_config_file` - путь внутри nginx-контейнера, куда монтируется конфиг.

### Certbot

```yaml
certbot_enabled: false
certbot_image: certbot/certbot:latest
certbot_email: ""
certbot_domains:
  - "{{ app_domain }}"
certbot_domain_list: >-
  {{
    (certbot_domains | from_yaml)
    if (certbot_domains is string and (certbot_domains | trim | regex_search('^\[')))
    else ([certbot_domains] if certbot_domains is string else certbot_domains)
  }}
certbot_staging: false
certbot_dns_servers: []
certbot_network_mode: host
certbot_webroot_path: /var/www/certbot
certbot_letsencrypt_volume: rasp-letsencrypt
certbot_webroot_volume: rasp-certbot-webroot
```

- `certbot_enabled` - включает создание certbot volume, запуск certbot и cron для renew.
- `certbot_email` - email для Let's Encrypt. Заполните один раз в `group_vars/all.yml`, чтобы не передавать его при каждом запуске.
- `certbot_domains` - список доменов для сертификата.
- `certbot_domain_list` - нормализованный список доменов. Нужен, чтобы случайно переданная строка не разбиралась Jinja как набор символов.
- `certbot_staging` - использовать staging-сервер Let's Encrypt для тестов.
- `certbot_dns_servers` - список DNS-серверов для certbot-контейнера, если Docker DNS на сервере не резолвит внешние домены.
- `certbot_network_mode` - Docker network mode для certbot-контейнера. По умолчанию `host`, потому что certbot не должен общаться с nginx по docker-сети, а host network обходит проблемы DNS в Docker bridge.
- `certbot_webroot_path` - путь webroot внутри контейнеров nginx и certbot.
- `certbot_letsencrypt_volume` - Docker volume с сертификатами.
- `certbot_webroot_volume` - Docker volume для ACME HTTP-01 challenge.

## Первый выпуск сертификата

Перед выпуском сертификата:

1. DNS домена должен указывать на целевой сервер.
2. Порт `80` должен быть доступен снаружи.
3. `nginx_ssl_enabled` должен быть `false`, потому что сертификата еще нет.

Один раз заполните постоянные значения в `group_vars/all.yml`:

```yaml
app_domain: rasp.asharikov.ru
certbot_email: admin@example.com
certbot_domains:
  - "{{ app_domain }}"
```

Для нескольких доменов:

```yaml
app_domain: rasp.asharikov.ru
certbot_email: admin@example.com
certbot_domains:
  - rasp.asharikov.ru
  - www.rasp.asharikov.ru
```

После этого первичный выпуск сертификата запускается без ввода домена и email:

```bash
make certbot-init
```

Что произойдет:

- Ansible создаст docker-сеть.
- Запишет nginx-конфиг без HTTPS server block.
- Запустит nginx на `80` и `443`.
- Смонтирует webroot volume в nginx.
- Запустит контейнер `certbot/certbot` с `certonly --webroot`.
- Сохранит сертификаты в Docker volume `rasp-letsencrypt`.
- Добавит cron для автоматического продления.

После успешного выпуска сертификата включите HTTPS отдельным деплоем:

```bash
make deploy-https
```

Обычный `make deploy` использует значение `nginx_ssl_enabled` из `group_vars/all.yml`. Если там оставлено `false`, nginx поднимется только с HTTP server block, даже если порт `443` проброшен Docker-контейнером. В этом случае HTTPS-запросы не попадут в логи nginx и приложения.

Альтернативно можно один раз включить HTTPS в переменных:

```yaml
nginx_ssl_enabled: true
```

После этого обычный `make deploy` будет деплоить HTTPS-конфиг.

Для теста без расходования production лимитов Let's Encrypt:

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass \
  -e certbot_enabled=true \
  -e certbot_staging=true
```

Если certbot падает с ошибкой вида `Failed to resolve 'acme-v02.api.letsencrypt.org'`, проблема в DNS внутри контейнера или Docker daemon на сервере. В этом случае можно явно передать DNS-серверы:

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass \
  -e certbot_enabled=true \
  -e '{"certbot_dns_servers":["1.1.1.1","8.8.8.8"]}'
```

Через `make certbot-init`:

```bash
make certbot-init \
  EXTRA_ARGS="-e '{\"certbot_dns_servers\":[\"1.1.1.1\",\"8.8.8.8\"]}'"
```

По умолчанию certbot запускается в сетевом режиме хоста:

```bash
make certbot-init
```

Если certbot все равно падает с DNS-ошибкой, сравните DNS на хосте и внутри контейнера:

```bash
getent hosts acme-v02.api.letsencrypt.org
curl -I https://acme-v02.api.letsencrypt.org/directory
docker run --rm --network host certbot/certbot:latest \
  certbot register --dry-run --agree-tos --email test@example.com --no-eff-email
```

Если первые две команды работают, а команда в контейнере нет, проблема в Docker runtime или образе certbot на сервере.

## Включение HTTPS после выпуска сертификата

После успешного выпуска сертификата нужно включить HTTPS-конфиг:

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass \
  -e nginx_ssl_enabled=true
```

После этого nginx будет использовать:

```text
/etc/letsencrypt/live/rasp.asharikov.ru/fullchain.pem
/etc/letsencrypt/live/rasp.asharikov.ru/privkey.pem
```

Путь `/etc/letsencrypt` находится внутри контейнера nginx и монтируется из Docker volume `rasp-letsencrypt`.

## Обычный деплой

Если сертификат уже получен, можно зафиксировать постоянные значения в `group_vars/all.yml`:

```yaml
app_domain: rasp.asharikov.ru
nginx_domain: "{{ app_domain }}"
nginx_ssl_enabled: true
nginx_php_host: php
certbot_email: admin@example.com
certbot_domains:
  - "{{ app_domain }}"
```

После этого обычный деплой:

```bash
make deploy
```

Если не хочется менять `group_vars/all.yml`, можно передавать переменные при запуске:

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass \
  -e nginx_ssl_enabled=true
```

## Автоматическое продление

Когда `certbot_enabled=true`, плейбук добавляет cron-задачу:

```bash
docker run --rm \
  --network host \
  --dns 1.1.1.1 \
  --dns 8.8.8.8 \
  -v rasp-letsencrypt:/etc/letsencrypt \
  -v rasp-certbot-webroot:/var/www/certbot \
  certbot/certbot:latest renew --webroot --webroot-path /var/www/certbot \
  && docker restart rasp-nginx
```

Задача запускается каждый день в `03:17`.

Для повторной установки cron можно снова выполнить `make certbot-init` с теми же переменными.

## Работа с Vault

Зашифровать vault-файл:

```bash
make vault-encrypt
```

Отредактировать vault-файл:

```bash
make vault-edit
```

Обычный деплой запрашивает пароль vault:

```bash
make deploy
```

## Проверка синтаксиса playbook

В обычной системе:

```bash
ansible-playbook -i inventory.ini playbook.yml --syntax-check
```

Если окружение не дает Ansible писать в `~/.ansible/tmp`, можно указать временные директории:

```bash
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local \
ANSIBLE_REMOTE_TEMP=/tmp/ansible-remote \
ansible-playbook -i inventory.ini playbook.yml --syntax-check
```

## Важные замечания

- Сертификат выпускается через HTTP-01 challenge, поэтому домен должен быть доступен по HTTP на порту `80`.
- `nginx_ssl_enabled=true` стоит включать только после того, как сертификат уже существует в `rasp-letsencrypt`.
- `nginx_php_host` должен совпадать с именем или alias контейнера PHP-FPM в docker-сети. Сейчас приложение получает alias `php`.
- Конфиг nginx пишется на хост в `nginx_host_config_file`, а затем монтируется в контейнер как `nginx_container_config_file`.
- Env-файл приложения пишется на хост в `app_host_env_file`, а затем монтируется в контейнер как `/app/.env.prod`.
- Перед генерацией env-файла плейбук удаляет старый `.env.prod`. После удаления или изменения env-файла плейбук перезапускает `rasp-app`, потому что приложение обычно читает env только на старте процесса.
- После запуска app-контейнера плейбук приводит владельца всего содержимого `/app` к `1000:1000` и перезапускает `rasp-app`, если права были изменены.
- Плейбук рассчитан на запуск без root-прав на сервере. Поэтому nginx-конфиг пишется в домашнюю директорию пользователя Ansible, а не в `/opt` или `/etc`.
- Ошибка `Failed to resolve 'acme-v02.api.letsencrypt.org'` означает проблему DNS у certbot-контейнера, а не проблему с DNS-записью вашего домена.
- Если `certbot_dns_servers` не помогает, попробуйте `certbot_network_mode: host`. Если и это не помогает, проверяйте DNS и исходящий HTTPS на сервере.
- Если меняется `nginx_domain`, сертификат нужно выпустить для нового домена.
