// Дані для підкатегорій з extra fields
final Map<String, Map<String, dynamic>> subcategoriesExtraFields = {
  // Знайомства
  'women_dating': {
    'age_range': {'type': 'range', 'min': 18, 'max': 100},
  },
  'men_dating': {
    'age_range': {'type': 'range', 'min': 18, 'max': 100},
  },

  // Одяг
  'women_clothes': {
    'size': ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'],
    'condition': ['Нове', 'Б/в', 'Потребує ремонту'],
  },
  'men_clothes': {
    'size': ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'],
    'condition': ['Нове', 'Б/в', 'Потребує ремонту'],
  },

  // Взуття
  'women_shoes': {
    'size': List<String>.generate(9, (index) => (34 + index).toString()), // 34-42 EU
    'condition': ['Нове', 'Б/в', 'Потребує ремонту'],
  },
  'men_shoes': {
    'size': List<String>.generate(9, (index) => (39 + index).toString()), // 39-47 EU
    'condition': ['Нове', 'Б/в', 'Потребує ремонту'],
  },

  // Білизна та купальники
  'women_underwear': {
    'size': ['XS', 'S', 'M', 'L', 'XL'],
    'condition': ['Нове', 'Б/в'],
  },
  'men_underwear': {
    'size': ['S', 'M', 'L', 'XL', 'XXL'],
    'condition': ['Нове', 'Б/в'],
  },

  // Спеціальний одяг
  'maternity_clothes': {
    'size': ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
    'condition': ['Нове', 'Б/в'],
  },
  'work_clothes': {
    'size': ['S', 'M', 'L', 'XL', 'XXL', 'XXXL'],
    'condition': ['Нове', 'Б/в', 'Потребує ремонту'],
  },
  'work_shoes': {
    'size': List<String>.generate(11, (index) => (38 + index).toString()), // 38-48
    'condition': ['Нове', 'Б/в', 'Потребує ремонту'],
  },

  // Нерухомість подобово
  'houses_daily': {
    'area': {'type': 'number', 'unit': 'м²'},
    'rooms': {'type': 'number'},
  },
  'apartments_daily': {
    'area': {'type': 'number', 'unit': 'м²'},
    'rooms': {'type': 'number'},
  },
  'rooms_daily': {
    'area': {'type': 'number', 'unit': 'м²'},
  },

  // Транспорт
  'cars': {
    'year': {'type': 'number'},
    'engine_power_hp': {'type': 'number', 'unit': 'к.с.'},
    'car_brand': [
      'Volkswagen', 'BMW', 'Audi', 'Mercedes-Benz', 'Toyota',
      'Renault', 'Skoda', 'Ford', 'Nissan', 'Opel', 'Інше'
    ],
  },
  'cars_poland': {
    'year': {'type': 'number'},
    'engine_power_hp': {'type': 'number', 'unit': 'к.с.'},
    'car_brand': [
      'Volkswagen', 'BMW', 'Audi', 'Mercedes-Benz', 'Toyota',
      'Renault', 'Skoda', 'Ford', 'Nissan', 'Opel', 'Інше'
    ],
  },
  'trucks': {
    'year': {'type': 'number'},
    'engine_power_hp': {'type': 'number', 'unit': 'к.с.'},
  },
  'buses': {
    'year': {'type': 'number'},
    'engine_power_hp': {'type': 'number', 'unit': 'к.с.'},
  },
  'moto': {
    'year': {'type': 'number'},
    'engine_power_hp': {'type': 'number', 'unit': 'к.с.'},
  },
  'special_equipment': {
    'year': {'type': 'number'},
    'engine_power_hp': {'type': 'number', 'unit': 'к.с.'},
  },
  'agricultural': {
    'year': {'type': 'number'},
    'engine_power_hp': {'type': 'number', 'unit': 'к.с.'},
  },
  'water_transport': {
    'year': {'type': 'number'},
    'engine_power_hp': {'type': 'number', 'unit': 'к.с.'},
  },
  'trailers': {
    'year': {'type': 'number'},
    'engine_power_hp': {'type': 'number', 'unit': 'к.с.'},
  },
  'trucks_poland': {
    'year': {'type': 'number'},
    'engine_power_hp': {'type': 'number', 'unit': 'к.с.'},
  },
  'other_transport': {
    'year': {'type': 'number'},
  },

  // Нерухомість
  'apartments': {
    'area': {'type': 'number', 'unit': 'м²'},
    'rooms': {'type': 'number'},
  },
  'rooms': {
    'area': {'type': 'number', 'unit': 'м²'},
  },
  'houses': {
    'area': {'type': 'number', 'unit': 'м²'},
    'rooms': {'type': 'number'},
  },
  'commercial': {
    'area': {'type': 'number', 'unit': 'м²'},
  },
  'garages': {
    'area': {'type': 'number', 'unit': 'м²'},
  },
  'foreign': {
    'area': {'type': 'number', 'unit': 'м²'},
  },
};

// Функція для отримання extra fields для конкретної підкатегорії
Map<String, dynamic>? getExtraFieldsForSubcategory(String subcategoryId) {
  return subcategoriesExtraFields[subcategoryId];
}

// Функція для отримання назви поля для відображення
String getFieldDisplayName(String fieldName) {
  switch (fieldName) {
    // Знайомства
    case 'age_range':
      return 'Вік';
    
    // Авто
    case 'year':
      return 'Рік випуску';
    case 'brand':
      return 'Марка';
    case 'car_brand':
      return 'Марка авто';
    case 'engine_hp':
      return 'Потужність двигуна';
    case 'engine_power_hp':
      return 'Двигун (к.с.)';
    case 'mileage':
      return 'Пробіг (км)';
    case 'fuel_type':
      return 'Тип палива';
    case 'transmission':
      return 'Коробка передач';
    case 'body_type':
      return 'Тип кузова';
    case 'color':
      return 'Колір';
    
    // Нерухомість
    case 'area':
      return 'Площа (м²)';
    case 'square_meters':
      return 'Площа (м²)';
    case 'rooms':
      return 'Кількість кімнат';
    case 'floor':
      return 'Поверх';
    case 'total_floors':
      return 'Всього поверхів';
    case 'property_type':
      return 'Тип нерухомості';
    case 'renovation':
      return 'Ремонт';
    case 'furniture':
      return 'Меблі';
    case 'balcony':
      return 'Балкон';
    case 'parking':
      return 'Парковка';
    
    // Електроніка
    case 'model':
      return 'Модель';
    case 'memory':
      return 'Пам\'ять';
    case 'storage':
      return 'Накопичувач';
    case 'processor':
      return 'Процесор';
    case 'screen_size':
      return 'Розмір екрану';
    case 'battery':
      return 'Батарея';
    
    // Одяг
    case 'size':
      return 'Розмір';
    case 'material':
      return 'Матеріал';
    case 'season':
      return 'Сезон';
    case 'style':
      return 'Стиль';
    case 'gender':
      return 'Стать';
    
    // Загальні
    case 'condition':
      return 'Стан';
    case 'warranty':
      return 'Гарантія';
    case 'delivery':
      return 'Доставка';
    case 'payment':
      return 'Оплата';
    
    default:
      // Конвертуємо snake_case в Title Case
      return fieldName
          .split('_')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
  }
} 