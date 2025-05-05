# nit-helper

**nit-helper** — это кроссплатформенный CLI-инструмент на Dart, предназначенный для автоматизации сборки Flutter и Serverpod проектов. Он аналогичен `flutterfire` и работает как глобальный инструмент (`dart pub global activate`).

Инструмент автоматически определяет нужные директории (`*_flutter`, `*_server`) и выполняет соответствующие команды, с учётом опционального использования `fvm`.

---

## ✨ Возможности

- 📦 Автоматическая сборка Flutter-модулей  
- 🛠 Генерация кода и миграций для Serverpod  
- 🔁 Поддержка `fvm` (Flutter Version Management)  
- 🧠 Умная навигация по структуре проекта  
- 🔧 Команды объединены в единый CLI: `nit-helper`  

---

## 🚀 Установка

```bash
dart pub global activate nit_helper
````

Убедитесь, что путь к глобальным утилитам Dart добавлен в `PATH`:

* **Linux/macOS**:

  ```bash
  export PATH="$PATH:$HOME/.pub-cache/bin"
  ```
* **Windows**:
  Откройте **Свойства системы → Дополнительные параметры → Переменные среды** и добавьте

  ```
  %APPDATA%\Pub\Cache\bin
  ```

  в переменную `Path`.

---

## 🧪 Использование

### 🔨 `build`

Собирает Flutter-проект (ищет директорию, оканчивающуюся на `_flutter`, или работает в текущей, если она таковая).

```bash
nit-helper build
```

С использованием `fvm`:

```bash
nit-helper build --fvm
```

Выполняются команды:

* `dart run build_runner build`
* `fluttergen`

---

### 🖥 `build-server`

Генерирует код Serverpod и применяет миграции. Ищет директорию, оканчивающуюся на `_server`.

```bash
nit-helper build-server
```

Принудительное создание миграций:

```bash
nit-helper build-server --f
```

С использованием `fvm`:

```bash
nit-helper build-server --fvm
```

Выполняются команды:

* `serverpod generate`
* `serverpod create-migration` (или `-f`)
* `dart run bin/main.dart --role maintenance --apply-migrations`

---

### 🔁 `build-full`

Комбинирует `build` и `build-server`:

```bash
nit-helper build-full
```

С опциями:

```bash
nit-helper build-full --fvm --f
```

---

## 🧰 Аргументы

| Аргумент | Команда                      | Описание                       |
| -------- | ---------------------------- | ------------------------------ |
| `--fvm`  | все команды                  | Выполнять через `fvm exec`     |
| `--f`    | `build-server`, `build-full` | Принудительно создать миграции |

---

## 💡 Примеры

```bash
# Сборка Flutter с fvm
nit-helper build --fvm

# Сборка Serverpod с принудительной миграцией
nit-helper build-server --f

# Полная сборка проекта
nit-helper build-full --fvm --f
```

---

## 📂 Структура проекта

```text
project_root/
├── my_app_flutter/
│   └── main.dart
├── my_app_server/
│   └── bin/main.dart
```

`nit-helper` сам определит, где `*_flutter`, где `*_server`, и выполнит команды.

---

## 📜 Лицензия

MIT License.
© 2025 \ Maksim Levchenko

---

## 📫 Обратная связь

Сообщите об ошибках или предложениях:
[GitHub Issues](https://github.com/MaksimLevchenko/nit-helper/issues)