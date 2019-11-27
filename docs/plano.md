# Plano de Trabalho

## Teste para Engenheiro de Software

Este é um pequeno plano de trabalho que visa organizar, planejar e controlar o progresso nos requisitos e tarefas necessárias para construir uma solução fim à fim envolvendo infraestrutura, desenvolvimento de software, banco de dados, logging e monitoramento.

# Requisitos

1. O software desenvolvido deverá consultar o Twitter para coletar diferentes "hashtags" e armazená-las em um banco de dados.
2. Uma API REST deverá ser criada permitindo a consulta de forma sumarizada, agrupando e totalizando os dados conforme diferentes exigências, expondo métricas de execução.
3. Uma página web deverá consultar a API REST e exibir os dados no navegador.
4. Os logs de execução, erros ou informações da API REST deverão ser guardados em uma ferramenta para gerenciamento, e então sua filtragem deverá ser sumarizada em uma ferramenta de métricas.

# Tecnologias Utilizadas

- Lua 
- VueJS 
- Firebird 
- Graylog 
- Prometheus 
- Docker 
- Vagrant 

**Obs:** Lua e Firebird são tecnologias praticamente inexistentes em aplicações web modernas e nunca utilizadas por mim, por este motivo foram escolhidas.

# Metas
- Dia 1 - Escrever o plano de trabalho, validar a viabilidade do Lua + Firebird e criar repositório 
  - Plano B - Caso Lua e/ou Firebird não atendam as exigências, utilizar PHP e/ou MySQL. 
- Dia 2 - Modelar o banco, desenvolver a aplicação que consulta o Twitter 
- Dia 3 - Escrever as queries para sumarizar os dados 
- Dia 4 - Criar a API REST para expor o resultado das queries 
- Dia 5 - Consumir a API REST através de um SPA com VueJS, exibindo gráficos no navegador 
- Dia 6 - Criar as tratativas e envio de log da aplicação para o Graylog 
- Dia 7 - Criar e/ou configurar o exportador do Prometheus para extrair as métricas da aplicação

# Resultado do Plano

O plano de trabalho foi seguido sem desvios, porém alguns etapas consideradas simples acabaram levando mais tempo. Graças ao período total, foi possível compensar alguns atrasos que, embora não foi o suficiente para entregar antes do tempo, ao menos permitiu a entrega na data esperada.

## Lua e Firebird

A adoção destas duas tecnologias geraram o maior atraso dentro do projeto, como um todo. A linguagem LUA apresentou dificuldades por não fazer parte das ferramentas conhecidas. A falta de alguns módulos nos repositórios e/ou nativos - presentes em outras linguagens, como por exemplo manipulação mais complexa de datas, driver de conexão com banco - além da utilização do Openresty como webserver, com suas dependências compiladas, trouxeram alguns problemas de complexidade não esperados.

O Firebird causou estranhesa pela ausência de alguns recursos comuns em bancos de dados mais populares como MySQL e PostgreSQL, além de uma configuração um tanto quanto exótica. Com os ajustes em algumas partes das queries - fora do padrão ANSI - o banco de dados passou a não ser um problema.

## Vagrant e Docker

O provisionamento nos dois ambientes também foi um problema, apesar de não ser requisito a escolha do Vagrant foi fundamental para concluir o ambiente de forma mais simples, sem precisar tomar os cuidados necessários com o Docker, como persistência e imagens enxutas sem as ferramentas necessárias para utilizar soluções pouco conhecidas.

## Entregas Pequenas

Graças as pequenas tarefas, foi possível conseguir pequenos avanços diários causando a sensação de progresso e evitando o desânimo de grandes períodos de baixa entrega.
