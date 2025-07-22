// @deno-types="npm:@types/deno@latest"
// supabase/functions/sync-to-algolia/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import algoliasearch from "npm:algoliasearch";

// Ініціалізація клієнта Algolia
// Ці секрети ми додамо в налаштуваннях проєкту Supabase
const ALGOLIA_APP_ID = Deno.env.get("ALGOLIA_APP_ID")!;
const ALGOLIA_ADMIN_KEY = Deno.env.get("ALGOLIA_ADMIN_KEY")!;
const ALGOLIA_INDEX_NAME = "products";

const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
const index = client.initIndex(ALGOLIA_INDEX_NAME);

console.log("Функція синхронізації з Algolia запущена.");

serve(async (req) => {
  try {
    const payload = await req.json();
    console.log("Отримано payload:", JSON.stringify(payload, null, 2));

    const { type, record, old_record } = payload;

    // В Algolia `objectID` - це унікальний ідентифікатор.
    // Ми будемо використовувати `id` з нашої таблиці Supabase.
    const objectID = type === 'DELETE' ? old_record.id : record.id;
    if (!objectID) {
      throw new Error("ID запису відсутній, неможливо синхронізувати з Algolia.");
    }

    switch (type) {
      case "INSERT":
        // Нові записи додаємо в Algolia
        console.log(`Зберігаємо об'єкт ${objectID} в Algolia...`);
        await index.saveObject({
          objectID,
          ...record,
        });
        console.log(`Об'єкт ${objectID} успішно збережено.`);
        break;

      case "UPDATE":
        // Оновлені записи оновлюємо і в Algolia
        console.log(`Оновлюємо об'єкт ${objectID} в Algolia...`);
        await index.saveObject({
          objectID,
          ...record,
        });
        console.log(`Об'єкт ${objectID} успішно оновлено.`);
        break;

      case "DELETE":
        // Видалені записи видаляємо з Algolia
        console.log(`Видаляємо об'єкт ${objectID} з Algolia...`);
        await index.deleteObject(objectID);
        console.log(`Об'єкт ${objectID} успішно видалено.`);
        break;

      default:
        console.warn(`Необроблений тип події: ${type}`);
        break;
    }

    return new Response(JSON.stringify({ success: true, type, objectID }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Помилка обробки запиту:", error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
