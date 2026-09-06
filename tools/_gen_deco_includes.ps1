$ErrorActionPreference = 'Stop'
$data = Join-Path $PSScriptRoot '..\data'

function Write-OneLine($path, $parts) {
    [System.IO.File]::WriteAllText($path, ($parts -join ','), [System.Text.UTF8Encoding]::new($false))
}

$newpaper = [System.Collections.Generic.List[string]]::new()
foreach ($x in @(
    'p_cs_bridecatpage01x','p_cs_newsclip03x','p_cs_newspaper_01x','p_cs_newspaper_02x','p_cs_newspaper_02x_noanim','p_cs_newspaper_03x','p_cs_oldpaper1889','p_depotpapers01x',
    'p_group_newspaper01','p_group_newspaper02','p_group_newspaper03','p_group_newspaper04','p_group_newspaperstack',
    'p_newspaper_cs02x','p_newspaper_cs02xnhg','p_newspaper_cs02xsdtt','p_newspaper01x','p_newspaper01x001','p_newspaperbox_cs01x','p_newspaperbw01x',
    'p_newspapergroup01x','p_newspapergroup02x','p_newspaperlivestock01x','p_newspapernbx01x','p_newspaperroll01x','p_newspapersdx01x','p_newspaperset01x',
    'p_newspaperstack01x','p_newspaperstack02x','p_newspaperstack03x'
)) { [void]$newpaper.Add([string]$x) }
foreach ($prefix in @('p_newspaperstandbl_','p_newspaperstandnh_','p_newspaperstandsd_')) {
    foreach ($i in 1..14) {
        $n = '{0:D2}' -f $i
        [void]$newpaper.Add($prefix + $n + 'x')
    }
}
foreach ($x in @('p_newspapervalx01x','p_newsstand01x_new','s_cs_bl_newspaper01x','s_cs_nh_newspaper01x','s_cs_sd_newspaper01x','s_cs_sd_newspaper05x','s_misclockbox_loot_j')) { [void]$newpaper.Add($x) }
Write-OneLine (Join-Path $data 'deco_newpaper_include.txt') $newpaper

$paint = @(
    'kill','mp005_s_posse_col_posters01x'
) + (1..15 | ForEach-Object { 'mp006_p_mshn_painting{0:D2}x' -f $_ }) + (1..7 | ForEach-Object { 'mp007_p_nat_pictureframe{0:D2}x' -f $_ }) + @(
    'mp008_p_mshn_painting16x','mp008_p_mshn_painting17x','p_blackwater_josiah_01x',
    'p_cs_frame01ax','p_cs_frame01x','p_cs_frame01x_02','p_cs_frame02ax','p_cs_frame02x','p_cs_frame02x_02','p_cs_frame03ax','p_cs_frame03x','p_cs_frame03x_02',
    'p_cs_frame04ax','p_cs_frame04x','p_cs_frame04x_02','p_cs_frame05ax','p_cs_frame05x','p_cs_frame05x_02','p_cs_frame06ax','p_cs_frame06x',
    'p_cs_frame07ax','p_cs_frame07x','p_cs_frame07x_02','p_cs_frame08ax','p_cs_frame08x','p_cs_frame08x_02','p_cs_frame09ax','p_cs_frame09x','p_cs_frame09x_02',
    'p_cs_sketch01x','p_flowerframe01x','p_needlework01x','p_painting_newgala_lrg01x','p_painting_newgala_sml01x','p_painting02x','p_paintings01x','p_picturemirror02x',
    'p_spainting_01','p_stdenismap01x','s_abe_grandmapic01x','s_gunsmithframe01x'
)
Write-OneLine (Join-Path $data 'deco_paint_include.txt') $paint

$papers = @(
    'mp004_s_mp_bondrolled01x','mp005_p_collector_cigholder01x','mp005_p_cs_rollupcig01x_mp','mp005_p_mp_bountyposter01x','mp005_p_mp_bountyposter02x','mp005_p_mp_bountyposter03x',
    'mp005_p_mp_lettertradecripps01x','mp006_p_mnshine_int_blueprint_01x','mp006_p_mnshine_int_blueprint_02x','mp008_p_mp_letter01x','mp008_p_mp_letter01x_clean',
    'mp008_p_mp_letter02x_clean2','mp008_p_mp_letter03x_brown','mp008_p_mp_letter04x_bloody','mp008_p_mp_letter05x_old','mp008_p_poster_lbm_shepardvergil01x','mp008_p_poster_lbm_shepardvergil02x',
    'p_cs_admitticket01x','p_cs_advertposter01x','p_cs_buildingplan01x','p_cs_deed01x','p_cs_deed02x','p_cs_envelope_cls_blank','p_cs_envelope_mayor','p_cs_envelope01x','p_cs_envelope02x',
    'p_cs_letter01a_x','p_cs_letter01a_x_01','p_cs_letter01a_x_02','p_cs_letter01b_x','p_cs_letter01c_x','p_cs_letter01e_x','p_cs_letter02x','p_cs_letter02x_bundle','p_cs_letter02x_env',
    'p_cs_letter03x','p_cs_letter03x_color','p_cs_letter03xa','p_cs_letter04x','p_cs_letter05x','p_cs_letter06x','p_cs_letter07x','p_cs_letter08x','p_cs_letter09x',
    'p_cs_letterfolded_old','p_cs_letterfolded01x','p_cs_letterfolded02x','p_cs_letterfrzdth','p_cs_letterrolled01x','p_cs_lettersandy01x','p_cs_note02x','p_cs_pamphlet01x','p_cs_paperpetition01x',
    'p_cs_photogunslgr','p_cs_pieceofpaperlist01x','p_cs_ripped_paper01bx','p_cs_ripped_paper01cx','p_cs_ripped_paper01x','p_cs_rollupcig01x','p_cs_rt_envelope01x','p_cs_scroll01x',
    'p_cs_shoplist01x','p_cs_siloinstruction01x','p_cs_smallnotecard01x','p_deed_cs01x','p_letter_cs01x','p_letter01x','p_letterenvelope_cs01x','p_pamphletstack01x',
    'p_paper01x','p_paper02x','p_paper03x','p_papercert01a','p_papercontract01a','p_paperdiploma01a','p_paperdrafting01a','p_paperdrafting01b','p_papergroup01x','p_papergroup02x','p_papergroup06x',
    'p_paperstack01a','p_paperstack01x','p_paperstackcom01x','p_papertyped01a','p_re_fund_sign02x','p_telegram01x','s_bottlemessagepaper01x','s_businesscard01x','s_centralunion_env','s_convictionlist01x',
    's_cs_bookhardpaper01x','s_deed_cs01x','s_easterntraintime01x','s_flyswarm01x','s_frozennote01x','s_inv_pamppothorse01x','s_inv_paper01a_x','s_inv_paper01b_x','s_inv_paper01c_x','s_inv_paper01d_x','s_inv_paper01e_x',
    's_inv_paper02a_x','s_inv_paper02b_x','s_inv_paper02c_x','s_inv_paper02d_x','s_inv_paper02e_x','s_lannahecheetraintime01x','s_leaflet01x','s_leafletstack01x','s_misclockbox_loot_d','s_mollyloveletter',
    's_purchasenotice01x','s_re_letterguama01x','s_rhodesbankplan01x','s_spc_schematic01x','s_stagecoachtimetable01x','s_trainplanrolled01x','s_trainschedule01x'
)
Write-OneLine (Join-Path $data 'deco_papers_include.txt') $papers

$photo = @(
    'mp001_mp_photo_alfredomontez_01x','mp001_mp_photo_jacksonjames_01x','mp001_mp_photo_shaky_01x','mp001_p_cs_photo_amos','mp001_p_cs_photo_grace','mp001_p_cs_photo_jeremiah','mp001_p_cs_photo_teddy',
    'mp006_p_moonshine_theme_festive','mp006_p_moonshine_theme_floral','mp006_p_moonshine_theme_hunter','mp006_p_moonshine_theme_refined','mp007_p_moonshine_theme_gothic',
    'mp008_p_moonshine_theme_photocomp01x','mp008_p_moonshine_theme_photocomp02x'
) + (1..6 | ForEach-Object { 'p_cs_gunslingerphoto{0:D2}x' -f $_ }) + @(
    'p_cs_photogunslgrdead'
) + (1..5 | ForEach-Object { 'p_cs_photonudie{0:D2}x_4x6' -f $_ }) + @(
    'p_cs_photowolves','p_si_photomanor01x','s_pic_adlermarriage01x','s_pic_arthursmom01x','s_pic_bronte01x','s_pic_charlesparent01x','s_pic_gunslingerbilly01x','s_pic_gunslingerblack01x',
    's_pic_gunslingeremmet01x','s_pic_gunslingerflaco01x','s_pic_gunslingerfrank01x','s_pic_gunslingerslim01x','s_pic_hoseaandwife','s_pic_mary01x','s_pic_missinghusband01x','s_pic_norlady01x',
    's_pic_rhodesgunsmith01x','s_pic_rockymansion01x','s_pic_younggrimshaw','s_pictureframe11x','s_pictureframe13x','s_pictureframe14x','s_trapdoorphoto'
)
Write-OneLine (Join-Path $data 'deco_photo_include.txt') $photo

Write-Host 'Generated deco_newpaper_include, deco_paint_include, deco_papers_include, deco_photo_include'
