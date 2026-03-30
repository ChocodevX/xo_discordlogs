fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'C2 Discord Logs'
version '1.0.0'
author 'C2'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.deathcauses.lua',
    'shared/config.general.lua'
}

export 'Discord'

server_scripts {
    'server/config.main.lua',
    'server/config.functions.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'ox_lib',
    -- 'es_extended',
    -- 'screenshot-basic'
}
