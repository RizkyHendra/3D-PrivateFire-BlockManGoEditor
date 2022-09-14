print('script_common:hello world')

Entity.addValueDef("dateData",{
    curtWeek = tonumber(Lib.getYearWeekStr(os.time())),
    totalLoginCount = 0,
    lastDay = 0
}
,false,false,true)