-- ============================================================
-- SCRIPT SQL PARA CRIAR AS TABELAS DO CARDÁPIO NO SUPABASE
-- Execute isso no Editor SQL do seu painel do Supabase
-- ============================================================

-- ============================================================
-- SCRIPT SQL PARA CRIAR AS TABELAS DO CARDÁPIO NO SUPABASE
-- Execute isso no Editor SQL do seu painel do Supabase
-- ============================================================

-- Tabela de Categorias
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    icon TEXT NOT NULL DEFAULT 'restaurant_menu',
    order_index INTEGER NOT NULL DEFAULT 0
);

-- Tabela de Produtos
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    price NUMERIC(10, 2) NOT NULL DEFAULT 0,
    image_url TEXT NOT NULL DEFAULT '',
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    ingredients JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    badge TEXT,
    rating NUMERIC(3, 2) NOT NULL DEFAULT 4.5,
    prep_time_minutes INTEGER NOT NULL DEFAULT 15,
    review_count INTEGER NOT NULL DEFAULT 0,
    option_groups JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS (Row Level Security) - opcional mas recomendado
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Política para permitir leitura pública nas categorias
CREATE POLICY "Allow public read access on categories"
    ON categories FOR SELECT
    TO anon, authenticated
    USING (true);

-- Política para permitir leitura pública nos produtos ativos
CREATE POLICY "Allow public read access on active products"
    ON products FOR SELECT
    TO anon, authenticated
    USING (is_active = true);

-- ============================================================
-- INSERÇÃO DAS CATEGORIAS
-- ============================================================

INSERT INTO categories (id, name, icon, order_index) VALUES
(1, 'Doces', 'cake', 1),
(2, 'Tamanho Família', 'people', 2),
(3, 'Salgados', 'local_pizza', 3),
(4, 'Combos', 'fastfood', 4),
(5, 'Bebidas Geladas', 'local_drink', 5),
(6, 'Bebidas Quentes', 'coffee', 6)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- INSERÇÃO DOS PRODUTOS
-- ============================================================

-- DOCES
INSERT INTO products (id, name, description, price, image_url, category_id, ingredients, is_active, rating, prep_time_minutes, review_count, option_groups) VALUES
(1, 'Bolo de Goiabada', 'Bolo caseiro fofinho com cobertura generosa de goiabada artesanal. Perfeito para acompanhar um cafe.', 35.00, '', 1, '["Goiabada Cascao", "Massa artesanal", "Amor de vo"]', true, 4.8, 10, 127, '[]')
ON CONFLICT (id) DO NOTHING;

INSERT INTO products (id, name, description, price, image_url, category_id, ingredients, is_active, rating, prep_time_minutes, review_count, option_groups) VALUES
(2, 'Geleia de Morango', 'Geleia premium de morango com pedacos da fruta, sem conservantes. Ideal para cafes da manha especiais.', 18.90, '', 1, '["Morango fresco", "Acucar de cana", "Pectina natural"]', true, 4.6, 5, 42, '[]')
ON CONFLICT (id) DO NOTHING;

INSERT INTO products (id, name, description, price, image_url, category_id, ingredients, is_active, rating, prep_time_minutes, review_count, option_groups) VALUES
(3, 'Doce de Leite Cremoso', 'Doce de leite cremoso artesanal, receita tradicional desde 1977. Textura aveludada e sabor inconfundivel.', 22.00, '', 1, '["Leite integral", "Acucar", "Textura aveludada"]', true, 4.7, 5, 89, '[]')
ON CONFLICT (id) DO NOTHING;

INSERT INTO products (id, name, description, price, image_url, category_id, ingredients, is_active, rating, prep_time_minutes, review_count, option_groups) VALUES
(4, 'Pudim de Leite', 'Pudim de leite condensado com calda de caramelo feita na hora. Super cremoso!', 15.00, '', 1, '["Leite condensado", "Ovos", "Caramelo"]', true, 4.9, 15, 156, '[]')
ON CONFLICT (id) DO NOTHING;

-- TAMANHO FAMILIA
INSERT INTO products (id, name, description, price, image_url, category_id, ingredients, is_active, badge, rating, prep_time_minutes, review_count, option_groups) VALUES
(14, 'Torta Salgada Família', 'Torta salgada grande, serve até 6 pessoas. Recheio de frango com catupiry ou palmito.', 89.00, '', 2, '["Massa leve", "Frango desfiado", "Catupiry", "Palmito"]', true, 'Mais Vendido', 4.8, 45, 215, '[]')
ON CONFLICT (id) DO NOTHING;

INSERT INTO products (id, name, description, price, image_url, category_id, ingredients, is_active, rating, prep_time_minutes, review_count, option_groups) VALUES
(15, 'Bandeja de Salgados', '50 mini salgados sortidos: coxinhas, bolinhas de queijo, kibes e risoles.', 75.00, '', 2, '["Coxinha", "Bolinha de queijo", "Kibe", "Risole"]', true, 4.6, 40, 98, '[]')
ON CONFLICT (id) DO NOTHING;

INSERT INTO products (id, name, description, price, image_url, category_id, ingredients, is_active, badge, rating, prep_time_minutes, review_count, option_groups) VALUES
(16, 'Bolo de Pote Família', '6 potes grandes de bolo de pote com cobertura generosa. Sabores variados.', 65.00, '', 2, '["Massa de bolo", "Cobertura", "Recheio cremoso"]', true, 'Promocao', 4.7, 20, 76, '[]')
ON CONFLICT (id) DO NOTHING;

-- SALGADOS
INSERT INTO products (id, name, description, price, image_url, category_id, ingredients, is_active, rating, prep_time_minutes, review_count, option_groups) VALUES
(5, 'Coxinha de Frango', 'Coxinha crocante com recheio de frango desfiado temperado. Tamanho familia, serve 2 pessoas.', 8.50, '', 3, '["Frango desfiado", "Massa de batata", "Temperos especiais"]', true, 4.5, 20, 312, '[]')
ON CONFLICT (id) DO NOTHING;

INSERT INTO products (id, name, description, price, image_url, category_id, ingredients, is_active, rating, prep_time_minutes, review_count, option_groups) VALUES
(6, 'Empada de Palmito', 'Empada artesanal com recheio cremoso de palmito e catupiry. Massa folhada sequinha.', 10.00, '', 3, '["Palmito", "Catupiry", "Massa folhada"]', true, 4.4, 18, 78, '[]')
ON CONFLICT (id) DO NOTHING;

INSERT INTO products (id, name, description, price, image_url, category_id, ingredients, is_active, rating, prep_time_minutes, review_count, option_groups) VALUES
(7, 'Esfiha de Carne', 'Esfiha aberta com carne moida temperada e especiarias. Sabor irresistivel!', 9.00, '', 3, '["Carne moida", "Tomate", "Especiarias"]', true, 4.3, 15, 34, '[]')
ON CONFLICT (id) DO NOTHING;

-- BEBIDAS GELADAS
INSERT INTO products (id, name, description, price, image_url, category_id, ingredients, is_active, badge, rating, prep_time_minutes, review_count, option_groups) VALUES
(8, 'Suco de Laranja Natural', 'Suco de laranja natural, espremido na hora. Sem adicao de agua ou acucar.', 12.00, '', 5, '["Laranja natural"]', true, null, 4.7, 5, 98, '[{"id": "tamanho", "name": "Tamanho", "options": [{"id": "t1", "name": "300ml", "price_modifier": 0}, {"id": "t2", "name": "500ml", "price_modifier": 3.00}, {"id": "t3", "name": "1L", "price_modifier": 7.00}]}, {"id": "embalagem", "name": "Embalagem", "options": [{"id": "e1", "name": "Copo", "price_modifier": 0}, {"id": "e2", "name": "Garrafa PET", "price_modifier": 1.50}, {"id": "e3", "name": "Vidro", "price_modifier": 3.00}]}]')
ON CONFLICT (id) DO NOTHING;

INSERT INTO products (id, name, description, price, image_url, category_id, ingredients, is_active, badge, rating, prep_time_minutes, review_count, option_groups) VALUES
(9, 'Refrigerante Artesanal', 'Refrigerante artesanal de guarana em garrafa de vidro. Sabor retro e refrescante.', 8.00, '', 5, '["Guarana natural", "Acucar de cana"]', true, 'Promocao', 4.2, 2, 56, '[{"id": "tamanho", "name": "Tamanho", "options": [{"id": "t1", "name": "350ml", "price_modifier": 0}, {"id": "t2", "name": "600ml", "price_modifier": 2.50}, {"id": "t3", "name": "1L", "price_modifier": 5.00}, {"id": "t4", "name": "2L", "price_modifier": 8.00}]}, {"id": "embalagem", "name": "Embalagem", "options": [{"id": "e1", "name": "Lata", "price_modifier": 0}, {"id": "e2", "name": "Garrafa", "price_modifier": 1.00}, {"id": "e3", "name": "Vidro", "price_modifier": 2.50}]}]')
ON CONFLICT (id) DO NOTHING;

-- BEBIDAS QUENTES
INSERT INTO products (id, name, description, price, image_url, category_id, ingredients, is_active, badge, rating, prep_time_minutes, review_count, option_groups) VALUES
(10, 'Cafe Especial da Casa', 'Cafe 100% arabica, torrado na hora. Notas de chocolate e caramelo.', 7.00, '', 6, '["Graos de cafe arabica"]', true, 'Premium', 4.9, 8, 203, '[{"id": "tamanho", "name": "Tamanho", "options": [{"id": "t1", "name": "Pequeno (80ml)", "price_modifier": 0}, {"id": "t2", "name": "Medio (150ml)", "price_modifier": 2.00}, {"id": "t3", "name": "Grande (240ml)", "price_modifier": 4.00}]}, {"id": "embalagem", "name": "Embalagem", "options": [{"id": "e1", "name": "Xicara", "price_modifier": 0}, {"id": "e2", "name": "Copo Termico", "price_modifier": 3.00}, {"id": "e3", "name": "Vidro", "price_modifier": 1.50}]}]')
ON CONFLICT (id) DO NOTHING;

INSERT INTO products (id, name, description, price, image_url, category_id, ingredients, is_active, rating, prep_time_minutes, review_count, option_groups) VALUES
(11, 'Cafe com Leite', 'Cafe especial da casa com leite vaporizado e uma pitada de canela.', 9.50, '', 6, '["Cafe especial", "Leite integral", "Canela"]', true, null, 4.6, 8, 145, '[{"id": "tamanho", "name": "Tamanho", "options": [{"id": "t1", "name": "Pequeno (100ml)", "price_modifier": 0}, {"id": "t2", "name": "Medio (200ml)", "price_modifier": 2.50}, {"id": "t3", "name": "Grande (350ml)", "price_modifier": 4.50}]}, {"id": "embalagem", "name": "Embalagem", "options": [{"id": "e1", "name": "Xicara", "price_modifier": 0}, {"id": "e2", "name": "Copo Termico", "price_modifier": 3.00}, {"id": "e3", "name": "Vidro", "price_modifier": 1.50}]}]')
ON CONFLICT (id) DO NOTHING;

-- COMBOS
INSERT INTO products (id, name, description, price, image_url, category_id, ingredients, is_active, badge, rating, prep_time_minutes, review_count, option_groups) VALUES
(12, 'Combo Cafe da Manha', 'Cafe com leite + pao na chapa com manteiga + geleia de morango.', 28.00, '', 4, '["Cafe com leite", "Pao na chapa", "Geleia de morango"]', true, 'Promocao', 4.7, 15, 67, '[]')
ON CONFLICT (id) DO NOTHING;

INSERT INTO products (id, name, description, price, image_url, category_id, ingredients, is_active, rating, prep_time_minutes, review_count, option_groups) VALUES
(13, 'Combo Tachao', '2 coxinhas + 1 empada + suco de laranja. O classico da casa.', 32.00, '', 4, '["Coxinha", "Empada", "Suco de laranja"]', true, null, 4.8, 25, 189, '[]')
ON CONFLICT (id) DO NOTHING;
