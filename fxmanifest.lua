fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'BT scripts'
description 'Donatie Voertuigen Testrit Systeem voor ESX'
version '1.1.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'modules/utils.lua',
    'modules/ui.lua', 
    'modules/vehicles.lua',
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'es_extended',
    'ox_lib'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png'
} 