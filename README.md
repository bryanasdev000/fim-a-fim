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

Os hostnames `prometheus` e `firebird` foram adicionados ao `/etc/hosts` para facilitar a padronização dos arquivos de configuração, fazendo com que a aplicação e o Grafana encontrem seus respectivos destinos.

## Provisionamento através do Docker

O provisionamento do **Docker** é um pouco mais complexo apesar do *compose-file* não ser tão extenso. Os contêineres **app**, **mongodb** e **grafana** tiveram suas diretivas `command` e/ou `entrypoint` alteradas para executarem seus respectivos arquivos no diretório `twitter-harvester/docker`. São eles `migration.sh`,  `mongo-restore.sh` e `grafana-restore.sh`.

O *Dockerfile* pode assustar um pouco e utiliza uma técnica conhecida como *multi-stage building*, que neste caso descarta a camada de compilação da dependência `luasql-firebird` e `OpenSSL 1.1.1`, aproveitando apenas os binários resultantes, tornando a imagem considerávelmente menor.

# API REST

A aplicação expõe uma API muito simples com 5 *endpoints*:

- GET - */fetch* - Limpa o banco de dados e insere informações atualizadas com base em uma nova pesquisa no Twitter.
- GET - */metrics* - Um exportador do Prometheus criado especialmente para a aplicação, exibe as métricas quantitativas e de latência.
- GET - */top_five* - Exibe os cinco usuários com mais seguidores com base nos dados salvos pela busca feita anteriormente por **/fetch**.
- GET - */tweets_by_hour* - Lista a quantidade de tweets por hora, independente da hashtag com base nos dados salvos pela busca feita anteriormente por **/fetch**.
- GET - */tweets_by_tag_and_location* - Lista os tweets por localização dos usuários e hashtags base nos dados salvos pela busca feita anteriormente por **/fetch**.

Todos os *endpoints* retornam o formato *application/json* com excessão do **/metrics** que por exigência do Prometheus retorna o formato *text*.
