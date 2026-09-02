-- ============================================================
-- WealthRank — Complete Database Schema
-- Supabase SQL Editor → Paste & Run
-- Updated: 2026-06-26
-- ============================================================
-- Urutan eksekusi:
--   1. Jalankan SECTION A (tabel lama, jika belum ada)
--   2. Jalankan SECTION B (tabel baru: net_worth & financial_todos)
--   3. Jalankan SECTION C (Storage avatar)
-- ============================================================


-- ============================================================
-- SECTION A — EXISTING TABLES (skip jika sudah ada)
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- TABLE 1: profiles
-- Data profil user (username, avatar)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  username    TEXT NOT NULL,
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_own" ON public.profiles FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "profiles_insert_own" ON public.profiles FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE  USING (auth.uid() = user_id);


-- ────────────────────────────────────────────────────────────
-- TABLE 2: user_stats
-- XP masing-masing kategori attribute
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_stats (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  financial_xp  INTEGER DEFAULT 0 NOT NULL CHECK (financial_xp >= 0),
  career_xp     INTEGER DEFAULT 0 NOT NULL CHECK (career_xp >= 0),
  habit_xp      INTEGER DEFAULT 0 NOT NULL CHECK (habit_xp >= 0),
  knowledge_xp  INTEGER DEFAULT 0 NOT NULL CHECK (knowledge_xp >= 0),
  health_xp     INTEGER DEFAULT 0 NOT NULL CHECK (health_xp >= 0),
  created_at    TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at    TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE public.user_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_stats_select_own" ON public.user_stats FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "user_stats_insert_own" ON public.user_stats FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_stats_update_own" ON public.user_stats FOR UPDATE  USING (auth.uid() = user_id);

-- Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_user_stats_updated_at
  BEFORE UPDATE ON public.user_stats
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


-- ────────────────────────────────────────────────────────────
-- TABLE 3: transactions
-- Riwayat transaksi keuangan (income, expense, saving, investment)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.transactions (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id   UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type      TEXT NOT NULL CHECK (type IN ('income', 'expense', 'saving', 'investment')),
  amount    BIGINT NOT NULL CHECK (amount >= 0),   -- dalam IDR (rupiah)
  category  TEXT,                                  -- contoh: 'Gaji Pokok', 'Dana Darurat'
  income_type TEXT DEFAULT 'fixed',                -- 'fixed' atau 'side'
  note      TEXT,
  date      DATE DEFAULT CURRENT_DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "transactions_select_own" ON public.transactions FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "transactions_insert_own" ON public.transactions FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "transactions_update_own" ON public.transactions FOR UPDATE  USING (auth.uid() = user_id);
CREATE POLICY "transactions_delete_own" ON public.transactions FOR DELETE  USING (auth.uid() = user_id);

-- Index untuk query bulan ini
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON public.transactions (user_id, date DESC);


-- ────────────────────────────────────────────────────────────
-- TABLE 4: career_entries
-- Riwayat skill & project Career
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.career_entries (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type        TEXT NOT NULL CHECK (type IN ('skill', 'project', 'experience', 'network')),
  title       TEXT NOT NULL,
  xp_earned   INTEGER NOT NULL DEFAULT 0 CHECK (xp_earned >= 0),
  added_at    TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE public.career_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "career_entries_select_own" ON public.career_entries FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "career_entries_insert_own" ON public.career_entries FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "career_entries_delete_own" ON public.career_entries FOR DELETE  USING (auth.uid() = user_id);


-- ────────────────────────────────────────────────────────────
-- TABLE 5: knowledge_entries
-- Riwayat buku, course, certificate (Knowledge)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.knowledge_entries (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type        TEXT NOT NULL CHECK (type IN ('book', 'online course', 'certificate', 'research paper')),
  title       TEXT NOT NULL,
  xp_earned   INTEGER NOT NULL DEFAULT 0 CHECK (xp_earned >= 0),
  added_at    TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE public.knowledge_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "knowledge_entries_select_own" ON public.knowledge_entries FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "knowledge_entries_insert_own" ON public.knowledge_entries FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "knowledge_entries_delete_own" ON public.knowledge_entries FOR DELETE  USING (auth.uid() = user_id);


-- ────────────────────────────────────────────────────────────
-- TABLE 6: health_entries
-- Riwayat workout & weight log (Health)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.health_entries (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type        TEXT NOT NULL CHECK (type IN ('workout', 'weight', 'streak')),
  note        TEXT,
  value       DECIMAL(8,2),   -- berat badan (kg) atau durasi (menit)
  xp_earned   INTEGER NOT NULL DEFAULT 0 CHECK (xp_earned >= 0),
  date        DATE DEFAULT CURRENT_DATE NOT NULL
);

ALTER TABLE public.health_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "health_entries_select_own" ON public.health_entries FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "health_entries_insert_own" ON public.health_entries FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "health_entries_delete_own" ON public.health_entries FOR DELETE  USING (auth.uid() = user_id);


-- ────────────────────────────────────────────────────────────
-- TABLE 7: achievements
-- Achievement yang sudah di-unlock user
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.achievements (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title        TEXT NOT NULL,
  description  TEXT,
  xp_reward    INTEGER DEFAULT 0 NOT NULL,
  unlocked_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "achievements_select_own" ON public.achievements FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "achievements_insert_own" ON public.achievements FOR INSERT  WITH CHECK (auth.uid() = user_id);


-- ────────────────────────────────────────────────────────────
-- TABLE 8: quests  (habit daily quests — lama)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.quests (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  category    TEXT NOT NULL DEFAULT 'habit',
  title       TEXT NOT NULL,
  xp_reward   INTEGER NOT NULL DEFAULT 0 CHECK (xp_reward >= 0),
  completed   BOOLEAN DEFAULT FALSE NOT NULL,
  date        DATE DEFAULT CURRENT_DATE NOT NULL
);

ALTER TABLE public.quests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "quests_select_own" ON public.quests FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "quests_insert_own" ON public.quests FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "quests_update_own" ON public.quests FOR UPDATE  USING (auth.uid() = user_id);
CREATE POLICY "quests_delete_own" ON public.quests FOR DELETE  USING (auth.uid() = user_id);


-- ============================================================
-- SECTION B — NEW TABLES (fitur baru WealthRank)
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- TABLE 9: net_worth_entries  ★ BARU
-- Riwayat manual input net worth user (direct IDR/USD)
--
-- Setiap kali user update net worth lewat bottom sheet,
-- disimpan sebagai satu baris (snapshot history).
-- Row terbaru = net worth aktif saat ini.
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.net_worth_entries (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,

  -- Jumlah net worth dalam IDR (Rupiah)
  -- Semua kalkulasi internal pakai IDR, USD hanya display
  amount_idr    BIGINT NOT NULL CHECK (amount_idr >= 0),

  -- Catatan opsional dari user ("Tabungan + Saham Q2 2026")
  label         TEXT,

  -- Dari mana sumber angka ini
  -- 'manual'   = diinput langsung oleh user
  -- 'auto'     = dikalkulasi dari transactions (future feature)
  source        TEXT NOT NULL DEFAULT 'manual'
                  CHECK (source IN ('manual', 'auto')),

  -- Snapshot komponen kekayaan (opsional, bisa null)
  -- Mempermudah analisis breakdown di masa depan
  cash_idr        BIGINT DEFAULT 0,        -- uang tunai + tabungan
  investment_idr  BIGINT DEFAULT 0,        -- saham, reksa dana, crypto
  property_idr    BIGINT DEFAULT 0,        -- aset properti
  debt_idr        BIGINT DEFAULT 0,        -- hutang (dikurangkan dari net worth)

  -- Wealth rank saat pencatatan (snapshot)
  -- Memungkinkan chart progression tanpa kalkulasi ulang
  wealth_rank   TEXT NOT NULL DEFAULT 'Beginner'
                  CHECK (wealth_rank IN ('Beginner', 'Starter', 'Builder', 'Elite', 'Wealth Master')),

  recorded_at   TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE public.net_worth_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "net_worth_select_own" ON public.net_worth_entries FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "net_worth_insert_own" ON public.net_worth_entries FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "net_worth_update_own" ON public.net_worth_entries FOR UPDATE  USING (auth.uid() = user_id);
CREATE POLICY "net_worth_delete_own" ON public.net_worth_entries FOR DELETE  USING (auth.uid() = user_id);

-- Index untuk query net worth terbaru per user (ORDER BY recorded_at DESC LIMIT 1)
CREATE INDEX IF NOT EXISTS idx_net_worth_user_date
  ON public.net_worth_entries (user_id, recorded_at DESC);

-- View: net worth aktif (baris terbaru per user)
CREATE OR REPLACE VIEW public.v_net_worth_current AS
SELECT DISTINCT ON (user_id)
  id,
  user_id,
  amount_idr,
  label,
  cash_idr,
  investment_idr,
  property_idr,
  debt_idr,
  wealth_rank,
  recorded_at
FROM public.net_worth_entries
ORDER BY user_id, recorded_at DESC;


-- ────────────────────────────────────────────────────────────
-- TABLE 10: financial_todos  ★ BARU
-- Misi harian keuangan — preset + custom buatan user
--
-- Preset  : is_preset = true, direset tiap hari otomatis
-- Custom  : is_preset = false, persisten sampai user hapus
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.financial_todos (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,

  -- Konten todo
  title           TEXT NOT NULL,
  description     TEXT,
  icon            TEXT DEFAULT '🎯',      -- emoji ikon
  points          INTEGER DEFAULT 50 NOT NULL CHECK (points >= 0),

  -- Status
  completed       BOOLEAN DEFAULT FALSE NOT NULL,
  completed_at    TIMESTAMPTZ,

  -- Tipe todo
  -- 'preset'  : misi default dari WealthConfig.dailyFinancialTodos
  -- 'custom'  : dibuat sendiri oleh user
  todo_type       TEXT NOT NULL DEFAULT 'custom'
                    CHECK (todo_type IN ('preset', 'custom')),

  -- ID preset (cocok dengan WealthConfig.dailyFinancialTodos[id])
  -- Null untuk custom todos
  preset_id       TEXT,

  -- Tanggal misi (preset di-reset tiap hari, custom tidak ada tanggal)
  todo_date       DATE DEFAULT CURRENT_DATE,

  created_at      TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at      TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE public.financial_todos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "financial_todos_select_own" ON public.financial_todos FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "financial_todos_insert_own" ON public.financial_todos FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "financial_todos_update_own" ON public.financial_todos FOR UPDATE  USING (auth.uid() = user_id);
CREATE POLICY "financial_todos_delete_own" ON public.financial_todos FOR DELETE  USING (auth.uid() = user_id);

-- Auto-update updated_at
CREATE OR REPLACE TRIGGER trg_financial_todos_updated_at
  BEFORE UPDATE ON public.financial_todos
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Index: query todos hari ini per user
CREATE INDEX IF NOT EXISTS idx_financial_todos_user_date
  ON public.financial_todos (user_id, todo_date DESC);

-- Index: custom todos (tanpa tanggal, persisten)
CREATE INDEX IF NOT EXISTS idx_financial_todos_custom
  ON public.financial_todos (user_id, todo_type)
  WHERE todo_type = 'custom';


-- ────────────────────────────────────────────────────────────
-- OPTIONAL: Seed preset todos untuk user baru
-- Panggil fungsi ini setelah user register
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.seed_daily_financial_todos(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  today DATE := CURRENT_DATE;
BEGIN
  -- Jangan seed kalau sudah ada untuk hari ini
  IF EXISTS (
    SELECT 1 FROM public.financial_todos
    WHERE user_id = p_user_id
      AND todo_type = 'preset'
      AND todo_date = today
  ) THEN
    RETURN;
  END IF;

  INSERT INTO public.financial_todos
    (user_id, title, description, icon, points, todo_type, preset_id, todo_date)
  VALUES
    (p_user_id, 'Catat pengeluaran hari ini',       'Track setiap rupiah yang keluar',              '📝', 50,  'preset', 'todo-f1', today),
    (p_user_id, 'Review saldo rekening tabungan',    'Cek apakah sesuai target bulan ini',           '🏦', 30,  'preset', 'todo-f2', today),
    (p_user_id, 'Pelajari satu konsep investasi',    'Saham, reksa dana, atau crypto 15 menit',      '📚', 40,  'preset', 'todo-f3', today),
    (p_user_id, 'Hindari pembelian impulsif',        'Tahan diri dari 1 keinginan hari ini',         '🛑', 60,  'preset', 'todo-f4', today),
    (p_user_id, 'Update net worth tracker',          'Input data keuangan terkini kamu',             '💰', 100, 'preset', 'todo-f5', today);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- SECTION C — STORAGE: Avatar bucket
-- Jalankan bagian ini sekali, terpisah jika perlu
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
  VALUES ('avatars', 'avatars', true)
  ON CONFLICT (id) DO NOTHING;

CREATE POLICY "avatars_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "avatars_user_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "avatars_user_update"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "avatars_user_delete"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);


-- ============================================================
-- DONE!
-- Total: 10 tabel + 1 view + 2 functions + storage bucket
-- ============================================================
