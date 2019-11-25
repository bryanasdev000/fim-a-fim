# Exemplos

Estes scripts demonstrar como fazer consultas no Twitter e enviar logs para o Graylog através de **shell** e **lua**.

Antes de executá-los é preciso possuír uma **conta de desenvolvedor** no Twitter além de um *developer app*.

## Como utilizar

Exporte as duas variáveis de ambientes `TW_KEY` e `TW_SECRET` com seus respectivos valores:

```bash
export TW_KEY='key123'
export TW_SECRET='secretabc'
```

E então basta executar qualquer um dos scripts. No caso do Graylog, lembre-se de configurar o **input GELF HTTP** para a porta **12201** utilizada nos scripts. 

## Shell

	bash twitter.sh

## Lua

	lua twitter.lua
