$ErrorActionPreference = 'Stop'
$data = Join-Path $PSScriptRoot '..\data'
$utf8 = [System.Text.UTF8Encoding]::new($false)

$plant = @(
    'mp005_s_posse_bottleterrarium01x','mp006_p_mp_potflowerarng01x','mp008_s_usd7_metal01x','mp008_s_usd7_metal01x_grnd','mp008_s_usd7_woodchop01x','mp008_s_usd7_woodchop01x_grnd','mp008_s_usd7_woodplank01x','mp008_s_usd7_woodplank01x_grnd',
    'p_basket06bx','p_belljarplant01x','p_bowlplantbra01x','p_exoticprops03x','p_exoticprops07x','p_exoticprops08x','p_exoticprops09x','p_exoticprops10x','p_exoticprops13x','p_exoticprops14x','p_exoticprops15x','p_exoticprops18x','p_exoticprops19x','p_exoticprops21x','p_exoticprops22x','p_exoticprops23x','p_exoticprops24x',
    'p_group_flowertable01','p_plant_int_03b','p_plant_int_04a','p_plant_moneytree','p_plant_philo','p_plant_philo2','p_plant_philo3','p_plant04x','p_plant05x','p_plant06x','p_planter','p_planter03a','p_planter03x','p_planternbx04a','p_planternbx04b','p_planternbx04c',
    'p_plantpothangnbx01x','p_plantpothangnbx02x','p_plantpotnbx02x','p_plantpotnbx03x','p_plantpotnbx04x','p_plantpotnbx05x','p_plantpotnbx06x','p_plantpotnbx07x','p_plantpotnbx08x','p_plantpotwallnbx01x','p_plantpotwallnbx02x',
    'p_pot_flowerarng01x','p_pot_flowerarng02x','p_pot_flowerarng03x','p_pot_flowerarng05x','p_pot_flowerarng06x','p_pot_flowerarng07x','p_pot_flowerarng08x','p_pot_flowerarng09bx','p_pot_flowerarng09x','p_pot_flowerarng10x','p_pot_flowerarng11x','p_pot_flowerarng16x','p_pot_flowerarng17x','p_pot_flowerarng18x','p_pot_flowerarng19x','p_pot_flowerarng20x','p_pot_flowerarng23x',
    'p_pot_flowerarngdead02','p_pot_leafyvase','p_pot_plant_01b','p_pot_plant_01e','p_pot_plant_01g','p_pot_plant_03b','p_pot_plant_05a','p_pot_plant_05b','p_pot_plant_08a','p_pot_plant_6a','p_pot_plant_6b','p_pot_plant_7_static','p_pot_plant_7a','p_pot_plant_7b','p_pot_plant_7c',
    'p_potfernbalcony01x','p_potfernbalcony02x','p_potfernbalcony02xb','p_potfernbalcony05xb_a','p_potfernbalcony05xb_b','planter_01a','s_canyonflowerjar01x'
)
[System.IO.File]::WriteAllText((Join-Path $data 'deco_plant_include.txt'), ($plant -join ','), $utf8)

$planter = @(
    'p_bowlplantnbx01x','p_bowlplantnbx01xb','p_bowlplantnbx02x','p_dirtpot01x','p_exoticprops12x','p_exoticprops16x','p_exoticprops17x','p_exoticprops20x','p_group_pot01x','p_planter01x','p_planternbx01x','p_planternbx02x','p_pot_plant_01f','p_potceramicnbx01x',
    'p_potclay01x','p_potclay02x','p_potclay03x','p_potclay04x','p_potclay05x','p_potclaynbx01x','p_potteryindian09x','p_potterynbx01x','p_terracottapot01x','p_terracottapotstack01x'
)
[System.IO.File]::WriteAllText((Join-Path $data 'deco_planter_include.txt'), ($planter -join ','), $utf8)

Write-Host 'deco_plant_include, deco_planter_include'
