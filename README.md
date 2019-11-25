# Twitter Harvester

Apesar do nome, **Twitter Harvester** é apenas uma exemplo de uma pequena aplicação escrita em [Lua](https://www.lua.org/) e [Vue.js](https://vuejs.org/) que tem como função se conectar ao [Twitter](https://twitter.com/) e extrair os últimos 100 *tweets* e seus usuários com base nas seguintes hashtags:

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

É possível obter uma conta de desenvolvedor gratuitamente através do endereço https://developer.twitter.com/ e então seguir o seguinte tutorial https://developer.twitter.com/en/docs/basics/getting-started para criar uma *developer app*.

Este *developer app* servirá para fornecer as credenciais, ou seja, o **token** e o **secret** que aplicação necessita para fazer consultas.

Uma vez com o **token** e o **secret** do *developer app*, basta adicioná-los ao arquivo `config.lua` da raíz do projeto:

```lua
config("development", {
        tw_key = 'minha key',
        tw_secret = 'meu secret',
        graylog_dashboard = '5ddb2b3ba048ab3fe5563fbd',
        graylog_widget = '2a2d492e-500c-4d86-9ce2-3378fe7a9ba0'
})
```

Os valores referentes ao Graylog não precisam ser alterados pois esses identificadores estão fixados no banco de dados que será restaurado durante o provisionamento.

## Vagrant

Caso o vagrant não esteja instalado em sua máquina, é possível encontrar instruções de instalação em https://www.vagrantup.com/downloads.html.

Abra o terminal e clone o projeto:

```bash
git clone https://github.com/hector-vido/fim-a-fim.git twitter-harvester
```

Entre no diretório `twitter-harvester/vagrant` e inicie o provisionamento:

```
cd twitter-harvester/vagrant
vagrant up
```

**Obs:** Levará algum tempo pois muitas ferramentas são instaladas e devido a uma dependência do OpenResty a biblioteca OpenSSL 1.1.1 precisa ser compilada.

Ao término do provisionamento, a aplicação poderá ser acessada através do endereço http://192.168.33.10:8080.

## Docker
