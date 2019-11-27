# Twitter Harvester

Apesar do nome, **Twitter Harvester** é apenas uma exemplo de uma pequena aplicação escrita em [Lua](https://www.lua.org/) com ajuda do framework [Lapis](https://leafo.net/lapis/) e [Vue.js](https://vuejs.org/) que tem como função se conectar ao [Twitter](https://twitter.com/) e extrair os últimos 100 *tweets* e seus usuários com base nas seguintes hashtags:

- openbanking
- apifirst
- devops
- cloudfirst
- microservices
- apigateway
- oauth
- swagger
- raml
- openapis

Essas informações podem então ser sumarizadas através da interface web.

## Objetivo

O objetivo é demonstrar que é possível criar aplicações modernas utilizando **Lua**, uma linguagem de programação brasileira, com ferramentas e conceitos do universo **DevOps**, garantindo a integração de todo o ecossistema responsável pela observabilidade da aplicação.

## Resumo

A aplicação funciona através de um servidor baseado em [nginx](https://nginx.org/) chamado [OpenResty](https://openresty.org).

O **backend** é escrito em **Lua** e fornece a estrutura necessária através de uma API REST para um **SPA** escrito em **Vue.js** e estilizado com [BareCSS](https://github.com/longsien/BareCSS). As informações são coletadas do Twitter através da chamada `/fetch` e então gravadas em um banco de dados [Firebird](https://firebirdsql.org/).

As ações da aplicação, como seus acessos e seus erros, são logadas diretamente no [Graylog](https://www.graylog.org/) através de [gelf](https://docs.graylog.org/en/3.1/pages/gelf.html).

A monitoração é feita pelo [Prometheus](https://prometheus.io/) através da chamada `/metrics` e estas informações são então exibidas através do painel do [Grafana](https://grafana.com/).

## Tecnologias

As tecnologias utilizadas neste projeto estão descritas abaixo:

- Lua - https://www.lua.org/
- Lapis - https://leafo.net/lapis/
- Firebird - https://firebirdsql.org/
- OpenResty - https://openresty.org/
- Vue.js - https://vuejs.org/
- BareCSS - https://github.com/longsien/BareCSS
- Graylog - https://www.graylog.org/
- Prometheus - https://prometheus.io/
- Grafana - https://grafana.com/
- Vagrant - https://www.vagrantup.com/
- Docker - https://www.docker.com/docker-community
- MongoDB - https://www.mongodb.com/ - Exigência do Graylog*
- Elasticsearch - https://www.elastic.co/products/elasticsearch - Exigência do Graylog*

**Obs:** A box configurada no Vagrantfile é um [Debian](https://www.debian.org/) 10.

# Como utilizar

Existem duas formas de provisionar esta aplicação, uma através do Vagrant e outra através do Docker, e independente da forma escolhida é preciso ter uma **conta de desenvolvedor** no Twitter bem como a **key e o secret** de um *developer app*.

É possível obter uma conta de desenvolvedor gratuitamente através do endereço https://developer.twitter.com/ e então seguir o trecho **How to get started with the Twitter API** do seguinte tutorial https://developer.twitter.com/en/docs/basics/getting-started para criar uma *developer app*.

Este *developer app* servirá para fornecer as credenciais, ou seja, o **token** e o **secret** que aplicação necessita para fazer consultas.

Uma vez que esteja em posse do **token** e o **secret** do *developer app*, basta adicioná-los ao arquivo `config.lua` da raíz do projeto:

```lua
config("development", {
        tw_key = 'minha key',
        tw_secret = 'meu secret',
})
```

## Obter os Arquivos

Se você não possui o git, as instruções de instalação podem ser encontradas em https://git-scm.com/book/en/v2/Getting-Started-Installing-Git.

Abra o terminal e clone o projeto:

```bash
git clone https://github.com/hector-vido/fim-a-fim.git twitter-harvester
```

Existem duas formas de provisionar o ambiente, um deles é com uma máquina virtual - **Vagrant** - e o outro através de contêineres - **Docker**. Veja abaixo qual a opção que mais lhe agrada, ambas são iguais em resultado.

## Vagrant

Caso o vagrant não esteja instalado em sua máquina, é possível encontrar instruções de instalação em https://www.vagrantup.com/downloads.html.

Entre no diretório `twitter-harvester/vagrant` e inicie o provisionamento:

```
cd twitter-harvester/vagrant
vagrant up
```

**Obs:** Levará algum tempo pois muitas ferramentas são instaladas e devido a uma dependência do OpenResty a biblioteca OpenSSL 1.1.1 precisa ser compilada.

Ao término do provisionamento, a aplicação poderá ser acessada através do endereço http://192.168.33.10:8080.

As outras ferramentas podem ser acessadas nos seguintes endereços:

- *Graylog* - http://192.168.33.10:9000
- *Prometheus* - http://192.168.33.10:9090
- *Grafana* - http://192.168.33.10:3000

## Docker

Caso o Docker não esteja instalado em sua máquina, é possível encontrar instruções de instalação para o Linux em https://docs.docker.com/install/ e para o Windows em https://docs.docker.com/docker-for-windows/install/.

Além do Docker, a ferramenta **docker-compose** é necessária para provisionar o ambiente, as instruções para instalação pode ser encontrada em https://docs.docker.com/compose/install/.

Entre no diretório `twitter-harvester/docker` e inicie o provisionamento:

```
cd twitter-harvester/docker
docker-compose up
```

**Obs:** Levará algum tempo, pois a imagem do **twitter-harvester** será criada em sua máquina, dinâmicamente através do Dockerfile presente em `twitter-harvester/docker`.

Ao término do provisionamento, a aplicação poderá ser acessada através do endereço http://localhost:8080.

As outras ferramentas podem ser acessadas nos seguintes endereços:

- *Graylog* - http://localhost:9000
- *Prometheus* - http://localhost:9090
- *Grafana* - http://localhost:3000

# Sobre o Provisionamento

Independente da forma escolhida para o provisionamento, em nenhum dos casos será necessário executar um passo extra, a aplicação estará pronta e todas as ferramentas conectadas.

- O banco de dados **Firebird** da aplicação é criado através do script `twitter-harvester/migration.lua`.
- Para a ferramenta **Graylog** um *dump* do MongoDB foi extraído em `twitter-harvester/dumps/mongo-graylog.tar.gz` e acompanha o repositório.
- No caso do **Grafana**, uma cópia do SQLite foi extraída para `twitter-harvester/dumps/grafana.db.gz` e acompanha o repositório. O dashboard utilizado também pode ser encontrado em `twitter-harvester/docs/grafana/twitter-harvester.json`.
- O arquivo de configuração do **Prometheus** pode ser encontrado em `twitter-harvester/docs/prometheus/prometheus.yml`

Para ambos os casos, a biblioteca OpenSSL 1.1.1 precisou ser compilada e copiada para os diretórios do OpenResty.

## Provisionamento através do Vagrant

O provisionamento do **Vagrant** é bastante direto, e pode ser observado através do único arquivo `twitter-harvester/vagrant/provision.sh`.

Logo no início, a senha padrão para o Firebird é configurada em `/etc/firebird/3.0/SYSDBA.password`. As ferramentas são instaladas em sequência, juntamente com a restauração dos *dumps* de cada banco. Uma série de substituições com `sed` são realizadas, de modo a configurar os arquivos conforme a necessidade.

Os hostnames `prometheus`, `graylog` e `firebird` foram adicionados ao `/etc/hosts` para facilitar a padronização dos arquivos de configuração, fazendo com que a aplicação e o Grafana encontrem seus respectivos destinos.

## Provisionamento através do Docker

O provisionamento do **Docker** é um pouco mais complexo apesar do *compose-file* não ser tão extenso. Os contêineres **app**, **mongodb** e **grafana** tiveram suas diretivas `command` e/ou `entrypoint` alteradas para executarem seus respectivos arquivos no diretório `twitter-harvester/docker`. São eles `migration.sh`,  `mongo-restore.sh` e `grafana-restore.sh`.

O *Dockerfile* pode assustar um pouco e utiliza uma técnica conhecida como *multi-stage building*, que neste caso descarta a camada de compilação da dependência `luasql-firebird` e `OpenSSL 1.1.1`, aproveitando apenas os binários resultantes, tornando a imagem considerávelmente menor.

# API REST

A aplicação expõe uma API muito simples com 5 *endpoints*:

- GET - **/fetch** - Limpa o banco de dados e insere informações atualizadas com base em uma nova pesquisa no Twitter.
- GET - **/metrics** - Um exportador do Prometheus criado especialmente para a aplicação, exibe as métricas quantitativas e de latência.
- GET - **/top_five** - Exibe os cinco usuários com mais seguidores com base nos dados salvos pela busca feita anteriormente por **/fetch**.
- GET - **/tweets_by_hour** - Lista a quantidade de tweets por hora, independente da hashtag com base nos dados salvos pela busca feita anteriormente por **/fetch**.
- GET - **/tweets_by_tag_and_location** - Lista os tweets por localização dos usuários e hashtags base nos dados salvos pela busca feita anteriormente por **/fetch**.

Todos os *endpoints* retornam o formato *application/json* com exceção do **/metrics** que por exigência do Prometheus retorna o formato *text*.

# Arquitetura

A arquitetura consiste-se de um backend escrito em **Lua** juntamente com um front-end desenvolvido em **Vue.js**.
O SGDB utilizado é um **Firebird**, e exige uma séria consistência de dados através de constraints.

Os logs da aplicação são enviados diretamente para o **Graylog**, e as métricas são recolhidas pelo **Prometheus**.

## Backend

O backend, escrito em **Lua** com a utilização do framework **Lapis**, funciona através de um *webserver* chamado **OpenResty**. Através de uma série de variáveis de ambiente configuradas em `/etc/openresty/nginx.conf` a aplicação consegue localizar e se comunicar com o banco de dados **Firebird** e o centralizador de logs **Graylog**.

As variáveis são as seguintes:

```ini
env FIREBIRD_HOST=firebird;
env FIREBIRD_USER=app;
env FIREBIRD_PASSWORD=zjgNmeaoENepyDaeq2*vs)x)kbNm8L2J;
env FIREBIRD_DATABASE=luafirebird.fdb;
env GRAYLOG_HOST=graylog;
env GRAYLOG_PORT=12201;
env GRAYLOG_USER=admin;
env GRAYLOG_DASHBOARD=5ddb2b3ba048ab3fe5563fbd;
env GRAYLOG_WIDGET=2a2d492e-500c-4d86-9ce2-3378fe7a9ba0;
env GRAYLOG_PASSWORD=admin;
env GRAYLOG_INPUT=gelf;
```

Através de um arquivo de configuração com a **key** e o **token** obtidos através do Twitter localizado em `/opt/app/config.lua` a aplicação consegue fazer uma busca por tags específicas - *vide início do documento* - puxando no máximo 100 registros para cada hashtag, separando e gravando estes registros no banco de dados.

A obtenção dos dados é descrita mais abaixo.

## Frontend

O front-end é desenvolvido em **Vue.js**, e pode ser acessado consultando a raíz da aplicação em `/`. Trata-se de um SAP - Single Page Application - extremamente simples que utiliza-se de requisições em background através da biblioteca **axion** para garantir uma melhor fluidez da interface.

A estilização é feita por um conjunto CSS **classless** conhecido como **BareCSS**.

## Obtenção dos Dados - Harvesting

Ao chamar o endpoint **/fetch** ou mesmo clicar em **Fetch** na interface web - sendo que esta última apresenta uma confirmação - o backend limpará o banco e fará uma nova busca no Twitter, preenchendo as tabelas com novos dados.

## Banco de Dados

O banco de dados é um Firebird, relacional. Durante a fase de cadastro centenas de campos são descartados e somente os necessários são inseridos, diminuindo a carga de trabalho e armazenamento.

A estrutura do banco é a seguinte:

![DER](/docs/der.svg "Diagrama de Entidade Relacionamento")

# Logging

Durante a execução, a aplicação envia seus logs de acessos, avisos e erros para o **Graylog** através de pequenas chamadas como:

```lua
local b, c, h, s = http.request {
    url = string.format('http://%s:%s/%s', os.getenv('GRAYLOG_HOST'), os.getenv('GRAYLOG_PORT'), os.getenv('GRAYLOG_INPUT')),
    method = 'POST',
    source = ltn12.source.string(payload),
    headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = payload:len()
    }       
}
```

As variáveis de ambiente utilizadas são autoexplicativas, com exceção da `GRAYLOG_INPUT` que faz referência ao tipo de captura criado dentro do **Graylog**.

# Monitoramento

O monitoramento é feito pelo **Prometheus** de 15 em 15 segundos através do endpoint **/metrics**, a chamada deste *endpoint* implica em alguns passos:

1. Uma busca dos dados históricos de acesso do Graylog é realizada
2. A latência dessa busca é calculada
3. É cálculado a latência de obtenção do token de acesso do Twitter
4. Também é calculado a latência da obtenção de 1 registro da busca de Tweets
5. A latência total é calculada
6. Os dados são retornados

Os dados retornados tem o seguinte formato:

```
# HELP twitter_harverster_stats by type
# TYPE twitter_harvester_stats counter
twitter_harvester_stats{type="error"} 0
twitter_harvester_stats{type="warning"} 0
twitter_harvester_stats{type="access"} 2
# HELP twitter_harvester_latency shows latency of various internal calls
# TYPE twitter_harvester_latency gauge
twitter_harvester_latency{name="graylog"} 0.004
twitter_harvester_latency{name="twitter_token"} 0.197
twitter_harvester_latency{name="twitter_search"} 0.226
twitter_harvester_latency{name="api"} 0.427
```

Com base nestes dados coletados, uma pequena *dashboard* foi criada dentro do Grafana para facilitar a visualização.

# Acessando o Graylog


![Graylog View](/docs/graylog/view.png "Visualização dos Últimos Logs")

![Graylog Dashboard](/docs/graylog/dashboard.png "Visualização do Sumário de Requisições, Avisos e Errors")

# Acessando o Grafana

![Dashboard Grafana](/docs/grafana/dashboard.png "Visualização do Estado Geral")
