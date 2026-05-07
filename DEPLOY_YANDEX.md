# Инструкция по деплою в Yandex Cloud Functions

## Обновлённая функция (fix for photo upload)

Файл `cloud_function.zip` готов к деплою.

## Способ 1: Через веб-консоль (рекомендуется)

1. Открой [Yandex Cloud Console](https://console.cloud.yandex.net/)
2. Перейди в **Serverless** → **Functions**
3. Выбери функцию с ID `d4e7c6mrr9bjtglvfdd9`
4. Вкладка **"Версии"** → кнопка **"Загрузить версию"**
5. Выбери файл `cloud_function.zip` из корня проекта
6. Убедись, что **Handler** установлен как `uploadToGitHub`
7. Нажми **"Сохранить"**
8. Подожди 1-2 минуты до завершения деплоя

## Способ 2: Через Yandex CLI

Если у тебя установлен Yandex CLI:

```bash
# Авторизуйся (если ещё не авторизован)
yc init

# Перейди в папку с архивом
cd D:\Stardust

# Задеплой функцию
yc serverless function version create \
  --function-id d4e7c6mrr9bjtglvfdd9 \
  --deployment-package-path cloud_function.zip \
  --runtime nodejs18 \
  --entrypoint uploadToGitHub
```

## Проверка

После деплоя:
1. Открой [http://localhost:8080](http://localhost:8080)
2. Попробуй загрузить фото
3. Ошибка 500 должна исчезнуть

## Примечания

- Функция теперь принимает `{'data': base64Content}` вместо `{'content': ...}`
- Также поддерживает старый формат для обратной совместимости
- Ответ содержит поле `downloadUrl` с ссылкой на изображение
