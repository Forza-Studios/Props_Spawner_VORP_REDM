(function () {
    var resourceName = 'vorp_prop_gizmo';
    var catalogTree = {};
    var allProps = [];
    var currentView = 'all';
    var categoryCatKey = null;
    var categorySubKey = null;
    var placedList = [];
    var placedPage = 1;
    var placedPageSize = 100;
    /** '' = all; '__none__' = props not in any folder; else folder id */
    var placedFolderFilter = '';
    /** Server-synced folders: { id, name, propIds: [] } */
    var placedFolders = [];
    var playerSkinSelectedModel = null;
    var catalogPage = 1;
    var catalogPageSize = 120;
    var favoritesCache = [];
    var searchQuery = '';
    var thumbBase = '';
    var lang = 'ru';
    var skinRosterCache = { online: [], history: [] };
    /** Match site: categories nested under “Spooni Props”. */
    var wrapSpooniRoot = true;
    /** If wrap on: start with Spooni group expanded. */
    var spooniRootExpanded = true;
    var pedsCatalog = [];
    var blipsCatalog = [];
    var blipNameToRow = {};
    var redLookupBaseUrl = 'https://redlookup.com';
    var redLookupPedImageUrl = '';
    var redLookupBlipImageUrl = '';

    var textModalResolve = null;
    var confirmModalResolve = null;

    /** Legacy prop-only favorites key (migrated once). */
    var FAV_KEY = 'prop_gizmo_favorites';
    /** Unified: entries like prop:name, ped:name, blip:name */
    var FAV_UNIFIED_KEY = 'prop_gizmo_favorites_unified';
    var I18N = {
        en: {
            categories: 'Categories',
            allProps: 'All Props',
            favorites: 'Favorites',
            peds: 'Peds',
            blips: 'Blips',
            placed: 'Placed',
            spawnPed: 'Spawn',
            title: 'Props Gallery',
            searchPlaceholder: 'Search props, peds, blips…',
            placement: 'Placement',
            move: 'Move',
            speed: 'Speed',
            freeMove: 'Free move (WASD + mouse + V)',
            rotate: 'Rotate (Z)',
            height: 'Height',
            pitch: 'Pitch',
            roll: 'Roll',
            place: 'Place',
            resetPosition: 'Reset position',
            cancel: 'Cancel',
            hintEsc: 'ESC - cancel. Hold LMB on move buttons.',
            noPreview: 'No preview',
            copy: 'Copy',
            placeBtn: 'Place',
            nothingFound: 'Nothing found.',
            noPlacedYet: 'No placed props, blips, or spawned peds yet.',
            noSearchPlaced: 'No matches for your search.',
            pedBadge: 'Ped',
            pedImmortal: 'Immortal',
            pedFrozen: 'Frozen in place',
            pedMissing: 'not in world',
            tableModel: 'Model',
            tableCoords: 'Coords',
            teleport: 'Teleport',
            copyCoords: 'Copy coords',
            del: 'Delete',
            copied: 'Copied',
            copyFailed: 'Copy failed',
            prev: 'Prev',
            next: 'Next',
            page: 'Page',
            propsTotal: 'Props',
            playerSkinNav: 'Player skin',
            playerSkinTitle: 'Player skin',
            playerSkinHint: 'Type a ped name below and/or pick a card, then Save & apply. Target: leave both empty = you; or server id (number from scoreboard); or full steam:… from F8 (hex after steam:). "Select" only picks a card — it does not change your ped until you press Save & apply. May conflict with vorp_character / multichar.',
            playerSkinSteamPh: 'steam:1100001ab… (optional, full from F8)',
            playerSkinServerIdPh: 'Server id (optional)',
            playerSkinModelPh: 'Ped model e.g. a_c_horse_01',
            playerSkinSelected: 'Selected',
            playerSkinApply: 'Save & apply',
            playerSkinDelete: 'Delete skin',
            playerSkinTargetSelf: 'Who: you (your character)',
            playerSkinTargetId: 'Who: server player #',
            playerSkinTargetSteam: 'Who: Steam',
            placedFolderFilter: 'Folder filter',
            placedFolderAll: 'All',
            placedFolderNone: 'Not in any folder',
            placedFolderCol: 'Folders',
            placedNewFolder: 'New folder',
            placedPickFolder: 'Add prop to folder…',
            placedDeleteFolder: 'Delete folder',
            placedRemoveFromFolder: 'Remove from this folder',
            skinSelect: 'Select',
            placedActions: 'Actions',
            folderNamePrompt: 'Folder name',
            folderDeleteConfirm: 'Delete this folder? Props stay in the world.',
            modalOk: 'OK',
            modalCancel: 'Cancel',
            skinRosterTitle: 'Who has a saved skin',
            skinRosterOnline: 'Online (saved skin)',
            skinRosterHistory: 'Recent assignments',
            skinRosterRefresh: 'Refresh list',
            skinRosterColTime: 'Time',
            skinRosterColAdmin: 'By',
            skinRosterColPlayer: 'Player',
            skinRosterColModel: 'Model',
            skinRosterColName: 'Name',
            skinRosterColId: 'Server ID',
            skinRosterColActions: '\u00a0',
            skinRosterDeleteSkin: 'Remove saved skin for this player',
            skinRosterEmpty: 'No data yet.',
        },
        ru: {
            categories: 'Категории',
            allProps: 'Все пропы',
            favorites: 'Избранное',
            peds: 'Педы',
            blips: 'Блипы',
            placed: 'Установленные',
            spawnPed: 'Спавн',
            title: 'Галерея пропов',
            searchPlaceholder: 'Поиск пропов, педов, блипов…',
            placement: 'Размещение',
            move: 'Движение',
            speed: 'Скорость',
            freeMove: 'Свободное управление (WASD + мышь + V)',
            rotate: 'Поворот (Z)',
            height: 'Высота',
            pitch: 'Наклон',
            roll: 'Крен',
            place: 'Установить',
            resetPosition: 'Сброс позиции',
            cancel: 'Отмена',
            hintEsc: 'ESC - отмена. Удерживайте ЛКМ на кнопках движения.',
            noPreview: 'Нет превью',
            copy: 'Копировать',
            placeBtn: 'Установить',
            nothingFound: 'Ничего не найдено.',
            noPlacedYet: 'Пока нет пропов, блипов или заспавненных педов.',
            noSearchPlaced: 'Нет совпадений по поиску.',
            pedBadge: 'Пед',
            pedImmortal: 'Бессмертный',
            pedFrozen: 'Заморожен на месте',
            pedMissing: 'нет в мире',
            tableModel: 'Модель',
            tableCoords: 'Координаты',
            teleport: 'Телепорт',
            copyCoords: 'Копировать координаты',
            del: 'Удалить',
            copied: 'Скопировано',
            copyFailed: 'Не удалось скопировать',
            prev: 'Назад',
            next: 'Далее',
            page: 'Страница',
            propsTotal: 'Пропов',
            playerSkinNav: 'Скин игрока',
            playerSkinTitle: 'Скин игрока',
            playerSkinHint: 'Введите имя педа ниже и/или выберите карточку, затем «Сохранить и применить». Цель: оба поля пусты = вы; или id игрока на сервере; или полный steam:… из F8 (после steam: буквы a–f). «Выбрать» только отмечает карточку — модель не применится, пока не нажмёте «Сохранить и применить». Может конфликтовать с vorp_character / multichar.',
            playerSkinSteamPh: 'steam:1100001ab… (необязательно, целиком из F8)',
            playerSkinServerIdPh: 'ID игрока на сервере (необязательно)',
            playerSkinModelPh: 'Модель педа, напр. a_c_horse_01',
            playerSkinSelected: 'Выбрано',
            playerSkinApply: 'Сохранить и применить',
            playerSkinDelete: 'Удалить скин',
            playerSkinTargetSelf: 'Кому: вы сами',
            playerSkinTargetId: 'Кому: игрок с ID сервера ',
            playerSkinTargetSteam: 'Кому: ',
            placedFolderFilter: 'Фильтр папки',
            placedFolderAll: 'Все',
            placedFolderNone: 'Без папки',
            placedFolderCol: 'Папки',
            placedNewFolder: 'Новая папка',
            placedPickFolder: 'Добавить проп в папку…',
            placedDeleteFolder: 'Удалить папку',
            placedRemoveFromFolder: 'Убрать из этой папки',
            skinSelect: 'Выбрать',
            placedActions: 'Действия',
            folderNamePrompt: 'Имя папки',
            folderDeleteConfirm: 'Удалить папку? Пропы в мире останутся.',
            modalOk: 'ОК',
            modalCancel: 'Отмена',
            skinRosterTitle: 'Кому выдан скин',
            skinRosterOnline: 'Сейчас онлайн (есть сохранённый скин)',
            skinRosterHistory: 'Последние назначения',
            skinRosterRefresh: 'Обновить список',
            skinRosterColTime: 'Время',
            skinRosterColAdmin: 'Кто выдал',
            skinRosterColPlayer: 'Игрок',
            skinRosterColModel: 'Модель',
            skinRosterColName: 'Имя',
            skinRosterColId: 'ID сервера',
            skinRosterColActions: '\u00a0',
            skinRosterDeleteSkin: 'Снять сохранённый скин с этого игрока',
            skinRosterEmpty: 'Пока нет данных.',
        }
    };

    function tr(key) {
        var dict = I18N[lang] || I18N.en;
        return dict[key] || (I18N.en[key] || key);
    }

    function copyTextToClipboard(text, onDone) {
        function done(ok) {
            if (typeof onDone === 'function') onDone(ok);
        }
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).then(function () {
                done(true);
            }).catch(function () {
                var ta = document.createElement('textarea');
                ta.value = text;
                ta.setAttribute('readonly', 'readonly');
                ta.style.position = 'fixed';
                ta.style.left = '-9999px';
                document.body.appendChild(ta);
                ta.select();
                var ok = false;
                try { ok = document.execCommand('copy'); } catch (e) { ok = false; }
                document.body.removeChild(ta);
                done(ok);
            });
            return;
        }
        var ta = document.createElement('textarea');
        ta.value = text;
        ta.setAttribute('readonly', 'readonly');
        ta.style.position = 'fixed';
        ta.style.left = '-9999px';
        document.body.appendChild(ta);
        ta.select();
        var ok2 = false;
        try { ok2 = document.execCommand('copy'); } catch (e2) { ok2 = false; }
        document.body.removeChild(ta);
        done(ok2);
    }

    function getRes() {
        return typeof GetParentResourceName !== 'undefined' ? GetParentResourceName() : resourceName;
    }

    function post(callbackName, data) {
        fetch('https://' + getRes() + '/' + callbackName, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data || {})
        }).catch(function () {});
    }

    function isTextModalOpen() {
        var el = document.getElementById('nui-text-modal');
        return el && !el.classList.contains('hidden');
    }

    function isConfirmModalOpen() {
        var el = document.getElementById('nui-confirm-modal');
        return el && !el.classList.contains('hidden');
    }

    function closeTextModalWithValue(value) {
        var root = document.getElementById('nui-text-modal');
        if (root) root.classList.add('hidden');
        var fn = textModalResolve;
        textModalResolve = null;
        if (typeof fn === 'function') fn(value);
    }

    function closeConfirmModalWithValue(value) {
        var root = document.getElementById('nui-confirm-modal');
        if (root) root.classList.add('hidden');
        var fn = confirmModalResolve;
        confirmModalResolve = null;
        if (typeof fn === 'function') fn(!!value);
    }

    function openTextModal(title, defaultValue) {
        return new Promise(function (resolve) {
            textModalResolve = resolve;
            var root = document.getElementById('nui-text-modal');
            var tit = document.getElementById('nui-text-modal-title');
            var inp = document.getElementById('nui-text-modal-input');
            if (tit) tit.textContent = title || '';
            if (inp) {
                inp.value = defaultValue != null ? String(defaultValue) : '';
            }
            if (root) root.classList.remove('hidden');
            if (inp) {
                setTimeout(function () {
                    inp.focus();
                    inp.select();
                }, 30);
            }
        });
    }

    function openConfirmModal(message) {
        return new Promise(function (resolve) {
            confirmModalResolve = resolve;
            var root = document.getElementById('nui-confirm-modal');
            var msg = document.getElementById('nui-confirm-modal-msg');
            if (msg) msg.textContent = message || '';
            if (root) root.classList.remove('hidden');
        });
    }

    function relabelNuiModalButtons() {
        var ok = document.getElementById('nui-text-modal-ok');
        var ca = document.getElementById('nui-text-modal-cancel');
        if (ok) ok.textContent = tr('modalOk');
        if (ca) ca.textContent = tr('modalCancel');
        var cok = document.getElementById('nui-confirm-modal-ok');
        var cca = document.getElementById('nui-confirm-modal-cancel');
        if (cok) cok.textContent = tr('modalOk');
        if (cca) cca.textContent = tr('modalCancel');
    }

    function initNuiModals() {
        relabelNuiModalButtons();
        var ok = document.getElementById('nui-text-modal-ok');
        var ca = document.getElementById('nui-text-modal-cancel');
        if (ok) ok.addEventListener('click', function () {
            var inp = document.getElementById('nui-text-modal-input');
            closeTextModalWithValue(inp ? inp.value : '');
        });
        if (ca) ca.addEventListener('click', function () {
            closeTextModalWithValue(null);
        });
        var inpEl = document.getElementById('nui-text-modal-input');
        if (inpEl) {
            inpEl.addEventListener('keydown', function (e) {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    closeTextModalWithValue(inpEl.value);
                }
            });
        }
        var cok = document.getElementById('nui-confirm-modal-ok');
        var cca = document.getElementById('nui-confirm-modal-cancel');
        if (cok) cok.addEventListener('click', function () {
            closeConfirmModalWithValue(true);
        });
        if (cca) cca.addEventListener('click', function () {
            closeConfirmModalWithValue(false);
        });
        document.querySelectorAll('.nui-modal-backdrop').forEach(function (bd) {
            bd.addEventListener('click', function (ev) {
                var root = ev.target && ev.target.closest && ev.target.closest('.nui-modal');
                if (!root) return;
                if (root.id === 'nui-text-modal') closeTextModalWithValue(null);
                if (root.id === 'nui-confirm-modal') closeConfirmModalWithValue(false);
            });
        });
    }

    function migrateLegacyFavorites() {
        try {
            if (localStorage.getItem(FAV_UNIFIED_KEY)) return;
            var raw = localStorage.getItem(FAV_KEY);
            if (!raw) return;
            var arr = JSON.parse(raw);
            if (!Array.isArray(arr)) return;
            var next = [];
            for (var i = 0; i < arr.length; i++) {
                var m = arr[i];
                if (typeof m !== 'string' || m === '') continue;
                if (m.indexOf('prop:') === 0 || m.indexOf('ped:') === 0 || m.indexOf('blip:') === 0) {
                    next.push(m);
                } else {
                    next.push('prop:' + m);
                }
            }
            localStorage.setItem(FAV_UNIFIED_KEY, JSON.stringify(next));
        } catch (e) {}
    }

    function loadUnifiedFavorites() {
        migrateLegacyFavorites();
        try {
            var raw = localStorage.getItem(FAV_UNIFIED_KEY);
            if (!raw) return [];
            var arr = JSON.parse(raw);
            return Array.isArray(arr) ? arr : [];
        } catch (e2) {
            return [];
        }
    }

    function saveUnifiedFavorites(arr) {
        try {
            localStorage.setItem(FAV_UNIFIED_KEY, JSON.stringify(arr));
        } catch (e) {}
    }

    function refreshFavoritesCache() {
        favoritesCache = loadUnifiedFavorites();
    }

    function favEntryKey(kind, ref) {
        if (kind === 'blip' && ref && typeof ref.name === 'string') return 'blip:' + ref.name;
        if (kind === 'ped') return 'ped:' + String(ref);
        return 'prop:' + String(ref);
    }

    function isFavoriteKey(key) {
        return favoritesCache.indexOf(key) !== -1;
    }

    function toggleFavoriteKey(key) {
        var f = favoritesCache.slice();
        var i = f.indexOf(key);
        if (i === -1) f.push(key);
        else f.splice(i, 1);
        saveUnifiedFavorites(f);
        favoritesCache = f;
        render();
    }

    function matchesSearch(name) {
        if (!searchQuery) return true;
        return String(name || '').toLowerCase().indexOf(searchQuery.toLowerCase()) !== -1;
    }

    function labelCat(s) {
        if (!s) return '';
        return String(s).split(/[\s_]+/).filter(Boolean).map(function (w) {
            return w.charAt(0).toUpperCase() + w.slice(1).toLowerCase();
        }).join(' ');
    }

    /** RedM/Cfx иногда отдаёт списки пропов как объект { "0": "…", "1": "…" }, не как массив. */
    function isPropIdList(v) {
        if (!v || typeof v !== 'object') return false;
        if (Array.isArray(v)) return v.every(function (x) { return typeof x === 'string'; });
        var keys = Object.keys(v);
        if (keys.length === 0) return false;
        for (var i = 0; i < keys.length; i++) {
            if (!/^\d+$/.test(keys[i])) return false;
            if (typeof v[keys[i]] !== 'string') return false;
        }
        return true;
    }

    function normalizePropList(v) {
        if (!v || typeof v !== 'object') return [];
        if (Array.isArray(v)) return v.filter(function (x) { return typeof x === 'string'; });
        return Object.keys(v)
            .filter(function (k) { return /^\d+$/.test(k); })
            .sort(function (a, b) { return Number(a) - Number(b); })
            .map(function (k) { return v[k]; })
            .filter(function (x) { return typeof x === 'string'; });
    }

    function normalizeIndexedArrayLike(v) {
        if (!v || typeof v !== 'object') return [];
        if (Array.isArray(v)) return v.slice();
        return Object.keys(v)
            .filter(function (k) { return /^\d+$/.test(k); })
            .sort(function (a, b) { return Number(a) - Number(b); })
            .map(function (k) { return v[k]; });
    }

    function normalizeStringList(v) {
        return normalizeIndexedArrayLike(v).filter(function (x) { return typeof x === 'string' && x !== ''; });
    }

    function applyRedLookupTemplate(tpl, name, sprite) {
        if (!tpl || typeof tpl !== 'string') return '';
        var enc = encodeURIComponent(name || '');
        return tpl.split('{name}').join(enc).split('{sprite}').join(sprite != null ? String(sprite) : '');
    }

    function dedupeUrls(urls) {
        var seen = {};
        var out = [];
        for (var i = 0; i < urls.length; i++) {
            var u = urls[i];
            if (!u || typeof u !== 'string' || seen[u]) continue;
            seen[u] = true;
            out.push(u);
        }
        return out;
    }

    /**
     * BryceCanyonCounty rdr3-nativedb-data uses names like a_c_deer_01x1.jpg / a_c_wolfx1.jpg (not plain _01.jpg).
     * Try jsDelivr first — often loads in NUI when raw.githubusercontent.com is blocked or finicky.
     */
    var nativedbPedRawBase = 'https://raw.githubusercontent.com/BryceCanyonCounty/rdr3-nativedb-data/master/objects/images/';
    var nativedbPedJsdBase = 'https://cdn.jsdelivr.net/gh/BryceCanyonCounty/rdr3-nativedb-data@master/objects/images/';

    function pushNativedbPedJpegs(urls, stem) {
        if (!stem) return;
        var s = String(stem).toLowerCase();
        var enc = encodeURIComponent(s);
        var bases = [nativedbPedJsdBase, nativedbPedRawBase];
        for (var bi = 0; bi < bases.length; bi++) {
            var base = bases[bi];
            urls.push(base + enc + 'x1.jpg');
            urls.push(base + s + 'x1.jpg');
            urls.push(base + enc + 'x2.jpg');
            urls.push(base + s + 'x2.jpg');
            urls.push(base + enc + 'x3.jpg');
            urls.push(base + s + 'x3.jpg');
            urls.push(base + enc + '.jpg');
            urls.push(base + s + '.jpg');
        }
    }

    function pedImageCandidates(name) {
        var raw = String(name || '').trim();
        var lo = raw.toLowerCase();
        var enc = encodeURIComponent(lo);
        var urls = [];
        pushNativedbPedJpegs(urls, lo);
        var u = applyRedLookupTemplate(redLookupPedImageUrl, raw, null);
        if (u) urls.push(u);
        var b = (redLookupBaseUrl || 'https://redlookup.com').replace(/\/$/, '');
        urls.push(b + '/_nuxt/peds/' + enc + '.webp');
        urls.push(b + '/peds/thumbnail/' + enc + '.png');
        urls.push('https://femga.com:8080/images/samples/ui_textures/peds/' + enc + '.png');
        urls.push('https://femga.com:8080/images/samples/peds/' + enc + '.png');
        urls.push('https://femga.com:8080/images/samples/peds/' + lo + '.png');
        urls.push('img/peds/' + enc + '.png');
        urls.push('https://ui-avatars.com/api/?background=374151&color=e5e7eb&size=160&font-size=0.33&bold=true&name=' + enc);
        return dedupeUrls(urls);
    }

    function blipImageCandidates(row) {
        var n = row.name;
        var enc = encodeURIComponent(n);
        var urls = [];
        var u = applyRedLookupTemplate(redLookupBlipImageUrl, n, row.sprite);
        if (u) urls.push(u);
        var rlb = (redLookupBaseUrl || 'https://redlookup.com').replace(/\/$/, '');
        urls.push(rlb + '/_nuxt/blips/' + enc + '.webp');
        urls.push(rlb + '/blips/thumbnail/' + enc + '.png');
        urls.push('https://femga.com:8080/images/samples/ui_textures_no_bg/blips_mp/' + enc + '.png');
        urls.push('https://femga.com:8080/images/samples/ui_textures/blips_mp/' + enc + '.png');
        urls.push('https://femga.com:8080/images/samples/ui_textures_no_bg/blips/' + enc + '.png');
        urls.push('https://femga.com:8080/images/samples/ui_textures/blips/' + enc + '.png');
        urls.push('img/blips/' + enc + '.png');
        return dedupeUrls(urls);
    }

    function propImageSrc(model) {
        if (thumbBase) {
            return thumbBase + '/' + encodeURIComponent(model) + '.webp';
        }
        return 'img/' + encodeURIComponent(model) + '.png';
    }

    function updateNavActive() {
        document.querySelectorAll('#sidebar-nav .nav-btn').forEach(function (b) {
            var v = b.getAttribute('data-view');
            var active = false;
            if (currentView === 'category' && v === 'category') {
                active = b.getAttribute('data-cat') === categoryCatKey && b.getAttribute('data-sub') === categorySubKey;
            } else if (currentView !== 'category' && v === currentView && !b.getAttribute('data-cat')) {
                active = true;
            }
            b.classList.toggle('active', active);
        });
        updateTitleLogos();
    }

    /** Gizmo logo by default; Spooni (старый) логотип — только в режиме подкатегории каталога (как на скрине: Fireplace и т.д.). */
    function updateTitleLogos() {
        var gizmo = document.getElementById('title-logo-gizmo');
        var spooni = document.getElementById('title-logo-spooni');
        if (!gizmo || !spooni) return;
        var useSpooni = currentView === 'category';
        gizmo.classList.toggle('hidden', useSpooni);
        spooni.classList.toggle('hidden', !useSpooni);
    }

    function applyStaticI18n() {
        var sidebarHead = document.querySelector('.sidebar-head');
        if (sidebarHead) sidebarHead.textContent = tr('categories');
        var bAll = document.querySelector('#sidebar-nav .nav-btn[data-view="all"]');
        if (bAll) bAll.textContent = tr('allProps');
        var bFav = document.querySelector('#sidebar-nav .nav-btn[data-view="favorites"]');
        if (bFav) bFav.textContent = tr('favorites');
        var bPeds = document.querySelector('#sidebar-nav .nav-btn[data-view="peds"]');
        if (bPeds) bPeds.textContent = tr('peds');
        var bBlips = document.querySelector('#sidebar-nav .nav-btn[data-view="blips"]');
        if (bBlips) bBlips.textContent = tr('blips');
        var bPlaced = document.querySelector('#sidebar-nav .nav-btn[data-view="placed"]');
        if (bPlaced) bPlaced.textContent = tr('placed');
        var bSkin = document.querySelector('#sidebar-nav .nav-btn[data-view="playerSkin"]');
        if (bSkin) bSkin.textContent = tr('playerSkinNav');
        var title = document.querySelector('.title');
        if (title) title.textContent = tr('title');
        var search = document.getElementById('search-input');
        if (search) search.placeholder = tr('searchPlaceholder');
        var pTitle = document.querySelector('.placement-title');
        if (pTitle) pTitle.textContent = tr('placement');
        var labels = document.querySelectorAll('.pl-label');
        if (labels[0]) labels[0].textContent = tr('move');
        if (labels[1]) labels[1].textContent = tr('speed');
        if (labels[2]) labels[2].textContent = tr('rotate');
        if (labels[3]) labels[3].textContent = tr('height');
        if (labels[4]) labels[4].textContent = tr('pitch');
        if (labels[5]) labels[5].textContent = tr('roll');
        var freeMoveLabel = document.getElementById('pl-free-move-label');
        if (freeMoveLabel) freeMoveLabel.textContent = tr('freeMove');
        var c = document.getElementById('pl-confirm');
        if (c) c.textContent = tr('place');
        var r = document.getElementById('pl-reset');
        if (r) r.textContent = tr('resetPosition');
        var x = document.getElementById('pl-cancel');
        if (x) x.textContent = tr('cancel');
        var hint = document.querySelector('.pl-hint');
        if (hint) hint.textContent = tr('hintEsc');
    }

    function setGridOrPlaced(mode) {
        var gridWrap = document.getElementById('content-grid-wrap');
        var placedEl = document.getElementById('content-placed');
        var skinEl = document.getElementById('content-player-skin');
        var isPlaced = mode === 'placed';
        var isSkin = mode === 'playerSkin';
        var isGrid = mode === 'grid';
        if (gridWrap) gridWrap.classList.toggle('hidden', !isGrid);
        if (placedEl) placedEl.classList.toggle('hidden', !isPlaced);
        if (skinEl) skinEl.classList.toggle('hidden', !isSkin);
        if (isPlaced) renderPlaced();
        if (isSkin) {
            buildPlayerSkinToolbar();
            render();
        }
        if (isGrid) render();
    }

    function setView(view) {
        currentView = view;
        categoryCatKey = null;
        categorySubKey = null;
        catalogPage = 1;
        if (view === 'placed') placedPage = 1;
        updateNavActive();
        if (view === 'placed') {
            setGridOrPlaced('placed');
        } else if (view === 'playerSkin') {
            setGridOrPlaced('playerSkin');
        } else {
            setGridOrPlaced('grid');
        }
    }

    function setCategoryView(cat, sub) {
        currentView = 'category';
        categoryCatKey = cat;
        categorySubKey = sub;
        catalogPage = 1;
        placedPage = 1;
        updateNavActive();
        setGridOrPlaced('grid');
    }

    function makeCategoryGroup(catKey, nested) {
        var subs = catalogTree[catKey];
        var subKeys = Object.keys(subs).filter(function (sk) {
            return isPropIdList(subs[sk]);
        }).sort();
        if (subKeys.length === 0) return null;
        var group = document.createElement('div');
        group.className = 'nav-group' + (nested ? ' nav-group-nested' : '');
        var toggle = document.createElement('button');
        toggle.type = 'button';
        toggle.className = 'nav-group-toggle';
        toggle.textContent = labelCat(catKey);
        var subWrap = document.createElement('div');
        subWrap.className = 'nav-sub hidden';
        subKeys.forEach(function (subKey) {
            var btn = document.createElement('button');
            btn.type = 'button';
            btn.className = 'nav-btn';
            btn.setAttribute('data-view', 'category');
            btn.setAttribute('data-cat', catKey);
            btn.setAttribute('data-sub', subKey);
            btn.textContent = labelCat(subKey);
            subWrap.appendChild(btn);
        });
        group.appendChild(toggle);
        group.appendChild(subWrap);
        return group;
    }

    function buildCategoryNav() {
        var container = document.getElementById('category-nav');
        if (!container) return;
        container.innerHTML = '';
        var keys = Object.keys(catalogTree).filter(function (k) {
            var o = catalogTree[k];
            return o && typeof o === 'object' && !Array.isArray(o);
        }).sort();
        if (keys.length === 0) return;

        if (wrapSpooniRoot) {
            var outer = document.createElement('div');
            outer.className = 'nav-group nav-spooni-root';
            var otoggle = document.createElement('button');
            otoggle.type = 'button';
            otoggle.className = 'nav-group-toggle';
            otoggle.textContent = 'Spooni Props';
            var osub = document.createElement('div');
            osub.className = 'nav-sub nav-spooni-nested hidden';
            var any = false;
            keys.forEach(function (catKey) {
                var g = makeCategoryGroup(catKey, true);
                if (g) {
                    osub.appendChild(g);
                    any = true;
                }
            });
            if (any) {
                outer.appendChild(otoggle);
                outer.appendChild(osub);
                container.appendChild(outer);
                if (spooniRootExpanded) {
                    outer.classList.add('open');
                    osub.classList.remove('hidden');
                }
                return;
            }
            /* empty catalog: draw flat */
        }

        keys.forEach(function (catKey) {
            var g = makeCategoryGroup(catKey, false);
            if (g) container.appendChild(g);
        });
    }

    function getModelsForView() {
        if (currentView === 'all') {
            return allProps.filter(matchesSearch);
        }
        if (currentView === 'favorites') {
            return favoritesCache.filter(matchesSearch);
        }
        if (currentView === 'peds') {
            return pedsCatalog.filter(matchesSearch);
        }
        if (currentView === 'playerSkin') {
            return pedsCatalog.filter(matchesSearch);
        }
        if (currentView === 'blips') {
            return blipsCatalog.filter(function (row) {
                if (!row || typeof row.name !== 'string') return false;
                if (!searchQuery) return true;
                var q = searchQuery.toLowerCase();
                var h = row.sprite != null ? String(row.sprite) : '';
                return (row.name + ' ' + h).toLowerCase().indexOf(q) !== -1;
            });
        }
        if (currentView === 'category' && categoryCatKey && categorySubKey) {
            var subs = catalogTree[categoryCatKey];
            if (subs && isPropIdList(subs[categorySubKey])) {
                return normalizePropList(subs[categorySubKey]).filter(matchesSearch);
            }
        }
        return [];
    }

    function renderCard(model) {
        var isBlip = false;
        var isPed = false;
        var displayModel = model;
        var blipRow = null;
        var favStorageKey = null;

        if (currentView === 'favorites' && typeof model === 'string') {
            favStorageKey = model;
            if (model.indexOf('ped:') === 0) {
                isPed = true;
                displayModel = model.slice(4);
            } else if (model.indexOf('blip:') === 0) {
                isBlip = true;
                var bn = model.slice(5);
                blipRow = blipNameToRow[bn] || { name: bn, sprite: 0 };
                displayModel = blipRow;
            } else if (model.indexOf('prop:') === 0) {
                displayModel = model.slice(5);
            } else {
                displayModel = model;
                favStorageKey = 'prop:' + model;
            }
        } else if (currentView === 'blips') {
            isBlip = model && typeof model === 'object' && typeof model.name === 'string';
            blipRow = isBlip ? model : null;
            displayModel = model;
            favStorageKey = favEntryKey('blip', model);
        } else if (currentView === 'peds') {
            isPed = true;
            displayModel = model;
            favStorageKey = favEntryKey('ped', model);
        } else if (currentView === 'playerSkin') {
            isPed = true;
            displayModel = model;
            favStorageKey = null;
        } else {
            displayModel = model;
            favStorageKey = favEntryKey('prop', model);
        }

        var card = document.createElement('div');
        card.className = 'prop-card' + (currentView === 'playerSkin' && playerSkinSelectedModel === displayModel ? ' prop-card-selected' : '');

        var tw = document.createElement('div');
        tw.className = 'prop-thumb-wrap';
        var img = document.createElement('img');
        img.className = 'prop-thumb';
        img.alt = '';
        var extCandidates = [];
        if (isBlip && blipRow) {
            extCandidates = blipImageCandidates(blipRow);
            img.dataset.extTry = '0';
            img.src = extCandidates[0] || '';
        } else if (isPed) {
            extCandidates = pedImageCandidates(displayModel);
            img.dataset.extTry = '0';
            img.src = extCandidates[0] || '';
        } else {
            img.src = propImageSrc(displayModel);
        }
        img.onerror = function () {
            if (isBlip || isPed) {
                var ei = parseInt(img.dataset.extTry || '0', 10) + 1;
                if (ei < extCandidates.length) {
                    img.dataset.extTry = String(ei);
                    img.src = extCandidates[ei];
                    return;
                }
                img.style.display = 'none';
                if (!tw.querySelector('.prop-thumb-ph')) {
                    var phb = document.createElement('div');
                    phb.className = 'prop-thumb-ph';
                    phb.textContent = tr('noPreview');
                    tw.appendChild(phb);
                }
                return;
            }
            if (thumbBase && img.dataset.fallback !== '1') {
                img.dataset.fallback = '1';
                img.src = 'img/' + encodeURIComponent(displayModel) + '.png';
                return;
            }
            if (img.dataset.fallback === '1' && img.dataset.fallback2 !== '1') {
                img.dataset.fallback2 = '1';
                img.src = 'img/' + encodeURIComponent(displayModel) + '.webp';
                return;
            }
            img.style.display = 'none';
            if (!tw.querySelector('.prop-thumb-ph')) {
                var ph = document.createElement('div');
                ph.className = 'prop-thumb-ph';
                ph.textContent = tr('noPreview');
                tw.appendChild(ph);
            }
        };
        tw.appendChild(img);

        var bar = document.createElement('div');
        bar.className = 'prop-bar';
        var name = document.createElement('div');
        name.className = 'prop-name';
        if (isBlip && blipRow) {
            name.textContent = blipRow.name + (blipRow.sprite != null ? '  #' + blipRow.sprite : '');
        } else {
            name.textContent = displayModel;
        }

        var actions = document.createElement('div');
        actions.className = 'prop-actions';

        var btnCopy = document.createElement('button');
        btnCopy.type = 'button';
        btnCopy.className = 'btn-copy';
        btnCopy.textContent = tr('copy');
        btnCopy.addEventListener('click', function (e) {
            e.stopPropagation();
            var t = isBlip && blipRow ? (blipRow.name + ' ' + blipRow.sprite) : displayModel;
            copyTextToClipboard(t);
        });
        actions.appendChild(btnCopy);

        if (currentView !== 'playerSkin') {
            var btnFav = document.createElement('button');
            btnFav.type = 'button';
            var fk = favStorageKey || favEntryKey(isBlip ? 'blip' : (isPed ? 'ped' : 'prop'), isBlip ? blipRow : displayModel);
            btnFav.className = 'btn-fav' + (isFavoriteKey(fk) ? ' on' : '');
            btnFav.textContent = isFavoriteKey(fk) ? '★' : '☆';
            btnFav.addEventListener('click', function (e) {
                e.stopPropagation();
                toggleFavoriteKey(fk);
            });
            actions.appendChild(btnFav);
        }

        var btnPlace = document.createElement('button');
        btnPlace.type = 'button';
        btnPlace.className = 'btn-place';
        if (currentView === 'playerSkin') {
            btnPlace.textContent = tr('skinSelect');
            btnPlace.addEventListener('click', function (e) {
                e.stopPropagation();
                playerSkinSelectedModel = displayModel;
                updatePlayerSkinSelectedLabel();
                render();
            });
        } else {
            btnPlace.textContent = isPed ? tr('spawnPed') : tr('placeBtn');
            btnPlace.addEventListener('click', function (e) {
                e.stopPropagation();
                if (isBlip && blipRow) post('beginPlaceBlip', { name: blipRow.name });
                else if (isPed) post('spawnPedAtPlayer', { model: displayModel });
                else post('beginPlace', { model: displayModel });
            });
        }
        actions.appendChild(btnPlace);
        bar.appendChild(name);
        bar.appendChild(actions);
        card.appendChild(tw);
        card.appendChild(bar);
        return card;
    }

    function getActiveCatalogGrid() {
        return currentView === 'playerSkin'
            ? document.getElementById('player-skin-grid')
            : document.getElementById('props-grid');
    }

    function getActiveCatalogWrap() {
        return currentView === 'playerSkin'
            ? document.getElementById('content-grid-wrap-skin')
            : document.getElementById('content-grid-wrap');
    }

    function updatePlayerSkinSelectedLabel() {
        var el = document.getElementById('player-skin-selected-label');
        if (el) el.textContent = tr('playerSkinSelected') + ': ' + (playerSkinSelectedModel || '—');
    }

    function updatePlayerSkinTargetSummary() {
        var el = document.getElementById('player-skin-target-info');
        if (!el) return;
        var stEl = document.getElementById('player-skin-steam');
        var sidEl = document.getElementById('player-skin-server-id');
        var steamV = stEl && stEl.value ? String(stEl.value).trim() : '';
        var sidRaw = sidEl && sidEl.value ? String(sidEl.value).trim() : '';
        var sidNum = sidRaw ? parseInt(sidRaw, 10) : NaN;
        if (!isNaN(sidNum) && sidNum > 0) {
            el.textContent = tr('playerSkinTargetId') + String(sidNum);
            return;
        }
        if (steamV) {
            var disp = steamV.length > 42 ? steamV.slice(0, 39) + '…' : steamV;
            el.textContent = tr('playerSkinTargetSteam') + disp;
            return;
        }
        el.textContent = tr('playerSkinTargetSelf');
    }

    function formatSkinTs(ts) {
        if (ts == null || ts === '') return '—';
        var n = Number(ts);
        if (!Number.isFinite(n) || n <= 0) return '—';
        try {
            return new Date(n * 1000).toLocaleString('ru-RU');
        } catch (e) {
            return String(ts);
        }
    }

    function renderSkinRosterPanel(host, data) {
        if (!host) return;
        data = data || skinRosterCache;
        host.innerHTML = '';
        var h2 = document.createElement('h3');
        h2.className = 'player-skin-roster-title';
        h2.textContent = tr('skinRosterTitle');
        host.appendChild(h2);
        var bRef = document.createElement('button');
        bRef.type = 'button';
        bRef.className = 'btn-place player-skin-roster-refresh';
        bRef.textContent = tr('skinRosterRefresh');
        bRef.addEventListener('click', function () {
            post('skinRosterRefresh', {});
        });
        host.appendChild(bRef);

        function mkTable(titleKey, columns, rows, rowFn) {
            if (!rows || rows.length === 0) return;
            var sec = document.createElement('div');
            sec.className = 'player-skin-roster-section';
            var th = document.createElement('h4');
            th.textContent = tr(titleKey);
            sec.appendChild(th);
            var tbl = document.createElement('table');
            tbl.className = 'player-skin-roster-table';
            var thead = document.createElement('thead');
            var trh = document.createElement('tr');
            columns.forEach(function (col) {
                var thc = document.createElement('th');
                thc.textContent = tr(col.labelKey);
                if (col.thClass) thc.className = col.thClass;
                trh.appendChild(thc);
            });
            thead.appendChild(trh);
            tbl.appendChild(thead);
            var tbody = document.createElement('tbody');
            rows.forEach(function (row) {
                tbody.appendChild(rowFn(row));
            });
            tbl.appendChild(tbody);
            sec.appendChild(tbl);
            host.appendChild(sec);
        }

        mkTable('skinRosterOnline', [
            { labelKey: 'skinRosterColName' },
            { labelKey: 'skinRosterColId' },
            { labelKey: 'skinRosterColModel' },
            { labelKey: 'skinRosterColActions', thClass: 'player-skin-roster-th-actions' },
        ], data.online || [], function (r) {
            var trEl = document.createElement('tr');
            var td1 = document.createElement('td');
            td1.textContent = r.name || '—';
            var td2 = document.createElement('td');
            td2.textContent = r.serverId != null ? String(r.serverId) : '—';
            var td3 = document.createElement('td');
            td3.textContent = r.model || '—';
            var td4 = document.createElement('td');
            td4.className = 'player-skin-roster-cell-action';
            var sidNum = r.serverId != null ? Number(r.serverId) : NaN;
            if (!Number.isNaN(sidNum) && sidNum > 0) {
                var del = document.createElement('button');
                del.type = 'button';
                del.className = 'btn-skin-roster-delete';
                del.setAttribute('aria-label', tr('skinRosterDeleteSkin'));
                del.setAttribute('title', tr('skinRosterDeleteSkin'));
                del.innerHTML =
                    '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>';
                del.addEventListener('click', function (e) {
                    e.preventDefault();
                    e.stopPropagation();
                    post('playerSkinClear', { targetServerId: sidNum, targetSteam: '' });
                });
                td4.appendChild(del);
            } else {
                td4.textContent = '—';
            }
            trEl.appendChild(td1);
            trEl.appendChild(td2);
            trEl.appendChild(td3);
            trEl.appendChild(td4);
            return trEl;
        });

        mkTable('skinRosterHistory', [
            { labelKey: 'skinRosterColTime' },
            { labelKey: 'skinRosterColAdmin' },
            { labelKey: 'skinRosterColPlayer' },
            { labelKey: 'skinRosterColModel' },
        ], data.history || [], function (r) {
            var trEl = document.createElement('tr');
            [formatSkinTs(r.ts), r.admin || '—', r.targetName || '—', r.model || '—'].forEach(function (t) {
                var td = document.createElement('td');
                td.textContent = t;
                trEl.appendChild(td);
            });
            return trEl;
        });

        if (!host.querySelector('.player-skin-roster-section')) {
            var empty = document.createElement('p');
            empty.className = 'player-skin-roster-empty';
            empty.textContent = tr('skinRosterEmpty');
            host.appendChild(empty);
        }
    }

    function buildPlayerSkinToolbar() {
        var tb = document.getElementById('player-skin-toolbar');
        if (!tb) return;
        tb.innerHTML = '';
        var hint = document.createElement('p');
        hint.className = 'player-skin-hint';
        hint.textContent = tr('playerSkinHint');
        var row = document.createElement('div');
        row.className = 'player-skin-controls';
        var modelInp = document.createElement('input');
        modelInp.type = 'text';
        modelInp.className = 'player-skin-steam';
        modelInp.placeholder = tr('playerSkinModelPh');
        modelInp.id = 'player-skin-model-input';
        modelInp.autocomplete = 'off';
        var sidInp = document.createElement('input');
        sidInp.type = 'text';
        sidInp.inputMode = 'numeric';
        sidInp.className = 'player-skin-steam';
        sidInp.style.minWidth = '100px';
        sidInp.placeholder = tr('playerSkinServerIdPh');
        sidInp.id = 'player-skin-server-id';
        sidInp.autocomplete = 'off';
        var steam = document.createElement('input');
        steam.type = 'text';
        steam.className = 'player-skin-steam';
        steam.placeholder = tr('playerSkinSteamPh');
        steam.id = 'player-skin-steam';
        steam.autocomplete = 'off';
        var btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'btn-place';
        btn.textContent = tr('playerSkinApply');
        btn.addEventListener('click', function () {
            var manual = modelInp.value ? String(modelInp.value).trim() : '';
            var model = manual || playerSkinSelectedModel;
            if (!model) return;
            var st = document.getElementById('player-skin-steam');
            var sidRaw = sidInp.value ? String(sidInp.value).trim() : '';
            var sidNum = sidRaw ? parseInt(sidRaw, 10) : NaN;
            var payload = {
                model: model,
                targetSteam: st && st.value ? String(st.value).trim() : '',
            };
            if (!isNaN(sidNum) && sidNum > 0) {
                payload.targetServerId = sidNum;
            }
            post('playerSkinApply', payload);
        });
        row.appendChild(modelInp);
        row.appendChild(sidInp);
        row.appendChild(steam);
        row.appendChild(btn);

        var targetRow = document.createElement('div');
        targetRow.className = 'player-skin-target-row';
        var info = document.createElement('div');
        info.className = 'player-skin-target-info';
        info.id = 'player-skin-target-info';
        var btnDel = document.createElement('button');
        btnDel.type = 'button';
        btnDel.className = 'btn-player-skin-delete';
        btnDel.textContent = tr('playerSkinDelete');
        btnDel.setAttribute('title', tr('playerSkinDelete'));
        btnDel.addEventListener('click', function () {
            var st = document.getElementById('player-skin-steam');
            var sidRaw = sidInp.value ? String(sidInp.value).trim() : '';
            var sidNum = sidRaw ? parseInt(sidRaw, 10) : NaN;
            var clrPayload = {
                targetSteam: st && st.value ? String(st.value).trim() : '',
            };
            if (!isNaN(sidNum) && sidNum > 0) {
                clrPayload.targetServerId = sidNum;
            }
            post('playerSkinClear', clrPayload);
        });
        targetRow.appendChild(info);
        targetRow.appendChild(btnDel);

        function onTargetFieldsInput() {
            updatePlayerSkinTargetSummary();
        }
        sidInp.addEventListener('input', onTargetFieldsInput);
        steam.addEventListener('input', onTargetFieldsInput);

        tb.appendChild(hint);
        tb.appendChild(row);
        tb.appendChild(targetRow);
        updatePlayerSkinTargetSummary();
        var rosterWrap = document.createElement('div');
        rosterWrap.id = 'player-skin-roster-wrap';
        rosterWrap.className = 'player-skin-roster-wrap';
        tb.appendChild(rosterWrap);
        renderSkinRosterPanel(rosterWrap, skinRosterCache);
        post('skinRosterRefresh', {});
    }

    function render() {
        var grid = getActiveCatalogGrid();
        if (!grid) return;
        grid.innerHTML = '';
        var wrap = getActiveCatalogWrap();
        if (wrap) {
            var old = wrap.querySelector('.catalog-pagination');
            if (old) old.remove();
        }
        var models = getModelsForView();
        if (models.length === 0) {
            var empty = document.createElement('div');
            empty.style.gridColumn = '1 / -1';
            empty.style.color = '#666';
            empty.style.padding = '24px';
            empty.textContent = tr('nothingFound');
            grid.appendChild(empty);
            return;
        }
        var pageCount = Math.max(1, Math.ceil(models.length / catalogPageSize));
        if (catalogPage > pageCount) catalogPage = pageCount;
        if (catalogPage < 1) catalogPage = 1;
        var start = (catalogPage - 1) * catalogPageSize;
        var pageModels = models.slice(start, start + catalogPageSize);
        pageModels.forEach(function (m) {
            grid.appendChild(renderCard(m));
        });
        if (pageCount > 1 && wrap) {
            var pg = document.createElement('div');
            pg.className = 'catalog-pagination';
            var bPrev = document.createElement('button');
            bPrev.type = 'button';
            bPrev.textContent = tr('prev');
            bPrev.disabled = catalogPage <= 1;
            bPrev.addEventListener('click', function () {
                if (catalogPage > 1) {
                    catalogPage -= 1;
                    render();
                }
            });
            var info = document.createElement('span');
            info.textContent = tr('page') + ' ' + catalogPage + ' / ' + pageCount + ' · ' + tr('propsTotal') + ': ' + models.length;
            var bNext = document.createElement('button');
            bNext.type = 'button';
            bNext.textContent = tr('next');
            bNext.disabled = catalogPage >= pageCount;
            bNext.addEventListener('click', function () {
                if (catalogPage < pageCount) {
                    catalogPage += 1;
                    render();
                }
            });
            pg.appendChild(bPrev);
            pg.appendChild(info);
            pg.appendChild(bNext);
            wrap.appendChild(pg);
        }
    }

    function formatVec(row) {
        var x = Number(row.x).toFixed(2);
        var y = Number(row.y).toFixed(2);
        var z = Number(row.z).toFixed(2);
        return x + ', ' + y + ', ' + z;
    }

    function folderContainsProp(folder, propId) {
        if (!folder || !propId) return false;
        var ids = folder.propIds;
        if (!Array.isArray(ids)) return false;
        return ids.indexOf(propId) !== -1;
    }

    function propInAnyFolder(propId) {
        for (var i = 0; i < placedFolders.length; i++) {
            if (folderContainsProp(placedFolders[i], propId)) return true;
        }
        return false;
    }

    function findFolderById(folderId) {
        for (var i = 0; i < placedFolders.length; i++) {
            if (placedFolders[i].id === folderId) return placedFolders[i];
        }
        return null;
    }

    function buildPlacedFolderCell(row) {
        var tdG = document.createElement('td');
        tdG.className = 'placed-folder-cell';
        if ((row.kind || 'prop') !== 'prop') {
            tdG.textContent = '—';
            tdG.style.color = '#555';
            return tdG;
        }
        var wrap = document.createElement('div');
        wrap.className = 'placed-folder-cell-inner';
        var sel = document.createElement('select');
        sel.className = 'placed-row-group-select';
        function addOpt(v, label) {
            var o = document.createElement('option');
            o.value = v;
            o.textContent = label;
            sel.appendChild(o);
        }
        addOpt('', tr('placedPickFolder'));
        placedFolders.forEach(function (f) {
            if (f && f.id && f.name) addOpt(f.id, f.name);
        });
        addOpt('__new__', '+ ' + tr('folderNamePrompt'));
        sel.value = '';
        sel.addEventListener('change', function () {
            var v = sel.value;
            sel.value = '';
            if (v === '' || v === '__new__') {
                if (v === '__new__') {
                    openTextModal(tr('folderNamePrompt'), '').then(function (name) {
                        if (name != null && String(name).trim()) {
                            post('createPlacedFolder', { name: String(name).trim() });
                        }
                    });
                }
                return;
            }
            post('addPlacedPropToFolder', { folderId: v, propId: row.id });
        });
        wrap.appendChild(sel);
        var names = [];
        placedFolders.forEach(function (f) {
            if (folderContainsProp(f, row.id) && f.name) names.push(f.name);
        });
        if (names.length > 0) {
            var badges = document.createElement('div');
            badges.className = 'placed-folder-badges';
            badges.textContent = names.join(', ');
            wrap.appendChild(badges);
        }
        var ff = placedFolderFilter;
        if (ff && ff !== '' && ff !== '__none__' && folderContainsProp(findFolderById(ff), row.id)) {
            var brm = document.createElement('button');
            brm.type = 'button';
            brm.className = 'btn-folder-remove';
            brm.textContent = tr('placedRemoveFromFolder');
            brm.addEventListener('click', function () {
                post('removePlacedPropFromFolder', { folderId: ff, propId: row.id });
            });
            wrap.appendChild(brm);
        }
        tdG.appendChild(wrap);
        return tdG;
    }

    function renderPlaced() {
        var el = document.getElementById('content-placed');
        if (!el) return;
        el.innerHTML = '';
        el.style.padding = '14px 18px';

        var toolbar = document.createElement('div');
        toolbar.className = 'placed-toolbar';
        var bPlus = document.createElement('button');
        bPlus.type = 'button';
        bPlus.className = 'btn-folder-plus';
        bPlus.title = tr('placedNewFolder');
        bPlus.setAttribute('aria-label', tr('placedNewFolder'));
        bPlus.textContent = '+';
        bPlus.addEventListener('click', function () {
            openTextModal(tr('folderNamePrompt'), '').then(function (name) {
                if (name != null && String(name).trim()) {
                    post('createPlacedFolder', { name: String(name).trim() });
                }
            });
        });
        var lab = document.createElement('span');
        lab.className = 'placed-toolbar-label';
        lab.textContent = tr('placedFolderFilter');
        var fsel = document.createElement('select');
        fsel.className = 'placed-group-filter';
        [['', tr('placedFolderAll')], ['__none__', tr('placedFolderNone')]].forEach(function (pair) {
            var o = document.createElement('option');
            o.value = pair[0];
            o.textContent = pair[1];
            fsel.appendChild(o);
        });
        placedFolders.forEach(function (f) {
            if (f && f.id && f.name) {
                var o = document.createElement('option');
                o.value = f.id;
                o.textContent = f.name;
                fsel.appendChild(o);
            }
        });
        fsel.value = placedFolderFilter || '';
        fsel.addEventListener('change', function () {
            placedFolderFilter = fsel.value;
            placedPage = 1;
            renderPlaced();
        });
        toolbar.appendChild(bPlus);
        toolbar.appendChild(lab);
        toolbar.appendChild(fsel);
        var ff = placedFolderFilter || '';
        if (ff !== '' && ff !== '__none__') {
            var bDel = document.createElement('button');
            bDel.type = 'button';
            bDel.className = 'btn-folder-delete';
            bDel.textContent = tr('placedDeleteFolder');
            bDel.addEventListener('click', function () {
                openConfirmModal(tr('folderDeleteConfirm')).then(function (ok) {
                    if (ok) {
                        post('deletePlacedFolder', { folderId: ff });
                        placedFolderFilter = '';
                        placedPage = 1;
                        renderPlaced();
                    }
                });
            });
            toolbar.appendChild(bDel);
        }
        el.appendChild(toolbar);

        var filtered = placedList.filter(function (row) {
            var hay = (row.model || '') + ' ' + (row.kind || '');
            if (!matchesSearch(hay)) return false;
            var fk = row.kind || 'prop';
            if (fk !== 'prop') return true;
            var gpf = placedFolderFilter || '';
            if (gpf === '') return true;
            if (gpf === '__none__') return !propInAnyFolder(row.id);
            var fo = findFolderById(gpf);
            return fo ? folderContainsProp(fo, row.id) : true;
        });
        if (filtered.length === 0) {
            var empty = document.createElement('div');
            empty.style.color = '#666';
            empty.style.padding = '16px 0';
            empty.textContent = placedList.length === 0 ? tr('noPlacedYet') : tr('noSearchPlaced');
            el.appendChild(empty);
            return;
        }
        var pageCount = Math.max(1, Math.ceil(filtered.length / placedPageSize));
        if (placedPage > pageCount) placedPage = pageCount;
        if (placedPage < 1) placedPage = 1;
        var start = (placedPage - 1) * placedPageSize;
        var pageRows = filtered.slice(start, start + placedPageSize);

        var table = document.createElement('table');
        table.className = 'placed-table';
        var thead = document.createElement('thead');
        var trh = document.createElement('tr');
        ['tableModel', 'tableCoords', 'placedFolderCol', 'placedActions'].forEach(function (key) {
            var th = document.createElement('th');
            th.textContent = tr(key);
            trh.appendChild(th);
        });
        thead.appendChild(trh);
        table.appendChild(thead);
        var tbody = document.createElement('tbody');
        pageRows.forEach(function (row) {
            var rowEl = document.createElement('tr');
            var tdM = document.createElement('td');
            if (row.kind === 'ped') {
                var badge = document.createElement('span');
                badge.className = 'placed-kind-badge';
                badge.textContent = tr('pedBadge');
                tdM.appendChild(badge);
                tdM.appendChild(document.createTextNode(' ' + row.model));
                if (row.entityAlive === false) {
                    var miss = document.createElement('span');
                    miss.className = 'placed-ped-missing';
                    miss.textContent = ' (' + tr('pedMissing') + ')';
                    tdM.appendChild(miss);
                }
            } else {
                tdM.textContent = row.model;
            }
            var tdC = document.createElement('td');
            tdC.style.fontSize = '11px';
            tdC.style.color = '#aaa';
            tdC.textContent = formatVec(row);
            var tdG = buildPlacedFolderCell(row);
            var tdA = document.createElement('td');
            tdA.className = 'placed-actions';
            if (row.kind === 'ped') {
                var flagsWrap = document.createElement('div');
                flagsWrap.className = 'placed-ped-flags';
                var alive = row.entityAlive !== false;
                var mkChk = function (labelKey, flagName, checked) {
                    var lab = document.createElement('label');
                    lab.className = 'placed-ped-flag-label';
                    var inp = document.createElement('input');
                    inp.type = 'checkbox';
                    inp.setAttribute('data-flag', flagName);
                    inp.checked = !!checked;
                    inp.disabled = !alive;
                    lab.appendChild(inp);
                    lab.appendChild(document.createTextNode(' ' + tr(labelKey)));
                    flagsWrap.appendChild(lab);
                };
                mkChk('pedImmortal', 'invincible', row.invincible);
                mkChk('pedFrozen', 'frozen', row.frozen);
                flagsWrap.querySelectorAll('input[type="checkbox"]').forEach(function (inp) {
                    inp.addEventListener('change', function () {
                        var inv = flagsWrap.querySelector('input[data-flag="invincible"]');
                        var fro = flagsWrap.querySelector('input[data-flag="frozen"]');
                        post('placedPedSetFlags', {
                            id: row.id,
                            invincible: inv ? inv.checked : false,
                            frozen: fro ? fro.checked : false
                        });
                    });
                });
                tdA.appendChild(flagsWrap);
            }
            var bTp = document.createElement('button');
            bTp.type = 'button';
            bTp.textContent = tr('teleport');
            bTp.addEventListener('click', function () {
                post('placedTeleport', { id: row.id });
            });
            var bCp = document.createElement('button');
            bCp.type = 'button';
            bCp.textContent = tr('copyCoords');
            bCp.addEventListener('click', function () {
                var t = formatVec(row);
                copyTextToClipboard(t);
            });
            var bDel = document.createElement('button');
            bDel.type = 'button';
            bDel.className = 'danger';
            bDel.textContent = tr('del');
            bDel.addEventListener('click', function () {
                post('placedDelete', { id: row.id, kind: row.kind || 'prop' });
            });
            tdA.appendChild(bTp);
            tdA.appendChild(bCp);
            tdA.appendChild(bDel);
            rowEl.appendChild(tdM);
            rowEl.appendChild(tdC);
            rowEl.appendChild(tdG);
            rowEl.appendChild(tdA);
            tbody.appendChild(rowEl);
        });
        table.appendChild(tbody);
        el.appendChild(table);

        if (pageCount > 1) {
            var pg = document.createElement('div');
            pg.className = 'placed-pagination';
            var bPrev = document.createElement('button');
            bPrev.type = 'button';
            bPrev.textContent = tr('prev');
            bPrev.disabled = placedPage <= 1;
            bPrev.addEventListener('click', function () {
                if (placedPage > 1) {
                    placedPage -= 1;
                    renderPlaced();
                }
            });
            var info = document.createElement('span');
            info.textContent = tr('page') + ' ' + placedPage + ' / ' + pageCount + ' (' + filtered.length + ')';
            var bNext = document.createElement('button');
            bNext.type = 'button';
            bNext.textContent = tr('next');
            bNext.disabled = placedPage >= pageCount;
            bNext.addEventListener('click', function () {
                if (placedPage < pageCount) {
                    placedPage += 1;
                    renderPlaced();
                }
            });
            pg.appendChild(bPrev);
            pg.appendChild(info);
            pg.appendChild(bNext);
            el.appendChild(pg);
        }
    }

    function showPlacement(data) {
        var root = document.getElementById('app-root');
        if (root) root.classList.add('placement-world-visible');
        var shell = document.querySelector('.gizmo-shell');
        if (shell) shell.classList.add('hidden');
        var dock = document.getElementById('placement-dock');
        var label = document.getElementById('placement-model-label');
        if (label && data.model) label.textContent = data.model;
        var range = document.getElementById('pl-speed');
        var pct = document.getElementById('pl-speed-pct');
        if (range && data.speedMin != null) {
            range.min = String(data.speedMin);
            range.max = String(data.speedMax);
            range.step = String(data.speedStep || 5);
            range.value = String(data.speedPercent != null ? data.speedPercent : 100);
        }
        if (pct && range) pct.textContent = range.value + '%';
        var freeMove = document.getElementById('pl-free-move');
        if (freeMove) {
            freeMove.checked = false;
            post('placementSetFreeMove', { enabled: false });
        }
        if (dock) dock.classList.remove('hidden');
    }

    function hidePlacement() {
        var root = document.getElementById('app-root');
        if (root) root.classList.remove('placement-world-visible');
        var shell = document.querySelector('.gizmo-shell');
        if (shell) shell.classList.remove('hidden');
        var dock = document.getElementById('placement-dock');
        if (dock) dock.classList.add('hidden');
    }

    function setupPlacementControls() {
        function sendMove(dir, pressed) {
            post('placementMove', { direction: dir, pressed: pressed });
        }
        var dock = document.getElementById('placement-dock');
        if (!dock) return;
        dock.querySelectorAll('.pl-btn[data-dir]').forEach(function (btn) {
            var dir = btn.getAttribute('data-dir');
            btn.addEventListener('mousedown', function () { sendMove(dir, true); });
            btn.addEventListener('mouseup', function () { sendMove(dir, false); });
            btn.addEventListener('mouseleave', function () { sendMove(dir, false); });
        });
        var range = document.getElementById('pl-speed');
        var pct = document.getElementById('pl-speed-pct');
        function sendSpeed() {
            if (!range) return;
            var v = parseInt(range.value, 10);
            if (pct) pct.textContent = v + '%';
            post('placementSetSpeed', { percent: v });
        }
        if (range) {
            range.addEventListener('input', sendSpeed);
            range.addEventListener('change', sendSpeed);
        }
        var confirm = document.getElementById('pl-confirm');
        var reset = document.getElementById('pl-reset');
        var cancel = document.getElementById('pl-cancel');
        var freeMove = document.getElementById('pl-free-move');
        if (confirm) confirm.addEventListener('click', function () { post('placeConfirm', {}); });
        if (reset) reset.addEventListener('click', function () { post('placementReset', {}); });
        if (cancel) cancel.addEventListener('click', function () { post('placementCancel', {}); });
        if (freeMove) {
            freeMove.addEventListener('change', function () {
                post('placementSetFreeMove', { enabled: freeMove.checked });
            });
        }
    }

    function openApp(data) {
        catalogTree = data.tree || {};
        allProps = normalizePropList(data.allProps || []);
        pedsCatalog = normalizeStringList(data.peds || []);
        blipsCatalog = normalizeIndexedArrayLike(data.blips || [])
            .map(function (row) {
                if (!row || typeof row !== 'object') return null;
                var n = row.name;
                var sp = row.sprite != null ? Number(row.sprite) : null;
                if (typeof n !== 'string' || n === '' || !Number.isFinite(sp)) return null;
                return { name: n, sprite: sp };
            })
            .filter(function (x) { return x != null; });
        blipNameToRow = {};
        for (var bi = 0; bi < blipsCatalog.length; bi++) {
            var brow = blipsCatalog[bi];
            if (brow && typeof brow.name === 'string') blipNameToRow[brow.name] = brow;
        }
        redLookupBaseUrl = (typeof data.redLookupBaseUrl === 'string' && data.redLookupBaseUrl) ? data.redLookupBaseUrl.replace(/\/$/, '') : 'https://redlookup.com';
        redLookupPedImageUrl = typeof data.redLookupPedImageUrl === 'string' ? data.redLookupPedImageUrl : '';
        redLookupBlipImageUrl = typeof data.redLookupBlipImageUrl === 'string' ? data.redLookupBlipImageUrl : '';
        if (data.resourceName) resourceName = data.resourceName;
        thumbBase = (typeof data.thumbBase === 'string') ? data.thumbBase.replace(/\/$/, '') : '';
        wrapSpooniRoot = data.wrapSpooniRoot !== false;
        spooniRootExpanded = data.spooniRootExpanded !== false;
        lang = (data.lang === 'en') ? 'en' : 'ru';
        placedPageSize = Number(data.placedPageSize) > 0 ? Math.max(20, Math.floor(Number(data.placedPageSize))) : 100;
        catalogPageSize = Number(data.catalogPageSize) > 0 ? Math.max(40, Math.floor(Number(data.catalogPageSize))) : 120;
        refreshFavoritesCache();
        catalogPage = 1;
        placedPage = 1;
        applyStaticI18n();
        relabelNuiModalButtons();
        var root = document.getElementById('app-root');
        if (root) root.classList.remove('hidden');
        var shell = document.querySelector('.gizmo-shell');
        if (shell) shell.classList.remove('hidden');
        buildCategoryNav();
        setView('all');
    }

    function closeApp() {
        if (isTextModalOpen()) closeTextModalWithValue(null);
        if (isConfirmModalOpen()) closeConfirmModalWithValue(false);
        var root = document.getElementById('app-root');
        if (root) root.classList.add('hidden');
        hidePlacement();
    }

    window.addEventListener('message', function (event) {
        var data = event.data;
        if (!data || !data.action) return;
        if (data.action === 'open') {
            openApp(data);
        }
        if (data.action === 'close') {
            closeApp();
        }
        if (data.action === 'placedList') {
            placedList = normalizeIndexedArrayLike(data.list || []);
            placedFolders = Array.isArray(data.folders) ? data.folders : [];
            if (currentView === 'placed') renderPlaced();
            if (currentView === 'playerSkin') render();
        }
        if (data.action === 'skinHint') {
            var dock = document.getElementById('skin-hint-dock');
            if (!dock) return;
            if (!data.show) {
                dock.classList.add('hidden');
                return;
            }
            dock.classList.remove('hidden');
            var ht = document.getElementById('skin-hint-title');
            var ul = document.getElementById('skin-hint-list');
            if (ht) ht.textContent = data.title || '';
            if (ul) {
                ul.innerHTML = '';
                var lines = data.lines || [];
                for (var hi = 0; hi < lines.length; hi++) {
                    var li = document.createElement('li');
                    li.textContent = lines[hi];
                    ul.appendChild(li);
                }
            }
        }
        if (data.action === 'skinRosterData') {
            skinRosterCache = data.data && typeof data.data === 'object' ? data.data : { online: [], history: [] };
            var rw = document.getElementById('player-skin-roster-wrap');
            if (rw) renderSkinRosterPanel(rw, skinRosterCache);
        }
        if (data.action === 'showPlacement') {
            showPlacement(data);
        }
        if (data.action === 'hidePlacement') {
            hidePlacement();
        }
    });

    document.getElementById('btn-close').addEventListener('click', function () {
        post('close', {});
    });

    document.getElementById('search-input').addEventListener('input', function (e) {
        searchQuery = (e.target && e.target.value) || '';
        catalogPage = 1;
        placedPage = 1;
        if (currentView === 'placed') renderPlaced();
        else if (currentView === 'playerSkin') render();
        else render();
    });

    document.getElementById('sidebar-nav').addEventListener('click', function (e) {
        var t = e.target;
        if (!(t instanceof HTMLElement)) return;
        if (t.classList.contains('nav-group-toggle')) {
            var g = t.closest('.nav-group');
            if (g) {
                g.classList.toggle('open');
                var sub = g.querySelector('.nav-sub');
                if (sub) sub.classList.toggle('hidden');
            }
            return;
        }
        if (!t.classList.contains('nav-btn')) return;
        var v = t.getAttribute('data-view');
        if (!v) return;
        if (v === 'category') {
            var c = t.getAttribute('data-cat');
            var s = t.getAttribute('data-sub');
            if (c && s) setCategoryView(c, s);
        } else {
            setView(v);
        }
    });

    document.addEventListener('keydown', function (e) {
        if (isTextModalOpen()) {
            if (e.key === 'Escape') {
                e.preventDefault();
                closeTextModalWithValue(null);
            }
            return;
        }
        if (isConfirmModalOpen()) {
            if (e.key === 'Escape') {
                e.preventDefault();
                closeConfirmModalWithValue(false);
            }
            return;
        }
        var root = document.getElementById('app-root');
        if (!root || root.classList.contains('hidden')) return;
        var dock = document.getElementById('placement-dock');
        var placing = dock && !dock.classList.contains('hidden');
        if (placing) {
            if (e.key === 'Escape') {
                e.preventDefault();
                post('placementCancel', {});
            }
            return;
        }
        if (e.key === 'Escape') {
            post('close', {});
        }
    });

    initNuiModals();
    setupPlacementControls();
})();
