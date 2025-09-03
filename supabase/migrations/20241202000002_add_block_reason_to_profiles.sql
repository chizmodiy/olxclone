-- Додаємо поле для причини блокування користувача
ALTER TABLE public.profiles 
ADD COLUMN block_reason TEXT NULL;

-- Додаємо коментар до поля
COMMENT ON COLUMN public.profiles.block_reason IS 'Причина блокування користувача (заповнюється тільки якщо користувач заблокований)';

-- Додаємо перевірку, що block_reason може бути заповнене тільки якщо status = 'blocked'
ALTER TABLE public.profiles 
ADD CONSTRAINT check_block_reason_when_blocked 
CHECK (
  (status = 'blocked' AND block_reason IS NOT NULL) OR 
  (status != 'blocked' AND block_reason IS NULL)
); 