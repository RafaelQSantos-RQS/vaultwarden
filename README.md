# Vaultwarden: Gestor de Senhas Self-Hosted com PostgreSQL

<p align="center"\>
<img src="https://raw.githubusercontent.com/dani-garcia/vaultwarden/a2ad1dc7c3d28834749d4b14206838d795236c27/resources/vaultwarden-logo-white.svg" width="auto" height="150px" alt="Vaultwarden Logo"\>
</p\>

## 🎯 Visão Geral

Este projeto implanta uma instância do **Vaultwarden**, um servidor de senhas leve e de código aberto, compatível com os clientes oficiais do Bitwarden. A solução foi projetada para ser robusta e segura, utilizando um banco de dados **PostgreSQL** dedicado e se integrando perfeitamente a uma infraestrutura on-premise gerenciada via Traefik.

A implantação de um gerenciador de senhas é uma tarefa de **alta responsabilidade**. Este guia assume que o operador entende os riscos e seguirá as melhores práticas de segurança e manutenção.

## 🏗️ Arquitetura e Decisões de Design Críticas

A arquitetura desta solução foi pensada com um foco principal: **segurança em camadas**.

```text
INTERNET ──> TRAEFIK ──> [Rede 'web'] ──> VAULTWARDEN SERVER ──> [Rede 'internal'] ──> POSTGRESQL DB
                                                                                        (Isolado)
```

1. **Segregação de Serviços:** A aplicação (Vaultwarden) e o banco de dados (PostgreSQL) rodam em contêineres separados. Isso isola as responsabilidades e os possíveis pontos de falha. Se o contêiner da aplicação for comprometido, o acesso direto ao banco de dados não é imediato.

2. **Segregação de Rede (Ponto Crucial):** A comunicação entre os serviços é estritamente controlada por duas redes distintas:

      * **`web` (externa):** Apenas o contêiner do Vaultwarden está nesta rede. É por onde ele recebe o tráfego do proxy Traefik.
      * **`internal` (ponte):** O contêiner do PostgreSQL vive *exclusivamente* nesta rede. Ele não tem nenhuma rota para o mundo exterior ou para outros serviços da sua infraestrutura. Apenas o Vaultwarden pode falar com ele. **Isso é fundamental para a segurança.**

3. **Persistência de Dados Robusta:**

      * Os dados de configuração do Vaultwarden (anexos, chaves, etc.) são persistidos em um *bind mount* local (`./vw-data`). Isso facilita o acesso para backups.
      * Os dados do PostgreSQL são armazenados em um *volume Docker externo* (`vaultwarden-pgdata`), o padrão da indústria para gerenciar dados de bancos de dados em contêineres.

4. **Gestão Padronizada via `Makefile`:** O ciclo de vida da aplicação é gerenciado por um `Makefile`, garantindo consistência e simplicidade nas operações de deploy e manutenção.

## ✅ Pré-requisitos

* Docker Engine e Docker Compose.
* Um shell compatível com `bash`.
* Uma instância do Traefik já rodando e conectada à rede `web`.

## 🚀 Configuração e Deploy

### 1\. Clone o Repositório

```bash
cd /srv # Ou seu diretório de projetos
git clone https://github.com/RafaelQSantos-RQS/vaultwarden
cd vaultwarden
```

### 2\. Prepare o Ambiente

Execute o `Makefile` para criar os recursos necessários (rede, volume) e o seu arquivo de configuração.

```bash
make setup
```

O comando irá criar o arquivo `.env` a partir do template (`.env.template`) e parar, exigindo sua intervenção.

### 3\. Edite o Arquivo `.env` (Passo Mandatório)

Abra o arquivo `.env` e configure **cuidadosamente** as seguintes variáveis:

* **`HOSTNAME`**: O domínio completo pelo qual você acessará o Vaultwarden.
* **Credenciais do PostgreSQL**: Mude `POSTGRES_USER` e, principalmente, `POSTGRES_PASSWORD` para valores complexos e únicos.
* **`ADMIN_TOKEN`**: **Este é um passo de segurança crítico.** O token no template é um exemplo. Gere um novo token seguro (por exemplo, com `openssl rand -base64 48`) e o proteja. Este token dá acesso à página de administração do Vaultwarden em `/admin`. Sem ele, a página fica desativada.
* **Configurações de SMTP**: Para que o Vaultwarden possa enviar e-mails (verificação de conta, convites), configure as variáveis `SMTP_*`.
* **`SIGNUPS_ALLOWED`**: Após criar seu primeiro usuário, é fortemente recomendado mudar esta variável para `false` para impedir registros públicos não autorizados.

### 4\. Inicie os Serviços

Após configurar e salvar o `.env`, suba a stack:

```bash
make up
```

Os contêineres do Vaultwarden e do PostgreSQL serão iniciados. O Traefik irá detectar o serviço e o expor no domínio configurado.

## 🛡️ Segurança e Manutenção

### Backup: Sua Responsabilidade Primária

**Se você perder os dados, perderá todas as suas senhas. Não há recuperação.** Uma estratégia de backup regular não é opcional.

Você precisa fazer backup de **dois locais distintos**:

1. **O diretório de dados do Vaultwarden:** A pasta `./vw-data` contém todos os anexos e configurações da aplicação.
2. **O volume do PostgreSQL:** O volume `vaultwarden-pgdata` (ou o nome que você configurou) contém o banco de dados com todas as senhas criptografadas.

Use uma ferramenta como `docker cp` ou monte o volume em um contêiner temporário para copiar os dados do banco, ou utilize ferramentas específicas de backup do PostgreSQL como `pg_dump`. Armazene seus backups em um local seguro e criptografado.

### Atualizações

Para atualizar a aplicação, puxe a nova imagem e reinicie o serviço:

```bash
# Atualize a tag da versão no seu arquivo .env
nano .env

# Puxe a nova imagem
make pull

# Reinicie a stack para aplicar a nova versão
make restart
```

## 🧰 Comandos do `Makefile`

```bash
make help      # Mostra todos os comandos
make setup     # Prepara o ambiente
make up        # Inicia os contêineres
make down      # Para e remove os contêineres
make restart   # Reinicia os contêineres
make logs      # Acompanha os logs em tempo real
make status    # Verifica o status dos contêineres
```

## 💬 Contato e Contribuições

Este projeto é mantido como parte do meu portfólio. Se encontrar problemas ou tiver sugestões, abra uma **Issue**. Para outros assuntos, encontre-me no [LinkedIn](www.linkedin.com/in/rafael-queiroz-santos).
