install:
	ansible-galaxy install -r requirements.yml

deploy:
	ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass $(EXTRA_ARGS)

deploy-https:
	ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass -e nginx_ssl_enabled=true $(EXTRA_ARGS)

certbot-init:
	ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass -e certbot_enabled=true $(EXTRA_ARGS)

vault-encrypt:
	ansible-vault encrypt group_vars/webservers/vault.yml

vault-edit:
	ansible-vault edit group_vars/webservers/vault.yml
