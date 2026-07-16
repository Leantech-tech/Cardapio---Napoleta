-- ============================================================
-- TABELAS DE MODIFICADORES E ADICIONAIS (baseado no minha_loja)
-- ============================================================

-- Tabela: grupo_modificador
-- Agrupa as opções de modificadores/adicionais
CREATE TABLE IF NOT EXISTS grupo_modificador (
  id BIGSERIAL PRIMARY KEY,
  empresa_id SMALLINT NOT NULL DEFAULT 7,
  nome VARCHAR(100) NOT NULL,
  tipo VARCHAR(20) NOT NULL DEFAULT 'MODIFICADOR' CHECK (tipo IN ('MODIFICADOR', 'ADICIONAL')),
  qtd_min INTEGER NOT NULL DEFAULT 1,
  qtd_max INTEGER NOT NULL DEFAULT 1,
  is_ativo BOOLEAN NOT NULL DEFAULT true,
  is_excluido BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_grupo_modificador_empresa ON grupo_modificador(empresa_id);
CREATE INDEX IF NOT EXISTS idx_grupo_modificador_ativo ON grupo_modificador(is_ativo) WHERE is_excluido = false;

COMMENT ON TABLE grupo_modificador IS 'Grupos de modificadores e adicionais disponíveis';
COMMENT ON COLUMN grupo_modificador.tipo IS 'MODIFICADOR = escolha única (ex: tamanho). ADICIONAL = escolha múltipla (ex: ingredientes extras)';
COMMENT ON COLUMN grupo_modificador.qtd_min IS 'Quantidade mínima de itens que devem ser selecionados neste grupo';
COMMENT ON COLUMN grupo_modificador.qtd_max IS 'Quantidade máxima de itens que podem ser selecionados neste grupo';


-- Tabela: grupo_modificador_item
-- Opções individuais dentro de cada grupo
CREATE TABLE IF NOT EXISTS grupo_modificador_item (
  id BIGSERIAL PRIMARY KEY,
  grupo_modificador_id BIGINT NOT NULL REFERENCES grupo_modificador(id) ON DELETE CASCADE,
  nome VARCHAR(100) NOT NULL,
  vr_adicional NUMERIC(10,2) NOT NULL DEFAULT 0,
  ordem INTEGER NOT NULL DEFAULT 0,
  is_ativo BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_grupo_modificador_item_grupo ON grupo_modificador_item(grupo_modificador_id);
CREATE INDEX IF NOT EXISTS idx_grupo_modificador_item_ativo ON grupo_modificador_item(is_ativo);

COMMENT ON TABLE grupo_modificador_item IS 'Itens/opções dentro de cada grupo de modificador';
COMMENT ON COLUMN grupo_modificador_item.vr_adicional IS 'Valor adicional cobrado pelo cliente ao selecionar esta opção';


-- Tabela: produto_grupo_modificador
-- Vínculo N:N entre produto e grupo de modificador
CREATE TABLE IF NOT EXISTS produto_grupo_modificador (
  id BIGSERIAL PRIMARY KEY,
  produto_id BIGINT NOT NULL REFERENCES produto(id) ON DELETE CASCADE,
  grupo_modificador_id BIGINT NOT NULL REFERENCES grupo_modificador(id) ON DELETE CASCADE,
  ordem INTEGER NOT NULL DEFAULT 0,
  is_obrigatorio BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(produto_id, grupo_modificador_id)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_produto_grupo_modificador_produto ON produto_grupo_modificador(produto_id);
CREATE INDEX IF NOT EXISTS idx_produto_grupo_modificador_grupo ON produto_grupo_modificador(grupo_modificador_id);

COMMENT ON TABLE produto_grupo_modificador IS 'Relacionamento entre produtos e seus grupos de modificadores/adicionais';
COMMENT ON COLUMN produto_grupo_modificador.is_obrigatorio IS 'Se true, o cliente DEVE selecionar pelo menos uma opção deste grupo';


-- ============================================================
-- TABELA DE MODIFICADORES NA COMANDA (ajustes se necessário)
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'comanda_item_modificador' AND column_name = 'vr_adicional') THEN
    ALTER TABLE comanda_item_modificador ADD COLUMN vr_adicional NUMERIC(10,2) NOT NULL DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'comanda_item_modificador' AND column_name = 'created_at') THEN
    ALTER TABLE comanda_item_modificador ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
END $$;

COMMENT ON TABLE comanda_item_modificador IS 'Modificadores/adicionais vinculados a cada item de comanda';
COMMENT ON COLUMN comanda_item_modificador.vr_adicional IS 'Valor adicional cobrado neste modificador (snapshot do valor no momento da venda)';


-- ============================================================
-- VIEW PARA FACILITAR A BUSCA DE PRODUTOS COM MODIFICADORES
-- ============================================================

CREATE OR REPLACE VIEW v_produto_modificadores AS
SELECT 
  p.id AS produto_id,
  pgm.id AS vinculo_id,
  pgm.ordem AS vinculo_ordem,
  pgm.is_obrigatorio,
  gm.id AS grupo_id,
  gm.nome AS grupo_nome,
  gm.tipo AS grupo_tipo,
  gm.qtd_min,
  gm.qtd_max,
  gmi.id AS item_id,
  gmi.nome AS item_nome,
  gmi.vr_adicional,
  gmi.ordem AS item_ordem
FROM produto p
JOIN produto_grupo_modificador pgm ON pgm.produto_id = p.id
JOIN grupo_modificador gm ON gm.id = pgm.grupo_modificador_id AND gm.is_ativo = true AND gm.is_excluido = false
JOIN grupo_modificador_item gmi ON gmi.grupo_modificador_id = gm.id AND gmi.is_ativo = true
WHERE p.is_ativo = true AND (p.is_excluido = false OR p.is_excluido IS NULL)
ORDER BY p.id, pgm.ordem, gmi.ordem;
