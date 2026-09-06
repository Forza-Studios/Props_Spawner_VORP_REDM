$ErrorActionPreference = 'Stop'
$data = Join-Path $PSScriptRoot '..\data'
$u = [System.Text.UTF8Encoding]::new($false)

$statues = @(
    'mp001_s_whittlingwolf01a','mp001_s_whittlingwolf01b','mp001_s_whittlingwolf01c','mp001_s_whittlingwolf01d','mp001_s_whittlingwolf01e',
    'mp001_s_whittlingwolf02a','mp001_s_whittlingwolf02b','mp001_s_whittlingwolf02c','mp001_s_whittlingwolf02d','mp001_s_whittlingwolf02e',
    'p_cherubstatuenbx01x','p_cs_statue_button01x','p_cs_statue_int_lid01x','p_cs_statue01x','p_dragon_chinatown01x','p_exoticprops06x','p_exoticprops25x','p_gen_statue01x','p_gen_statue02b','p_gen_statue03b','p_gen_statue03x','p_guarma_pil_01',
    'p_headbust01x','p_headbust02x','p_headbust03x','p_new_cem_statue02x','p_sc_cupid_statue01x','p_sculpturedeer01x','p_statue07x','p_statue08x','p_statueharrisnbx01x','p_statuenbcom06x','s_inv_trinket_flower_spun',
    's_whittlingwolf01a','s_whittlingwolf01b','s_whittlingwolf01c','s_whittlingwolf01d','s_whittlingwolf01e','s_whittlingwolf02a','s_whittlingwolf02b','s_whittlingwolf02c','s_whittlingwolf02d','s_whittlingwolf02e'
)
[System.IO.File]::WriteAllText((Join-Path $data 'deco_statues_include.txt'), ($statues -join ','), $u)

$stuffed = @(
    'p_badger01x','p_badger02x','p_badger03x','p_cardinal01bx','p_cardinal01cx','p_cardinal01x','p_cougar_01x','p_eagle01bx','p_eagle01cx','p_eagle01x','p_exoticprops11x','p_fox01x','p_fox02x','p_fox03x','p_foxpheasant01x','p_gatorgunrack01x',
    'p_heron01bx','p_heron01x','p_heronloon01x','p_int_hunting01','p_taxibeaver01x','p_taxidermycoyote01x','p_taxidermycoyote02x','p_taxidermycoyote03x','p_taxidermydeer01x','p_taxidermyhawk01x','p_taxidermyhawk02x','p_taxidermyhawk03x',
    'p_taxidermyowl01x','p_taxidermypheasant02x','p_taxidermyvulture01x','p_taxidermyvulture02x','p_taxidermyvulture03x','p_taxidermyvulture04x','p_trex_partb','p_triceratops_partb','p_tuxyoungaligator01x','p_tuxyoungaligator02x','p_youngalligator01x',
    's_squirrelmarston01x','s_taxidermydiorama010x','s_taxidermydiorama01x','s_taxidermydiorama02x','s_taxidermydiorama03x','s_taxidermydiorama04x','s_taxidermydiorama05x','s_taxidermydiorama06x','s_taxidermydiorama07x','s_taxidermydiorama08x','s_taxidermydiorama09x'
)
[System.IO.File]::WriteAllText((Join-Path $data 'deco_stuffed_include.txt'), ($stuffed -join ','), $u)

$poster = @(
    'mp005_p_mp_collectorsign01x','mp005_p_mp_collectorsign02x','mp005_s_posse_col_posters02x','mp005_s_posse_col_posters03x','p_beaumontburly01x','p_cs_pamphlet02x','p_cs_pamphlet03x','p_cs_stackcholera01x','p_cs_stackscarlet01x','p_directdamnation01x','p_farmersdaughter01x','p_fiddle_de01x','p_fitcherbrothe01x','p_ghastlyserenade01x','p_josiahblackwate01x','p_lily_lucife01x','p_lovepotions01x','p_manflight01x','p_medicalchart01x','p_modernmedicine01x','p_mr_bear01x','p_poster_troub01x_lrg','p_saviorssavages01x','p_sign01x','p_sign02x','p_sign03x','p_sign05x','p_signtorn01x','p_signtorn02x','p_signtorn03x','p_signtorn04x','p_sweetheart01x','p_tinsign01x','p_tinsign02x','p_tinsign03x','p_tinsign04x','p_tinsignbloodeyes01x','p_tinsignschiffer01x','p_troubadours01x','p_vaudeville_fire','p_vaudeville_fire_frm','p_vaudevilleband','p_vaudevilleband_frm','p_vaudevillecancan','p_vaudevillecancan_frm','p_vaudevillemagician','p_vaudevillemagician_frm','p_vaudevilleoddfellows_frm','p_vaudevillesdance','p_vaudevillesdance_frm','p_vaudevilleswoman','p_vaudevilleswoman_frm','p_yodellingyeoman01x'
)
[System.IO.File]::WriteAllText((Join-Path $data 'deco_poster_include.txt'), ($poster -join ','), $u)

$various = @(
    'mp001_p_mp_globe02x','mp005_p_mp_crystalball01x','mp005_p_mp_crystalball01x_stand','mp005_s_posse_col_bat01x','mp005_s_posse_col_tel_astro_01x','mp007_p_mp_jarspecimen04x','mp007_p_mp_jarspecimen05x','mp007_p_mp_jarspecimen06x','mp007_p_taxidermy_base02x','mp007_p_taxidermy_base03x',
    'p_adl_drwsng01x','p_binocular_case_closed','p_binocular_case_open','p_binoculars01x','p_colorchart','p_crackpotloudspeaker01x','p_crackpotmicrophone01x','p_cs_easel01x','p_cs_easel02x','p_cs_megaphone01x','p_cs_stolen04x','p_depositboxgroup01x','p_door_stop_001','p_duster01x','p_firehydrantnbx01x','p_flintpiece01x','p_gavel01x','p_globe02x','p_hotairballoon01x','p_magnifyingglass01x','p_marstonwagonpiece02x','p_monocular01x','p_shadyprops03x','p_shadyprops07x','p_shadyprops08x','p_shadyprops10x','p_specimenbox01x','p_specimenbox02x','p_strawbgroup02x','p_telegraph01x','p_telescope01x','p_vanstoreprops01x','p_vanstoreprops02x','p_vanstoreprops03x','p_vanstoreprops04x','p_vanstoreprops05x','p_vanstoreprops06x','p_veh_caboose01x_1','p_wallplaque01x','s_airshipcrashed02x','s_barberscissors01x','s_bullhorntrinket01x','s_condorbeaktrinket','s_drugpackage_02x','s_escapebox01x','s_escapeboxknife01x','s_fortuneteller01x','s_ind1_redrope01x','s_jawharpcase01x','s_mask_pig01x','s_npc_binoculars01x','s_phonewall01x','s_scissors01x','s_scissors02x','s_ufo01x','s_ufo02x','s_warship01x','s_warship02x','w_binoculars01x','w_binoculars02'
)
[System.IO.File]::WriteAllText((Join-Path $data 'deco_various_include.txt'), ($various -join ','), $u)

$umbrella = @('mp004_p_parasol04x','p_hangingumbrella01x','p_parasol_cs02x','p_parasol01x','p_parasol02x','p_parasol03x','p_umbrella01x','p_umbrellanbx01x','p_umbrellanbx01xcs','p_umbrellanbx02x','p_umbrellanbx02x_static','p_umbrellanbx03x','s_umbrellanbx01x')
[System.IO.File]::WriteAllText((Join-Path $data 'deco_umbrella_include.txt'), ($umbrella -join ','), $u)

$vase = @('p_teamster_break01x_lrg','p_teamster_break01x_med','p_teamster_break01x_sml','p_urn01x','p_urn02x','p_vase01x','p_vase05x','p_vase06x','p_winecooler01x')
[System.IO.File]::WriteAllText((Join-Path $data 'deco_vase_include.txt'), ($vase -join ','), $u)

$wall = @('mp005_p_mp_photobackdrop02x_can','mp005_p_mp_photobackdrop02x_col','mp005_p_mp_photobackdrop02x_con','mp005_p_mp_photobackdrop02x_d','mp005_p_mp_photobackdrop02x_int','mp005_p_mp_photobackdrop02')
[System.IO.File]::WriteAllText((Join-Path $data 'deco_wallpainting_include.txt'), ($wall -join ','), $u)

$xmas = @('mp006_p_veh_xmasnsteamer01x','mp006_p_wreath01x','mp006_p_xmas_coal01x','mp006_p_xmastree01x','mp006_s_lootablechest03x','mp006_s_markercandycane','mp006_s_markergingerbread','mp006_s_racexmasflag01x')
[System.IO.File]::WriteAllText((Join-Path $data 'deco_xmas_include.txt'), ($xmas -join ','), $u)

Write-Host 'deco tail includes OK'
