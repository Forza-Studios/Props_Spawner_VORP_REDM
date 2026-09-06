fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'VORP / custom'
description 'Admin prop browser and gizmo placement (/gizmo)'
lua54 'yes'

-- Start vorp_core or rsg-core before this resource (see Config.Framework).

shared_script 'config.lua'

client_scripts {
    'client/skin_applied.lua',
    'client/fixanimals_attack_types_data.lua',
    'client/animal_skin_assist.lua',
    'client/main.lua',
    'client/death_skin_compat.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'html/index.html'

-- NUI: ped preview JPGs from rdr3-nativedb-data (GitHub raw + jsDelivr mirror).
connect 'raw.githubusercontent.com'
connect 'cdn.jsdelivr.net'

files {
    'data/spooni_catalog.json',
    'data/bank_props.json',
    'data/peds_catalog.json',
    'data/blips_catalog.json',
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/img/*',
}


escrow_ignore {
    'config.lua',
    'client/skin_applied.lua',
    'client/fixanimals_attack_types_data.lua',
    'client/animal_skin_assist.lua',
    'client/death_skin_compat.lua',
    'html/index.html',
    'html/style.css',
    'html/script.js',
}
dependency '/assetpacks'
dependency '/assetpacks-redm'