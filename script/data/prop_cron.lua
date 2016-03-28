module("resmng")
prop_cron = {
    [1] = {game="*", boot=nil, min="*", hour="*", day="*", month="*", wday="*", action="cronTest", arg={1, "hello"}},
    [2] = {game="*", boot=nil, min="17", hour="5", day="*", month="*", wday="*", action="clean", arg={1, "hello"}},
    [3] = {game="*", boot=true, min="*", hour="5", day="*", month="*", wday="*", action="setDayStart", arg={1, "hello"}},
    [4] = {game="*", boot=nil, min="1", hour="5", day="*", month="*", wday="*", action="union_donate_summary", arg={}},
}
