Plano de Trabalho
Teste para Engenheiro de Software
Este é um pequeno plano de trabalho que visa organizar, planejar e controlar o progresso nos requisitos e tarefas necessárias para construir uma solução fim à fim envolvendo infraestrutura, desenvolvimento de software, banco de dados, logging e monitoramento.
Requisitos
O software desenvolvido deverá consultar o Twitter para coletar diferentes “hashtags” e armazená-las em um banco de dados.
Uma API REST deverá ser criada permitindo a consulta de forma sumarizada, agrupando e totalizando os dados conforme diferentes exigências, expondo métricas de execução.
Uma página web deverá consultar a API REST e exibir os dados no navegador.
Os logs de execução, erros ou informações da API REST deverão ser guardados em uma ferramenta para gerenciamento, e então sua filtragem deverá ser sumarizada em uma ferramenta de métricas.
Tecnologias Utilizadas
    • Lua 
    • VueJS 
    • Firebird 
    • Graylog 
    • Prometheus 
    • Docker 
    • Vagrant 
Obs: Lua e Firebird são tecnologias praticamente inexistentes em aplicações web modernas e nunca utilizadas por mim, por este motivo foram escolhidas.
Metas
    • Dia 1 - Escrever o plano de trabalho, validar a viabilidade do Lua + Firebird e criar repositório 
        ◦ Plano B - Caso Lua e/ou Firebird não atendam as exigências, utilizar PHP e/ou MySQL. 
    • Dia 2 - Modelar o banco, desenvolver a aplicação que consulta o Twitter 
    • Dia 3 - Escrever as queries para sumarizar os dados 
    • Dia 4 - Criar a API REST para expor o resultado das queries 
    • Dia 5 - Consumir a API REST através de um SPA com VueJS, exibindo gráficos no navegador 
    • Dia 6 - Criar as tratativas e envio de log da aplicação para o Graylog 
    • Dia 7 - Criar e/ou configurar o exportador do Prometheus para extrair as métricas do Graylog
