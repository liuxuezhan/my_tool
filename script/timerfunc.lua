module("timer")

_funs["toGate"] = function(sn, ip, port)
        conn.toGate(ip, port)
    end

_funs["toMongo"] = function(sn, host, port, db)
        conn.toMongo(host, port, db)
    end

_funs["cron"] = function(sn)
        local nextCron = 60 - (gTime % 60) + 30
        timer.new("cron", nextCron)

        mem_info()
        monster.loop()
        farm.loop()
        crontab.loop()
    end

_funs["cure"] = function(sn, pid, cures)
        local p = getPlayer(pid)
        if p then
            p:addTips("timeout cure")
            for _, v in pairs(cures) do
                LOG("cure, arm=%d, num=%d", v[1], v[2])
                p:inc_arm(v[1], v[2])
            end
        end
    end

_funs["cure_hero"] = function(sn, pid, hero_idx, delta_hp)
    local p = getPlayer(pid)
    if p then
        p:do_timer_cure_hero(sn, hero_idx, delta_hp)
    else
        ERROR("[timerfunc.cure_hero]: get player failed. pid = %d, hero_idx = %d, delta_hp = %d.", pid, hero_idx, delta_hp)
    end
end

_funs["troop"] = function(sn, pid, tid)
        local p = getPlayer(pid)
        p:doTimerTroop(sn, tid)
    end

_funs["build"] = function(sn, pid, build_idx)
        local p = getPlayer(pid)
        p:doTimerBuild(sn, build_idx)
    end

_funs["learn_tech"] = function(sn, pid, build_idx, tech_id)
    local p = getPlayer(pid)
    if p then
        p:doTimerBuild(sn, build_idx, tech_id)
    else
        ERROR("[timerfunc.learn_tech]: get player failed. pid = %d, build_idx = %d, tech_id = %d.", pid, build_idx, tech_id)
    end
end

_funs["mass"] = function(sn, uid, idx)
    local union = unionmng.get_union(uid)
    union:do_timer_mass(sn, idx)
end

_funs["uniontech"] = function(sn, uid, idx)
    local union = unionmng.get_union(uid)
    union:do_timer_tech(sn, idx)
end


_funs["test"] = function(sn, uid, idx)
    local p = getPlayer(30001)
    local ts = p:get_item()
    dumpTab(ts, "item")
end

_funs["release_prisoner"] = function(sn, pid, hero_id)
    local p = getPlayer(pid)
    if p then
        p:release_prisoner(hero_id, sn)
    else
        ERROR("[timerfunc.release_prisoner]: get player failed. pid = %d, hero_id = %d.", pid, hero_id)
    end
end

_funs["kill_hero"] = function(sn, pid, build_idx, hero_id, buff_id, buff_time)
    local p = getPlayer(pid)
    if p then
        -- p:real_kill_hero(hero_id, buff_id, buff_time)
        p:doTimerBuild(sn, build_idx, hero_id, buff_id, buff_time)
    end
end

_funs["delete_kill_buff"] = function(sn, pid, buff_id)
    local p = getPlayer(pid)
    if p then
        p:update_kill_buff(buff_id)
    end
end

_funs["destroy_dead_hero"] = function(sn, hero_id)
    local hero = heromng.get_hero_by_uniq_id(hero_id)
    if hero and hero.status ~= HERO_STATUS_TYPE.DEAD then
        heromng.destroy_hero(hero_id)
    end
end
