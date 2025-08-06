-- SQL скрипт для додавання підкатегорій згідно з наданим списком
-- Спочатку потрібно отримати ID категорій з таблиці categories

-- Дитячий світ
INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Дитячий одяг', '{}'::jsonb FROM public.categories WHERE name = 'Дитячий світ';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Дитяче взуття', '{}'::jsonb FROM public.categories WHERE name = 'Дитячий світ';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Дитячі коляски', '{}'::jsonb FROM public.categories WHERE name = 'Дитячий світ';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Дитячі автокрісла', '{}'::jsonb FROM public.categories WHERE name = 'Дитячий світ';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Дитячі меблі', '{}'::jsonb FROM public.categories WHERE name = 'Дитячий світ';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Іграшки', '{}'::jsonb FROM public.categories WHERE name = 'Дитячий світ';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Дитячий транспорт', '{}'::jsonb FROM public.categories WHERE name = 'Дитячий світ';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Годування', '{}'::jsonb FROM public.categories WHERE name = 'Дитячий світ';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Товари для школярів', '{}'::jsonb FROM public.categories WHERE name = 'Дитячий світ';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Інші дитячі товари', '{}'::jsonb FROM public.categories WHERE name = 'Дитячий світ';

-- Нерухомість
INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Квартири', '{"area": {"type": "number", "unit": "м²"}, "rooms": {"type": "number"}}'::jsonb FROM public.categories WHERE name = 'Нерухомість';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Кімнати', '{"area": {"type": "number", "unit": "м²"}}'::jsonb FROM public.categories WHERE name = 'Нерухомість';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Будинки', '{"area": {"type": "number", "unit": "м²"}, "rooms": {"type": "number"}}'::jsonb FROM public.categories WHERE name = 'Нерухомість';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Земля', '{"area": {"type": "number", "unit": "м²"}}'::jsonb FROM public.categories WHERE name = 'Нерухомість';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Комерційна нерухомість', '{"area": {"type": "number", "unit": "м²"}}'::jsonb FROM public.categories WHERE name = 'Нерухомість';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Гаражі, парковки', '{"area": {"type": "number", "unit": "м²"}}'::jsonb FROM public.categories WHERE name = 'Нерухомість';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Нерухомість за кордоном', '{"area": {"type": "number", "unit": "м²"}}'::jsonb FROM public.categories WHERE name = 'Нерухомість';

-- Авто
INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Легкові автомобілі', '{"year": {"type": "number"}, "engine_power_hp": {"type": "number", "unit": "к.с."}, "car_brand": ["Volkswagen", "BMW", "Audi", "Mercedes-Benz", "Toyota", "Renault", "Skoda", "Ford", "Nissan", "Opel", "Інше"]}'::jsonb FROM public.categories WHERE name = 'Авто';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Вантажні автомобілі', '{"year": {"type": "number"}, "engine_power_hp": {"type": "number", "unit": "к.с."}}'::jsonb FROM public.categories WHERE name = 'Авто';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Автобуси', '{"year": {"type": "number"}, "engine_power_hp": {"type": "number", "unit": "к.с."}}'::jsonb FROM public.categories WHERE name = 'Авто';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Мото', '{"year": {"type": "number"}, "engine_power_hp": {"type": "number", "unit": "к.с."}}'::jsonb FROM public.categories WHERE name = 'Авто';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Спецтехніка', '{"year": {"type": "number"}, "engine_power_hp": {"type": "number", "unit": "к.с."}}'::jsonb FROM public.categories WHERE name = 'Авто';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Сільгосптехніка', '{"year": {"type": "number"}, "engine_power_hp": {"type": "number", "unit": "к.с."}}'::jsonb FROM public.categories WHERE name = 'Авто';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Водний транспорт', '{"year": {"type": "number"}, "engine_power_hp": {"type": "number", "unit": "к.с."}}'::jsonb FROM public.categories WHERE name = 'Авто';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Автомобілі з Польщі', '{"year": {"type": "number"}, "engine_power_hp": {"type": "number", "unit": "к.с."}, "car_brand": ["Volkswagen", "BMW", "Audi", "Mercedes-Benz", "Toyota", "Renault", "Skoda", "Ford", "Nissan", "Opel", "Інше"]}'::jsonb FROM public.categories WHERE name = 'Авто';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Причепи / будинки на колесах', '{"year": {"type": "number"}, "engine_power_hp": {"type": "number", "unit": "к.с."}}'::jsonb FROM public.categories WHERE name = 'Авто';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Вантажівки та спецтехніка з Польщі', '{"year": {"type": "number"}, "engine_power_hp": {"type": "number", "unit": "к.с."}}'::jsonb FROM public.categories WHERE name = 'Авто';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Інший транспорт', '{"year": {"type": "number"}}'::jsonb FROM public.categories WHERE name = 'Авто';

-- Запчастини для транспорту
INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Автозапчастини', '{}'::jsonb FROM public.categories WHERE name = 'Запчастини для транспорту';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Аксесуари для авто', '{}'::jsonb FROM public.categories WHERE name = 'Запчастини для транспорту';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Автозвук та мультимедіа', '{}'::jsonb FROM public.categories WHERE name = 'Запчастини для транспорту';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Шини, диски і колеса', '{}'::jsonb FROM public.categories WHERE name = 'Запчастини для транспорту';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'GPS-навігатори / відеореєстратори', '{}'::jsonb FROM public.categories WHERE name = 'Запчастини для транспорту';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Транспорт на запчастини / авторозбірки', '{}'::jsonb FROM public.categories WHERE name = 'Запчастини для транспорту';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Мотозапчастини', '{}'::jsonb FROM public.categories WHERE name = 'Запчастини для транспорту';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Мотоекіпірування', '{}'::jsonb FROM public.categories WHERE name = 'Запчастини для транспорту';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Мотоаксесуари', '{}'::jsonb FROM public.categories WHERE name = 'Запчастини для транспорту';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Мастила та автохімія', '{}'::jsonb FROM public.categories WHERE name = 'Запчастини для транспорту';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Запчастини для іншої техніки', '{}'::jsonb FROM public.categories WHERE name = 'Запчастини для транспорту';

-- Робота
INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Роздрібна торгівля / продажі / закупки', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Логістика / Склад / Доставка', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Будівництво / облицювальні роботи', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Колл-центри / Телекомунікації', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Адміністративний персонал / HR / Секретаріат', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Охорона / безпека', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Клінінг / Домашній персонал', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Краса / фітнес / спорт', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Освіта / переклад', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Культура / мистецтво / розваги', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Медицина / фармацевтика', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'IT / комп''ютери', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Банки / фінанси / страхування / юриспруденція', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Нерухомість', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Реклама / дизайн / PR', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Виробництво / робітничі спеціальності', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Сільське і лісове господарство / агробізнес', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Часткова зайнятість', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Початок кар''єри / Студенти', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Робота за кордоном', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Бухгалтерія', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Готельно-ресторанний бізнес / Туризм', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Інші сфери занять', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'СТО / автомийки', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Служба в Силах оборони', '{}'::jsonb FROM public.categories WHERE name = 'Робота';

-- Тварини
INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Безкоштовно (тварини і в''язка)', '{}'::jsonb FROM public.categories WHERE name = 'Тварини';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Собаки', '{}'::jsonb FROM public.categories WHERE name = 'Тварини';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Коти', '{}'::jsonb FROM public.categories WHERE name = 'Тварини';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Акваріумістика', '{}'::jsonb FROM public.categories WHERE name = 'Тварини';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Гризуни', '{}'::jsonb FROM public.categories WHERE name = 'Тварини';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Сільгосп тварини', '{}'::jsonb FROM public.categories WHERE name = 'Тварини';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Інші тварини', '{}'::jsonb FROM public.categories WHERE name = 'Тварини';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Зоотовари', '{}'::jsonb FROM public.categories WHERE name = 'Тварини';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'В''язка', '{}'::jsonb FROM public.categories WHERE name = 'Тварини';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Бюро знахідок', '{}'::jsonb FROM public.categories WHERE name = 'Тварини';

-- Дім і сад
INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Канцтовари / витратні матеріали', '{}'::jsonb FROM public.categories WHERE name = 'Дім і сад';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Меблі', '{}'::jsonb FROM public.categories WHERE name = 'Дім і сад';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Продукти харчування / напої', '{}'::jsonb FROM public.categories WHERE name = 'Дім і сад';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Сад / город', '{}'::jsonb FROM public.categories WHERE name = 'Дім і сад';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Предмети інтер''єру', '{}'::jsonb FROM public.categories WHERE name = 'Дім і сад';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Будівництво / ремонт', '{}'::jsonb FROM public.categories WHERE name = 'Дім і сад';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Інструменти', '{}'::jsonb FROM public.categories WHERE name = 'Дім і сад';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Кімнатні рослини', '{}'::jsonb FROM public.categories WHERE name = 'Дім і сад';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Посуд / кухонне приладдя', '{}'::jsonb FROM public.categories WHERE name = 'Дім і сад';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Садовий інвентар', '{}'::jsonb FROM public.categories WHERE name = 'Дім і сад';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Господарський інвентар / побутова хімія', '{}'::jsonb FROM public.categories WHERE name = 'Дім і сад';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Інші товари для дому', '{}'::jsonb FROM public.categories WHERE name = 'Дім і сад';

-- Електроніка
INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Телефони та аксесуари', '{}'::jsonb FROM public.categories WHERE name = 'Електроніка';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Комп''ютери та комплектуючі', '{}'::jsonb FROM public.categories WHERE name = 'Електроніка';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Фото / відео', '{}'::jsonb FROM public.categories WHERE name = 'Електроніка';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Тв / відеотехніка', '{}'::jsonb FROM public.categories WHERE name = 'Електроніка';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Аудіотехніка', '{}'::jsonb FROM public.categories WHERE name = 'Електроніка';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Ігри та ігрові приставки', '{}'::jsonb FROM public.categories WHERE name = 'Електроніка';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Планшети / ел. книги та аксесуари', '{}'::jsonb FROM public.categories WHERE name = 'Електроніка';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Ноутбуки та аксесуари', '{}'::jsonb FROM public.categories WHERE name = 'Електроніка';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Техніка для дому', '{}'::jsonb FROM public.categories WHERE name = 'Електроніка';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Техніка для кухні', '{}'::jsonb FROM public.categories WHERE name = 'Електроніка';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Кліматичне обладнання', '{}'::jsonb FROM public.categories WHERE name = 'Електроніка';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Індивідуальний догляд', '{}'::jsonb FROM public.categories WHERE name = 'Електроніка';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Аксесуари й комплектуючі', '{}'::jsonb FROM public.categories WHERE name = 'Електроніка';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Інша електроніка', '{}'::jsonb FROM public.categories WHERE name = 'Електроніка';

-- Бізнес та послуги
INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Авто / мото послуги', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Краса / здоров''я', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Догляд за дітьми та літніми людьми', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Побутові послуги', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Клінінг', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Послуги освіти та спорту', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Перевезення та послуги спецтехніки', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Фото та відеозйомка', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Організація свят', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Ремонт та обслуговування техніки', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Будівництво та ремонт', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Сировина / матеріали', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Прийом вторсировини', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Туризм / імміграція', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Ділові послуги', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Продаж бізнесу', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Продаж обладнання для бізнесу', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Послуги для тварин', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Ритуальні послуги', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Інші послуги', '{}'::jsonb FROM public.categories WHERE name = 'Бізнес та послуги';

-- Житло подобово
INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Будинки подобово, погодинно', '{"area": {"type": "number", "unit": "м²"}, "rooms": {"type": "number"}}'::jsonb FROM public.categories WHERE name = 'Житло подобово';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Квартири подобово, погодинно', '{"area": {"type": "number", "unit": "м²"}, "rooms": {"type": "number"}}'::jsonb FROM public.categories WHERE name = 'Житло подобово';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Кімнати подобово, погодинно', '{"area": {"type": "number", "unit": "м²"}}'::jsonb FROM public.categories WHERE name = 'Житло подобово';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Готелі, бази відпочинку', '{}'::jsonb FROM public.categories WHERE name = 'Житло подобово';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Хостели, койко-місця', '{}'::jsonb FROM public.categories WHERE name = 'Житло подобово';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Пропозиції Туроператорів', '{}'::jsonb FROM public.categories WHERE name = 'Житло подобово';

-- Оренда та прокат
INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Оренда транспорту та спецтехніки', '{}'::jsonb FROM public.categories WHERE name = 'Оренда та прокат';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Прокат велосипедів і мото', '{}'::jsonb FROM public.categories WHERE name = 'Оренда та прокат';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Оренда обладнання', '{}'::jsonb FROM public.categories WHERE name = 'Оренда та прокат';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Прокат інструментів', '{}'::jsonb FROM public.categories WHERE name = 'Оренда та прокат';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Прокат товарів мед призначення', '{}'::jsonb FROM public.categories WHERE name = 'Оренда та прокат';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Прокат техніки та електроніки', '{}'::jsonb FROM public.categories WHERE name = 'Оренда та прокат';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Прокат товарів для заходів', '{}'::jsonb FROM public.categories WHERE name = 'Оренда та прокат';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Прокат спорт і туристичних товарів', '{}'::jsonb FROM public.categories WHERE name = 'Оренда та прокат';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Прокат одягу та аксесуарів', '{}'::jsonb FROM public.categories WHERE name = 'Оренда та прокат';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Прокат дитячого одягу та товарів', '{}'::jsonb FROM public.categories WHERE name = 'Оренда та прокат';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Інші товари на прокат', '{}'::jsonb FROM public.categories WHERE name = 'Оренда та прокат';

-- Мода і стиль
INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Жіночий одяг', '{"size": ["XS", "S", "M", "L", "XL", "XXL", "XXXL"], "condition": ["Нове", "Б/в", "Потребує ремонту"]}'::jsonb FROM public.categories WHERE name = 'Мода і стиль';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Жіноче взуття', '{"size": ["34", "35", "36", "37", "38", "39", "40", "41", "42"], "condition": ["Нове", "Б/в", "Потребує ремонту"]}'::jsonb FROM public.categories WHERE name = 'Мода і стиль';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Чоловічий одяг', '{"size": ["XS", "S", "M", "L", "XL", "XXL", "XXXL"], "condition": ["Нове", "Б/в", "Потребує ремонту"]}'::jsonb FROM public.categories WHERE name = 'Мода і стиль';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Чоловіче взуття', '{"size": ["39", "40", "41", "42", "43", "44", "45", "46", "47"], "condition": ["Нове", "Б/в", "Потребує ремонту"]}'::jsonb FROM public.categories WHERE name = 'Мода і стиль';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Жіноча білизна та купальники', '{"size": ["XS", "S", "M", "L", "XL"], "condition": ["Нове", "Б/в"]}'::jsonb FROM public.categories WHERE name = 'Мода і стиль';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Чоловіча білизна та плавки', '{"size": ["S", "M", "L", "XL", "XXL"], "condition": ["Нове", "Б/в"]}'::jsonb FROM public.categories WHERE name = 'Мода і стиль';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Головні убори', '{}'::jsonb FROM public.categories WHERE name = 'Мода і стиль';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Для весілля', '{}'::jsonb FROM public.categories WHERE name = 'Мода і стиль';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Наручні годинники', '{}'::jsonb FROM public.categories WHERE name = 'Мода і стиль';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Аксесуари', '{}'::jsonb FROM public.categories WHERE name = 'Мода і стиль';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Одяг для вагітних', '{"size": ["XS", "S", "M", "L", "XL", "XXL"], "condition": ["Нове", "Б/в"]}'::jsonb FROM public.categories WHERE name = 'Мода і стиль';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Краса / здоров''я', '{}'::jsonb FROM public.categories WHERE name = 'Мода і стиль';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Подарунки', '{}'::jsonb FROM public.categories WHERE name = 'Мода і стиль';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Спецодяг', '{"size": ["S", "M", "L", "XL", "XXL", "XXXL"], "condition": ["Нове", "Б/в", "Потребує ремонту"]}'::jsonb FROM public.categories WHERE name = 'Мода і стиль';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Спецвзуття та аксесуари', '{"size": ["38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48"], "condition": ["Нове", "Б/в", "Потребує ремонту"]}'::jsonb FROM public.categories WHERE name = 'Мода і стиль';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Мода різне', '{}'::jsonb FROM public.categories WHERE name = 'Мода і стиль';

-- Хобі, відпочинок і спорт
INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Антикваріат / колекції', '{}'::jsonb FROM public.categories WHERE name = 'Хобі, відпочинок і спорт';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Музичні інструменти', '{}'::jsonb FROM public.categories WHERE name = 'Хобі, відпочинок і спорт';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Спорт / відпочинок', '{}'::jsonb FROM public.categories WHERE name = 'Хобі, відпочинок і спорт';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Вело', '{}'::jsonb FROM public.categories WHERE name = 'Хобі, відпочинок і спорт';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Мілітарія', '{}'::jsonb FROM public.categories WHERE name = 'Хобі, відпочинок і спорт';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Квадрокоптери та аксесуари', '{}'::jsonb FROM public.categories WHERE name = 'Хобі, відпочинок і спорт';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Книги / журнали', '{}'::jsonb FROM public.categories WHERE name = 'Хобі, відпочинок і спорт';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'CD / DVD / Платівки', '{}'::jsonb FROM public.categories WHERE name = 'Хобі, відпочинок і спорт';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Квитки', '{}'::jsonb FROM public.categories WHERE name = 'Хобі, відпочинок і спорт';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Пошук попутників', '{}'::jsonb FROM public.categories WHERE name = 'Хобі, відпочинок і спорт';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Пошук гуртів / музикантів', '{}'::jsonb FROM public.categories WHERE name = 'Хобі, відпочинок і спорт';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Інше', '{}'::jsonb FROM public.categories WHERE name = 'Хобі, відпочинок і спорт';

-- Віддам безкоштовно
INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Безкоштовно', '{}'::jsonb FROM public.categories WHERE name = 'Віддам безкоштовно';

-- Знайомства
INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Чоловіки, які шукають знайомства', '{"age_range": {"type": "range", "min": 18, "max": 100}}'::jsonb FROM public.categories WHERE name = 'Знайомства';

INSERT INTO public.subcategories (category_id, name, extra_fields) 
SELECT id, 'Жінки, які шукають знайомства', '{"age_range": {"type": "range", "min": 18, "max": 100}}'::jsonb FROM public.categories WHERE name = 'Знайомства'; 