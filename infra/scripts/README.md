# Bennu API sem Docker

O servidor pode correr o Bennu Core API diretamente como serviço `systemd`.

## Instalação inicial

Na máquina servidora, a partir de um clone do repositório:

```sh
cd ~/bennu
git pull origin main
sudo sh infra/scripts/install-api.sh
```

O instalador instala Python/git, cria o utilizador de sistema `bennu`, cria `/opt/bennu`, cria o ambiente virtual Python, instala as dependências, prepara a base SQLite em `/var/lib/bennu/bennu.db`, aplica as migrations e inicia `bennu-api` na porta 8000.

Verificar:

```sh
curl http://127.0.0.1:8000/health
systemctl status bennu-api --no-pager
ss -lntp | grep 8000
```

## Atualizar

Depois de novos commits:

```sh
cd ~/bennu
git pull origin main
sudo sh infra/scripts/update-api.sh
```

## Telemóvel

No cliente Android, em **Definições**, colocar:

```text
http://IP-DO-SERVIDOR:8000
```

Não usar `localhost` ou `127.0.0.1`: no telemóvel isso aponta para o próprio telemóvel. O cliente consulta `/health` e `/api/v1/mobile/overview`, pelo que os números apresentados no painel vêm da API real.

Para produção, preferir um domínio HTTPS e reverse proxy.
