No Minha loja, vou implementado uma nova tela, a tela de balcão. Essa tela servirá para os pedidos feitos, via totem, pelo apk, serão salvos nessa tela.

Preciso que você analise o projeto Minha loja, como foi feito toda a funcionalidade do Delivery, como salva os pedidos feitos via link.

No banco de dados, foi criado as tabelas que você deve salvar os pedidos feitos, via apk, no totem, são elas: balcao_pedido, balcao_pedido_item, e se o pedido tiver algum modificador cadastrado, salvará nessas 2 mais a tabela balcao_pedido_item_modificador. Deverá salvar também na tabela de fila impressão, nela salvará os pedidos para fazer a impressão.# Integração Cardápio → Balcão do Minha Loja

## 1. Objetivo

Esta integração permite que um pedido de atendimento no balcão, criado pelo
Cardápio, seja registrado no módulo **Balcão** do Minha Loja.

Ao criar o pedido pela API, o Minha Loja executa tudo em uma única transação:

1. gera o número do pedido;
2. cria o pedido com status `EM_PREPARO`;
3. valida e grava os itens e modificadores;
4. calcula preços e totais usando o cadastro atual do Minha Loja;
5. registra o histórico da criação;
6. separa os itens por setor;
7. insere os comandos correspondentes em `fila_impressao`.

O Cardápio **não deve inserir diretamente** nas tabelas do Balcão nem em
`fila_impressao`.

## 2. URL base

Substitua a URL abaixo pelo endereço do backend do Minha Loja:

```text
https://apiminhaloja.leantechautomacao.com.br
```

Todos os caminhos documentados a seguir são relativos a essa URL.

## 3. Consulta do cardápio

As rotas de consulta do cardápio são públicas e recebem a empresa pela query
string.

### 3.1 Categorias

```http
GET /api/v1/menu/categories?empresa_id=1
```

Resposta:

```json
{
  "data": [
    {
      "id": 10,
      "nome": "Bebidas",
      "foto_url": null
    }
  ]
}
```

### 3.2 Produtos e modificadores

```http
GET /api/v1/menu/products?empresa_id=1
```

A resposta contém:

- `id` do produto;
- nome, descrição, preço, foto e categoria;
- grupos de modificadores vinculados ao produto;
- `id`, nome e valor adicional de cada modificador;
- quantidades mínimas e máximas configuradas no grupo.

Os IDs devolvidos por essa rota devem ser usados na criação do pedido.

Exemplo resumido:

```json
{
  "data": [
    {
      "id": 123,
      "nome": "AÇAÍ 500ML",
      "inf_adicionais": "Copo de 500 ml",
      "vr_venda": 22.0,
      "foto_url": null,
      "categoria_id": 10,
      "is_ativo": true,
      "produto_grupo_modificador": [
        {
          "ordem": 1,
          "is_obrigatorio": false,
          "grupo_modificador": {
            "id": 7,
            "nome": "Complementos",
            "tipo": "MULTIPLA_ESCOLHA",
            "qtd_min": 0,
            "qtd_max": 3,
            "grupo_modificador_item": [
              {
                "id": 45,
                "nome": "Leite condensado",
                "vr_adicional": 2.0,
                "ordem": 1
              }
            ]
          }
        }
      ]
    }
  ]
}
```

## 4. Autenticação atual

As rotas dedicadas do Balcão exigem autenticação.

### 4.1 Login

```http
POST /api/v1/auth/login
Content-Type: application/json
```

```json
{
  "usuario": "integracao-cardapio",
  "senha": "SENHA"
}
```

Também é possível informar o e-mail no campo `email`.

Resposta resumida:

```json
{
  "token": "TOKEN-JWT",
  "expires_in": 3600,
  "session": {
    "usuario": {
      "user_id": "ID-DO-USUARIO",
      "empresa_id": 1
    }
  }
}
```

Nas rotas protegidas, envie:

```http
Authorization: Bearer TOKEN-JWT
```

O usuário de integração precisa estar:

- ativo;
- vinculado à mesma empresa enviada no pedido;
- com perfil ativo;
- autorizado com `balcao.incluir`;
- em empresa com o módulo `balcao` habilitado.

## 5. Criação do pedido de Balcão

Esta é a rota principal da integração:

```http
POST /api/v1/balcao/orders
Authorization: Bearer TOKEN-JWT
Content-Type: application/json
```

Payload:

```json
{
  "empresa_id": 1,
  "pessoa_id": null,
  "cliente_nome": "Leandro",
  "observacao": "Cliente aguardando no balcão",
  "usuario_id": "ID-DO-USUARIO-DE-INTEGRACAO",
  "items": [
    {
      "produto_id": 123,
      "quantidade": 2,
      "observacao": "Sem gelo",
      "modifiers": [
        {
          "grupo_modificador_item_id": 45,
          "quantidade": 1
        }
      ]
    },
    {
      "produto_id": 124,
      "quantidade": 1,
      "observacao": "",
      "modifiers": []
    }
  ]
}
```

### 5.1 Campos do pedido

| Campo | Obrigatório | Descrição |
| --- | --- | --- |
| `empresa_id` | Sim | Empresa do Minha Loja |
| `pessoa_id` | Não | Cliente já cadastrado no Minha Loja |
| `cliente_nome` | Não | Nome ou identificação para chamar o cliente |
| `observacao` | Não | Observação geral do pedido |
| `usuario_id` | Não | Identificador do usuário de integração |
| `items` | Sim | Lista com pelo menos um item |

### 5.2 Campos do item

| Campo | Obrigatório | Descrição |
| --- | --- | --- |
| `produto_id` | Sim | ID retornado por `/api/v1/menu/products` |
| `quantidade` | Sim | Número maior que zero |
| `observacao` | Não | Observação específica do item |
| `modifiers` | Não | Modificadores selecionados |

### 5.3 Campos do modificador

| Campo | Obrigatório | Descrição |
| --- | --- | --- |
| `grupo_modificador_item_id` | Sim | ID do modificador retornado no produto |
| `quantidade` | Não | Se não for positiva, o Minha Loja utiliza `1` |

### 5.4 Campos que não devem ser enviados

O Cardápio não deve enviar como fonte de verdade:

- nome do produto;
- preço unitário;
- valor adicional;
- valor total;
- setor;
- status do pedido;
- número do pedido.

O Minha Loja consulta o produto e os modificadores, valida a empresa e calcula
os valores no servidor.

### 5.5 Resposta de sucesso

Status HTTP:

```text
201 Created
```

Exemplo resumido:

```json
{
  "data": {
    "id": 42,
    "empresa_id": 1,
    "numero": 15,
    "cliente_nome": "Leandro",
    "status": "EM_PREPARO",
    "subtotal": 46.0,
    "valor_total": 46.0,
    "created_at": "2026-08-29T10:30:00-03:00",
    "items": [],
    "logs": []
  }
}
```

O Cardápio deve guardar pelo menos `data.id` e `data.numero`.

## 6. Impressão automática

O `POST /api/v1/balcao/orders` já envia os itens para `fila_impressao`.
Nenhuma segunda chamada é necessária.

O Minha Loja:

- agrupa os itens pelo setor do produto;
- cria uma entrada na fila para cada setor;
- usa o evento `CRIACAO`;
- grava `impresso = false`;
- mantém pedido, itens e fila na mesma transação.

Conteúdo resumido inserido na fila:

```json
{
  "tipo": "balcao_pedido",
  "evento": "CRIACAO",
  "cancelado": false,
  "cabecalho": {
    "pedido": 15,
    "cliente": "Leandro",
    "atendimento": "BALCAO",
    "status": "EM_PREPARO",
    "cancelado": false
  },
  "data": "2026-08-29T10:30:00-03:00",
  "itens": [
    {
      "produto": "AÇAÍ 500ML",
      "quantidade": 2,
      "observacao": "Sem gelo",
      "modificadores": [
        "1x Leite condensado"
      ]
    }
  ]
}
```

Para a impressão chegar ao destino correto:

1. o produto deve possuir `setor_id` configurado;
2. o setor deve estar associado à impressora utilizada pelo agente de
   impressão;
3. o agente de impressão precisa estar ativo e monitorando a empresa.

Produto sem setor é enfileirado no setor textual `Sem setor`.

## 7. Consulta e manutenção do pedido

### 7.1 Listar pedidos

```http
GET /api/v1/balcao/orders?empresa_id=1
Authorization: Bearer TOKEN-JWT
```

Filtros opcionais:

```text
status=EM_PREPARO
search=15
include_finalized=true
```

Sem `include_finalized=true`, pedidos `CONCLUIDO` e `CANCELADO` não são
retornados na listagem geral.

### 7.2 Consultar um pedido

```http
GET /api/v1/balcao/orders/42?empresa_id=1
Authorization: Bearer TOKEN-JWT
```

### 7.3 Adicionar itens

Só é permitido enquanto o pedido estiver em `EM_PREPARO`.

```http
POST /api/v1/balcao/orders/42/items
Authorization: Bearer TOKEN-JWT
Content-Type: application/json
```

```json
{
  "empresa_id": 1,
  "usuario_id": "ID-DO-USUARIO-DE-INTEGRACAO",
  "items": [
    {
      "produto_id": 125,
      "quantidade": 1,
      "observacao": "",
      "modifiers": []
    }
  ]
}
```

Essa rota imprime somente os itens adicionados.

### 7.4 Alterar status

```http
POST /api/v1/balcao/orders/42/status
Authorization: Bearer TOKEN-JWT
Content-Type: application/json
```

Marcar como pronto:

```json
{
  "empresa_id": 1,
  "status": "PRONTO",
  "usuario_id": "ID-DO-USUARIO-DE-INTEGRACAO",
  "motivo": ""
}
```

Cancelar:

```json
{
  "empresa_id": 1,
  "status": "CANCELADO",
  "usuario_id": "ID-DO-USUARIO-DE-INTEGRACAO",
  "motivo": "Solicitação do cliente"
}
```

### 7.5 Reimprimir

```http
POST /api/v1/balcao/orders/42/print
Authorization: Bearer TOKEN-JWT
Content-Type: application/json
```

```json
{
  "empresa_id": 1,
  "usuario_id": "ID-DO-USUARIO-DE-INTEGRACAO"
}
```

## 8. Erros esperados

Os erros usam o formato:

```json
{
  "error": "mensagem do erro"
}
```

| Status | Situação comum |
| --- | --- |
| `400` | Payload inválido, produto indisponível ou modificador inválido |
| `401` | Token ausente, inválido ou expirado |
| `403` | Empresa divergente, módulo desabilitado ou permissão insuficiente |
| `404` | Pedido não encontrado |
| `409` | Operação incompatível com o status atual |
| `500` | Falha interna, inclusive ao gravar a fila de impressão |

## 9. Atualização da tela do Minha Loja

O pedido criado pela API fica imediatamente gravado e será retornado pela
listagem do Balcão.

No estado atual, se a tela Balcão já estiver aberta, o operador precisa clicar
em **Atualizar** para buscar pedidos externos. A tela ainda não possui polling
automático nem atualização em tempo real.

## 10. Segurança e arquitetura recomendada

### 10.1 Cardápio com backend próprio

O backend do Cardápio pode autenticar um usuário de integração e chamar a API
do Minha Loja de servidor para servidor.

As credenciais e o JWT devem permanecer somente no backend do Cardápio.

### 10.2 Cardápio executado somente no navegador

Não é seguro colocar usuário, senha ou token de um operador do Minha Loja no
JavaScript público do Cardápio.

Nesse cenário, ainda deve ser criada uma rota específica de integração, por
exemplo:

```http
POST /api/v1/menu/balcao/orders
```

Essa futura rota deve utilizar uma credencial de integração vinculada à
empresa, assinatura da requisição ou outro mecanismo equivalente.

### 10.3 Idempotência ainda necessária

A rota atual impede duplicação de impressões dentro de um pedido já criado,
mas ainda não possui uma chave externa de idempotência para a criação do
pedido.

Se o Cardápio receber timeout depois que o pedido foi confirmado no servidor e
repetir o `POST`, dois pedidos poderão ser criados.

Antes de uma integração pública definitiva, recomenda-se adicionar:

- `external_order_id` ou `idempotency_key` no pedido;
- índice único por empresa e origem;
- retorno do pedido já existente quando a mesma chave for repetida;
- origem do pedido, por exemplo `CARDAPIO` ou `PDV`;
- autenticação específica de integração.

## 11. Checklist de homologação

- [ ] Empresa com o módulo `balcao` habilitado.
- [ ] Usuário de integração ativo e com `balcao.incluir`.
- [ ] Domínio do Cardápio permitido em `ALLOWED_ORIGIN`, se a chamada ocorrer
      pelo navegador.
- [ ] Produtos ativos e pertencentes à mesma empresa.
- [ ] Modificadores vinculados corretamente aos produtos.
- [ ] Produtos vinculados aos setores de produção.
- [ ] Setores associados às impressoras.
- [ ] Agente de impressão ativo.
- [ ] Pedido criado aparece em **Pedidos → Balcão → Em preparo**.
- [ ] Uma impressão é gerada para cada setor envolvido.
- [ ] Repetição de requisição e timeout avaliados antes da produção.

## 12. Resumo das rotas

| Método | Rota | Autenticação | Finalidade |
| --- | --- | --- | --- |
| `GET` | `/api/v1/menu/categories?empresa_id={id}` | Não | Categorias |
| `GET` | `/api/v1/menu/products?empresa_id={id}` | Não | Produtos e modificadores |
| `POST` | `/api/v1/auth/login` | Não | Obter JWT |
| `POST` | `/api/v1/balcao/orders` | Sim | Criar e imprimir pedido |
| `GET` | `/api/v1/balcao/orders?empresa_id={id}` | Sim | Listar pedidos |
| `GET` | `/api/v1/balcao/orders/{id}?empresa_id={id}` | Sim | Consultar pedido |
| `POST` | `/api/v1/balcao/orders/{id}/items` | Sim | Adicionar e imprimir itens |
| `POST` | `/api/v1/balcao/orders/{id}/status` | Sim | Marcar pronto ou cancelar |
| `POST` | `/api/v1/balcao/orders/{id}/print` | Sim | Reimprimir |

