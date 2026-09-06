(function () {
    var resourceName = 'rsg_prop_gizmo';
    var catalogTree = {};
    var allProps = [];
    var currentView = 'all';
    var categoryCatKey = null;
    var categorySubKey = null;
    var placedList = [];
    var placedPage = 1;
    var placedPageSize = 100;
    var placedFolderFilter = '';
    var placedFolders = [];
    var catalogPage = 1;
    var catalogPageSize = 120;
    var favoritesCache = [];
    var searchQuery = '';
    var thumbBase = '';
    var lang = 'en';
    var pedsCatalog = [];
    var blipsCatalog = [];
    var blipNameToRow = {};
    var redLookupBaseUrl = 'https://redlookup.com';
    var redLookupPedImageUrl = '';
    var redLookupBlipImageUrl = '';

    var FAV_UNIFIED_KEY = 'rsg_prop_gizmo_favorites_unified';

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
            searchPlaceholder: 'Search props, peds, blips, archetypes…',
            placement: 'Placement',
            move: 'Move',
            speed: 'Speed',
            freeMove: 'Free move (WASD + mouse)',
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
            noPlacedYet: 'No placed props, blips, or peds yet.',
            tableModel: 'Model',
            tableCoords: 'Coords',
            teleport: 'Teleport',
            copyCoords: 'Copy coords',
            del: 'Delete',
            exportYmap: 'Export YMAP',
            prev: 'Prev',
            next: 'Next',
            page: 'Page',
            placedFolderFilter: 'Folder filter',
            placedFolderAll: 'All',
            placedFolderNone: 'Not in any folder',
            placedFolderCol: 'Folders',
            placedActions: 'Actions'
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
            freeMove: 'Свободное управление (WASD + мышь)',
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
            tableModel: 'Модель',
            tableCoords: 'Координаты',
            teleport: 'Телепорт',
            copyCoords: 'Копировать координаты',
            del: 'Удалить',
            exportYmap: 'Экспорт YMAP',
            prev: 'Назад',
            next: 'Далее',
            page: 'Страница',
            placedFolderFilter: 'Фильтр папки',
            placedFolderAll: 'Все',
            placedFolderNone: 'Без папки',
            placedFolderCol: 'Папки',
            placedActions: 'Действия'
        }
    };

    function tr(key) {
        var dict = I18N[lang] || I18N.en;
        return dict[key] || (I18N.en[key] || key);
    }

    function copyTextToClipboard(text) {
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text);
        } else {
            var ta = document.createElement('textarea');
            ta.value = text;
            document.body.appendChild(ta);
            ta.select();
            document.execCommand('copy');
            document.body.removeChild(ta);
        }
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

    function loadUnifiedFavorites() {
        try {
            var raw = localStorage.getItem(FAV_UNIFIED_KEY);
            return raw ? JSON.parse(raw) : [];
        } catch (e) { return []; }
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

    function normalizeStringList(v) {
        if (!v || typeof v !== 'object') return [];
        if (Array.isArray(v)) return v.filter(function (x) { return typeof x === 'string'; });
        return Object.keys(v).map(function (k) { return v[k]; }).filter(function (x) { return typeof x === 'string'; });
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
        var title = document.querySelector('.title');
        if (title) title.textContent = tr('title');
        var search = document.getElementById('search-input');
        if (search) search.placeholder = tr('searchPlaceholder');
    }

    function setGridOrPlaced(mode) {
        var gridWrap = document.getElementById('content-grid-wrap');
        var placedEl = document.getElementById('content-placed');
        var isPlaced = mode === 'placed';
        if (gridWrap) gridWrap.classList.toggle('hidden', isPlaced);
        if (placedEl) placedEl.classList.toggle('hidden', !isPlaced);
        if (isPlaced) renderPlaced();
        else render();
    }

    function setView(view) {
        currentView = view;
        categoryCatKey = null;
        categorySubKey = null;
        catalogPage = 1;
        if (view === 'placed') placedPage = 1;
        updateNavActive();
        setGridOrPlaced(view === 'placed' ? 'placed' : 'grid');
    }

    function getModelsForView() {
        if (currentView === 'all') return allProps.filter(matchesSearch);
        if (currentView === 'favorites') return favoritesCache.filter(matchesSearch);
        if (currentView === 'peds') return pedsCatalog.filter(matchesSearch);
        if (currentView === 'blips') {
            return blipsCatalog.filter(function (row) {
                if (!row || typeof row.name !== 'string') return false;
                if (!searchQuery) return true;
                return (row.name + ' ' + (row.sprite || '')).toLowerCase().indexOf(searchQuery.toLowerCase()) !== -1;
            });
        }
        return [];
    }

    function renderCard(model) {
        var isBlip = currentView === 'blips';
        var isPed = currentView === 'peds';
        var displayModel = isBlip && model ? model.name : model;

        var card = document.createElement('div');
        card.className = 'prop-card';

        var tw = document.createElement('div');
        tw.className = 'prop-thumb-wrap';
        var img = document.createElement('img');
        img.className = 'prop-thumb';
        img.src = propImageSrc(displayModel);
        img.onerror = function () {
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
        name.textContent = displayModel;

        var actions = document.createElement('div');
        actions.className = 'prop-actions';

        var btnCopy = document.createElement('button');
        btnCopy.type = 'button';
        btnCopy.className = 'btn-copy';
        btnCopy.textContent = tr('copy');
        btnCopy.addEventListener('click', function (e) {
            e.stopPropagation();
            copyTextToClipboard(displayModel);
        });
        actions.appendChild(btnCopy);

        var btnFav = document.createElement('button');
        btnFav.type = 'button';
        var fk = favEntryKey(isBlip ? 'blip' : (isPed ? 'ped' : 'prop'), displayModel);
        btnFav.className = 'btn-fav' + (isFavoriteKey(fk) ? ' on' : '');
        btnFav.textContent = isFavoriteKey(fk) ? '★' : '☆';
        btnFav.addEventListener('click', function (e) {
            e.stopPropagation();
            toggleFavoriteKey(fk);
        });
        actions.appendChild(btnFav);

        var btnPlace = document.createElement('button');
        btnPlace.type = 'button';
        btnPlace.className = 'btn-place';
        btnPlace.textContent = isPed ? tr('spawnPed') : tr('placeBtn');
        btnPlace.addEventListener('click', function (e) {
            e.stopPropagation();
            if (isBlip) post('beginPlaceBlip', { name: displayModel });
            else if (isPed) post('spawnPedAtPlayer', { model: displayModel });
            else post('beginPlace', { model: displayModel });
        });
        actions.appendChild(btnPlace);

        bar.appendChild(name);
        bar.appendChild(actions);
        card.appendChild(tw);
        card.appendChild(bar);
        return card;
    }

    function render() {
        var grid = document.getElementById('props-grid');
        if (!grid) return;
        grid.innerHTML = '';

        var items = getModelsForView();
        if (items.length === 0) {
            var empty = document.createElement('div');
            empty.className = 'empty-msg';
            empty.textContent = tr('nothingFound');
            grid.appendChild(empty);
            return;
        }

        var start = (catalogPage - 1) * catalogPageSize;
        var pageItems = items.slice(start, start + catalogPageSize);
        pageItems.forEach(function (m) {
            grid.appendChild(renderCard(m));
        });
    }

    function renderPlaced() {
        var el = document.getElementById('content-placed');
        if (!el) return;
        el.innerHTML = '';

        var toolbar = document.createElement('div');
        toolbar.className = 'placed-toolbar';
        var bYmap = document.createElement('button');
        bYmap.type = 'button';
        bYmap.className = 'btn-place';
        bYmap.textContent = tr('exportYmap');
        bYmap.addEventListener('click', function () {
            post('exportYmap', {});
        });
        toolbar.appendChild(bYmap);
        el.appendChild(toolbar);

        if (placedList.length === 0) {
            var empty = document.createElement('div');
            empty.className = 'empty-msg';
            empty.textContent = tr('noPlacedYet');
            el.appendChild(empty);
            return;
        }

        var table = document.createElement('table');
        table.className = 'placed-table';
        var thead = document.createElement('thead');
        thead.innerHTML = '<tr><th>' + tr('tableModel') + '</th><th>' + tr('tableCoords') + '</th><th>' + tr('placedActions') + '</th></tr>';
        table.appendChild(thead);

        var tbody = document.createElement('tbody');
        placedList.forEach(function (row) {
            var trEl = document.createElement('tr');
            var tdM = document.createElement('td');
            tdM.textContent = row.model;
            var tdC = document.createElement('td');
            tdC.textContent = (row.x ? row.x.toFixed(2) : '0') + ', ' + (row.y ? row.y.toFixed(2) : '0') + ', ' + (row.z ? row.z.toFixed(2) : '0');
            var tdA = document.createElement('td');
            
            var bTp = document.createElement('button');
            bTp.textContent = tr('teleport');
            bTp.addEventListener('click', function () { post('placedTeleport', { id: row.id }); });
            
            var bCp = document.createElement('button');
            bCp.textContent = tr('copyCoords');
            bCp.addEventListener('click', function () { copyTextToClipboard(tdC.textContent); });

            var bDel = document.createElement('button');
            bDel.className = 'danger';
            bDel.textContent = tr('del');
            bDel.addEventListener('click', function () { post('placedDelete', { id: row.id }); });

            tdA.appendChild(bTp);
            tdA.appendChild(bCp);
            tdA.appendChild(bDel);
            trEl.appendChild(tdM);
            trEl.appendChild(tdC);
            trEl.appendChild(tdA);
            tbody.appendChild(trEl);
        });
        table.appendChild(tbody);
        el.appendChild(table);
    }

    function showPlacement(data) {
        var root = document.getElementById('app-root');
        if (root) root.classList.add('placement-world-visible');
        var shell = document.querySelector('.gizmo-shell');
        if (shell) shell.classList.add('hidden');
        var dock = document.getElementById('placement-dock');
        var label = document.getElementById('placement-model-label');
        if (label && data.model) label.textContent = data.model;
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
        if (range) {
            range.addEventListener('input', function () {
                if (pct) pct.textContent = range.value + '%';
                post('placementSetSpeed', { percent: parseInt(range.value, 10) });
            });
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
        allProps = normalizeStringList(data.allProps || []);
        pedsCatalog = normalizeStringList(data.peds || []);
        blipsCatalog = Array.isArray(data.blips) ? data.blips : [];
        if (data.resourceName) resourceName = data.resourceName;
        thumbBase = data.thumbBase || '';
        lang = data.lang || 'en';
        refreshFavoritesCache();
        applyStaticI18n();
        var root = document.getElementById('app-root');
        if (root) root.classList.remove('hidden');
        setView('all');
    }

    function closeApp() {
        var root = document.getElementById('app-root');
        if (root) root.classList.add('hidden');
        hidePlacement();
    }

    window.addEventListener('message', function (event) {
        var data = event.data;
        if (!data || !data.action) return;
        if (data.action === 'open') openApp(data);
        if (data.action === 'close') closeApp();
        if (data.action === 'placedList') {
            placedList = Array.isArray(data.list) ? data.list : [];
            if (currentView === 'placed') renderPlaced();
        }
        if (data.action === 'showPlacement') showPlacement(data);
        if (data.action === 'hidePlacement') hidePlacement();
    });

    document.getElementById('btn-close').addEventListener('click', function () {
        post('close', {});
    });

    document.getElementById('search-input').addEventListener('input', function (e) {
        searchQuery = (e.target && e.target.value) || '';
        catalogPage = 1;
        render();
        if (searchQuery.length >= 2 && currentView === 'all') {
            fetch('https://' + getRes() + '/searchArchetype', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ query: searchQuery })
            }).then(function (res) { return res.json(); }).then(function (extraResults) {
                if (Array.isArray(extraResults) && extraResults.length > 0) {
                    extraResults.forEach(function (m) {
                        if (allProps.indexOf(m) === -1) {
                            allProps.push(m);
                        }
                    });
                    render();
                }
            }).catch(function () {});
        }
    });


    document.getElementById('sidebar-nav').addEventListener('click', function (e) {
        var t = e.target;
        if (!t || !t.classList.contains('nav-btn')) return;
        var v = t.getAttribute('data-view');
        if (v) setView(v);
    });

    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') {
            var dock = document.getElementById('placement-dock');
            if (dock && !dock.classList.contains('hidden')) {
                post('placementCancel', {});
            } else {
                post('close', {});
            }
        }
    });

    setupPlacementControls();
})();
