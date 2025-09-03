-- Оновлюємо RLS політики для profiles таблиці
-- Дозволяємо адмінам бачити всі поля включаючи block_reason

-- Дропаємо старі політики якщо вони існують
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

-- Створюємо нові політики
-- Користувачі можуть бачити тільки свої профілі
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Адміни можуть бачити всі профілі (включаючи причини блокування)
CREATE POLICY "Admins can view all profiles" ON public.profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Користувачі можуть оновлювати тільки свої профілі
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Адміни можуть оновлювати всі профілі (включаючи блокування)
CREATE POLICY "Admins can update all profiles" ON public.profiles
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  ); 