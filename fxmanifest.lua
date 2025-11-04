fx_version 'cerulean'
game 'gta5'

author 'Luudi'
description 'ESX Parking Fine System med ox_lib integration'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'locales/*.lua'
}

dependencies {
    'es_extended',
    'ox_lib',
    'oxmysql'
}
