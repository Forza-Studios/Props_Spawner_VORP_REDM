# vorp_prop_gizmo

---

## Бета-версия

Этот ресурс находится в **стадии бета-тестирования**: возможны ошибки, изменения поведения и обновления без предупреждения. Сообщайте о проблемах в Discord: [https://discord.gg/MWY6JYZp](https://discord.gg/MWY6JYZp).

**Код частично закрытый** — не весь исходный код доступен или открыт для свободного изменения.

---

## Beta version

This resource is in **beta**: bugs, behavior changes, and updates may occur without notice. Please report issues in Discord: [https://discord.gg/MWY6JYZp](https://discord.gg/MWY6JYZp).

**The code is partially closed** — not all source is available or open for unrestricted modification.

---

## RU — Что это и для чего

**Что это:** клиентский инструмент для RedM (VORP): каталог пропов в NUI, предпросмотр и **расстановка объектов в мире** с сохранением на сервере (команда `/gizmo`).

**Для чего:** удобно искать модели по категориям, ставить декорации и сценарные объекты без ручного ввода координат, вести список уже поставленных пропов.

---

## EN — What it is and what it’s for

**What it is:** a RedM (VORP) client tool: an NUI prop catalog, preview, and **in-world prop placement** persisted on the server (`/gizmo` command).

**What it’s for:** browse models by category, place set-dressing and scene props without typing coordinates manually, and manage a list of placed props.

---

## RU — Установка и зависимости

1. Папку ресурса положите в каталог сервера (например `resources/[VORP]/vorp_prop_gizmo`).
2. В `server.cfg` сначала запустите **одно** ядро: `ensure vorp_core` **или** `ensure rsg-core`, затем `ensure vorp_prop_gizmo`.
3. **Фреймворк:** в `config.lua` **`Config.Framework`**: `"auto"` (ищет `vorp_core`, затем `rsg-core` / `rsg_core`), либо явно `"vorp"` / `"rsg"`. Для RSG при нестандартном имени ресурса задайте **`Config.RsgCoreResource`**. Доступ по **`AdminGroups`** на RSG — это **ACE-строки** (`HasPermission`), как у стокового `admin` в rsg-core.
4. Настройте `config.lua` (язык, права доступа, дистанции, при необходимости пути к данным).
5. Убедитесь, что на месте файлы из `files` манифеста: `data/bank_props.json`, `data/spooni_catalog.json` (или актуальный каталог по вашему пайплайну), а также папка `html/` с UI.

**RedM / RDR3** — ресурс рассчитан на Red Dead Redemption 2 в сборке RedM, не на GTA/FiveM.

### RU — Файл `placed_props_sync.json`

В **папке ресурса на сервере** (рядом с `fxmanifest.lua`) хранится файл **`placed_props_sync.json`** — в нём записаны **все пропы, уже размещённые** через гизмо: модель, координаты, углы поворота и связанные данные. Файл создаётся/обновляется сервером при установке и удалении пропов. Имя файла можно задать в `config.lua`: параметр **`Config.ServerPlacedPropsFile`** (по умолчанию `placed_props_sync.json`). Делайте резервные копии этого файла при переносе сервера или бэкапах мира.

---

## EN — Installation and requirements

1. Copy the resource folder into your server resources (e.g. `resources/[VORP]/vorp_prop_gizmo`).
2. In `server.cfg`, start **either** [vorp_core](https://github.com/VORPCORE/vorp_core-lua) **or** [rsg-core](https://github.com/Rexshack-RedM/rsg-core) first, then `ensure vorp_prop_gizmo`.
3. **Framework:** **`Config.Framework`**: `"auto"` (tries `vorp_core`, then `rsg-core` / `rsg_core`), or `"vorp"` / `"rsg"`. If your RSG core resource is renamed, set **`Config.RsgCoreResource`**. On RSG, **`AdminGroups`** are **ACE permission strings** (same as `HasPermission` in rsg-core, e.g. `admin`).
4. Edit `config.lua` (language, permissions, distances, data options as needed).
5. Keep manifest `files` present: `data/bank_props.json`, `data/spooni_catalog.json` (or your updated catalog), and the `html/` UI assets.

**RedM / RDR3** — this is for RedM, not GTA/FiveM.

### EN — `placed_props_sync.json`

On the **server**, inside the resource folder (next to `fxmanifest.lua`), the file **`placed_props_sync.json`** stores **all props placed** via the gizmo: model name, coordinates, rotation, and related fields. The server creates/updates it when props are placed or removed. You can change the filename in `config.lua`: **`Config.ServerPlacedPropsFile`** (default `placed_props_sync.json`). Back up this file when migrating the server or saving your world.

---

## RU — Стандартная дистанция прогрузки

Уже **расставленные в мире** пропы на клиенте подгружаются по радиусу от игрока:

| Параметр | Значение по умолчанию | Смысл |
|----------|----------------------|--------|
| **`Config.PlacedPropLoadDistance`** | **180** м | в этом радиусе сущность пропа **спавнится** у игрока |
| **`Config.PlacedPropUnloadDistance`** | **220** м | дальше этого расстояния проп **снимается** с клиента (должно быть не меньше радиуса загрузки) |

Дополнительно: **`PlacedStreamRefreshMs`** (по умолчанию 1200) — как часто пересчитывается стриминг; **`PlacedStreamSpawnBudgetPerTick`** (12) — сколько пропов за один проход можно заспавнить (защита от просадки FPS). Старые имена **`PlacedStreamDistance`** / **`PlacedDespawnDistance`** в коде ещё поддерживаются, если новые ключи не заданы.

---

## EN — Default stream distance

**World-placed** props are spawned on each client by distance from the player:

| Setting | Default | Meaning |
|---------|---------|---------|
| **`Config.PlacedPropLoadDistance`** | **180** m | props **spawn** when you are within this radius |
| **`Config.PlacedPropUnloadDistance`** | **220** m | props **despawn** when farther (should be ≥ load radius) |

Also: **`PlacedStreamRefreshMs`** (default 1200) — how often streaming is refreshed; **`PlacedStreamSpawnBudgetPerTick`** (12) — max props spawned per pass (FPS safety). Legacy keys **`PlacedStreamDistance`** / **`PlacedDespawnDistance`** still work if the new keys are unset.

---

## RU — Кратко про `config.lua`

- **`Framework`** — `auto` / `vorp` / `rsg`; **`RsgCoreResource`** — имя ресурса rsg-core при отличии от `rsg-core`.
- **`Language`** — `en` / `ru` (интерфейс и часть уведомлений).
- **`CommandAccess`** — группы админов и/или профессии, кому доступна команда **`/gizmo`**.
- **`CategoryAccess`** — какие категории и подкатегории каталога показывать или скрывать (глобально и по работам).
- **`PlaceStepForward` / `Side` / `Up` / `Rotate` / `Pitch` / `Roll`** — шаг перемещения и поворота при расстановке.
- **`PlaceMovementMaxRadius`** — максимальное расстояние от игрока до превью при движении (**8** м по умолчанию; **`0`** = без ограничения). Старое имя: `PlaceMaxDistance`.
- **`PlaceSpeedSlider*`** — диапазон ползунка скорости в панели расстановки.
- **`SpawnDistance`**, **`SpawnHeightOffset`** — где появляется призрак относительно игрока при старте расстановки.
- **`ServerPlacedPropsFile`** — JSON с сохранёнными пропами (см. выше).
- **`PlaceMaxDistanceCheck`** — лимит дистанции при отправке установки на сервер (античит, по умолчанию **30** м; **`0`** = выкл.).
- **`PlacedPropLoadDistance`**, **`PlacedPropUnloadDistance`**, **`PlacedStreamRefreshMs`**, **`PlacedStreamSpawnBudgetPerTick`** — клиентский стриминг уже поставленных пропов.
- **`PlacedListPageSize`**, **`CatalogPageSize`** — пагинация в NUI при больших списках.
- **`PropThumbnailBaseUrl`** — базовый URL картинок превью; пусто = только локальные файлы в `html/img/`.
- **`NuiWrapSpooniPropsRoot`**, **`NuiExpandSpooniRootOnOpen`** — вид дерева категорий Spooni в сайдбаре.
- **`SpooniFetchCatalogOnResourceStart`**, **`SpooniSupabaseUrl`**, **`SpooniSupabaseAnonKey`** — авто-загрузка каталога с Supabase при старте ресурса.
- **`CatalogHintIfSingleCategory`** — подсказка в игре, если в каталоге мало верхнеуровневых категорий.

Полные комментарии к каждому полю — в самом файле **`config.lua`**.

---

## EN — `config.lua` quick reference

- **`Framework`** — `auto` / `vorp` / `rsg`; **`RsgCoreResource`** — RSG resource name if not `rsg-core`.
- **`Language`** — `en` / `ru` (UI and some notifications).
- **`CommandAccess`** — admin groups and/or jobs allowed to use **`/gizmo`**.
- **`CategoryAccess`** — allow/deny catalog tabs and blocks (global and per-job).
- **`PlaceStep*`** — nudge sizes for move/rotate while placing.
- **`PlaceMovementMaxRadius`** — max distance from player to placement ghost (**8** m default; **`0`** = unlimited). Legacy: `PlaceMaxDistance`.
- **`PlaceSpeedSlider*`** — min/max/step for the placement speed slider.
- **`SpawnDistance`**, **`SpawnHeightOffset`** — initial ghost spawn offset from the player.
- **`ServerPlacedPropsFile`** — JSON file for saved props (see above).
- **`PedsCatalogFile`**, **`BlipsCatalogFile`** — JSON lists for the **Peds** / **Blips** sidebar tabs.
- **`ServerPlacedBlipsFile`** — persisted placed blips (synced for all players).
- **`RedLookupBaseUrl`**, **`RedLookupPedImageUrl`**, **`RedLookupBlipImageUrl`** — card thumbnails from [RedLookup](https://redlookup.com); URLs may use `{name}` and `{sprite}`. If previews 404, open RedLookup in a browser, inspect a working image request, and paste the pattern into config.
- **`PedSpawnDistance`**, **`PedSpawnHeightOffset`** — spawn position for the **Spawn** button on the Peds tab.
- **`BlipStyle`**, **`BlipScale`** — map blip appearance for placed blips.
- **`PlaceMaxDistanceCheck`** — server-side max distance when submitting a placement (**30** m default; **`0`** = off).
- **`PlacedPropLoadDistance`**, **`PlacedPropUnloadDistance`**, **`PlacedStreamRefreshMs`**, **`PlacedStreamSpawnBudgetPerTick`** — client streaming for world props.
- **`PlacedListPageSize`**, **`CatalogPageSize`** — NUI pagination for large lists.
- **`PropThumbnailBaseUrl`** — remote thumbnail base URL; empty = local `html/img/` only.
- **`NuiWrapSpooniPropsRoot`**, **`NuiExpandSpooniRootOnOpen`** — Spooni category tree layout.
- **`SpooniFetchCatalogOnResourceStart`**, **`SpooniSupabaseUrl`**, **`SpooniSupabaseAnonKey`** — optional Supabase catalog fetch on resource start.
- **`CatalogHintIfSingleCategory`** — in-game hint when the catalog has few top-level categories.

See **`config.lua`** for inline comments on every option.

---

## RU — Пропы Spooni

Каталог может содержать **имена** пропов Spooni, но сами модели **не поставляются** этим скриптом. Чтобы они появлялись в игре, нужны **официальные ассеты** (стриминг и т.п.). Их нужно приобрести на официальном магазине Spooni: [https://spooni.pages.dev/store](https://spooni.pages.dev/store). Без покупки и подключения контента пропы Spooni **работать не будут** (ошибки загрузки модели и т.д.).

## RU — Вкладки Peds и Blips (RedLookup)

- Список **педов** задаётся в `data/peds_catalog.json` (массив строк-имён моделей); превью карточек берутся с [redlookup.com/peds](https://redlookup.com/peds?p=1) через настраиваемые URL в `config.lua` (`RedLookup*`).
- Список **блипов** — `data/blips_catalog.json` (`name` + `sprite`); размещение синхронизируется и хранится в `placed_blips_sync.json`.
- Если картинки не грузятся, сайт мог сменить пути: откройте RedLookup в браузере → DevTools → Network → скопируйте рабочий URL картинки и задайте `RedLookupPedImageUrl` / `RedLookupBlipImageUrl` с плейсхолдерами `{name}` и при необходимости `{sprite}`.

---

## EN — Spooni props

The catalog may list **Spooni prop names**, but this script does **not** ship Spooni model assets. For models to spawn in-game you need the **official Spooni content** (streaming assets, etc.), purchased from the official store: [https://spooni.pages.dev/store](https://spooni.pages.dev/store). Without that purchase and proper asset setup, Spooni props **will not work** (e.g. model load failures).

## EN — Peds & Blips tabs (RedLookup)

- **Peds** list is `data/peds_catalog.json` (array of model name strings). Card thumbnails are resolved from [redlookup.com/peds](https://redlookup.com/peds?p=1) using `RedLookupBaseUrl` / optional `RedLookupPedImageUrl` in `config.lua`.
- **Blips** catalog is `data/blips_catalog.json` (`name` + `sprite`). Placed blips sync to everyone and persist in `placed_blips_sync.json`.
- If thumbnails 404, RedLookup may have changed CDN paths: inspect a working image URL in the browser and set `RedLookupPedImageUrl` / `RedLookupBlipImageUrl` with `{name}` (and `{sprite}` if needed).

---

## Поддержка / Support

**Discord:** [https://discord.gg/MWY6JYZp](https://discord.gg/MWY6JYZp) — вопросы, баги и обратная связь по этой бета-версии.

---

*SPOONI store (official): [spooni.pages.dev/store](https://spooni.pages.dev/store)*
