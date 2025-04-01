fx_version 'cerulean'
game 'gta5'

author 'TvojeMeno'
description 'Vlastny bankovy system pre QBCore'
version '1.0.0'

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

-- Odstranene html subory, ktore neexistuju a sposobuju varovanie
-- ui_page 'html/index.html'
-- 
-- files {
--    'html/index.html',
--    'html/style.css',
--    'html/script.js'
-- }

dependencies {
    'qb-core',
    'qb-menu',
    'qb-input'
}