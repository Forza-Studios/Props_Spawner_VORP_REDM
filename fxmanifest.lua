fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'RSG Framework / Original'
description 'RSG Prop Placement Gizmo, Catalog Browser, Streaming & YMAP Exporter'
lua54 'yes'

shared_script 'config.lua'

client_scripts {
    'client/archetype_indexer.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

connect 'raw.githubusercontent.com'
connect 'cdn.jsdelivr.net'

files {
    'data/*',
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/img/*'
}
