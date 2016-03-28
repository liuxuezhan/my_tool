module("fight", package.seeall)
--todo when to clean?
gFightReports = gFightReports or {}

function init_arg_match()
    local t = {}
    for amode = 1, 4, 1 do
        local tt = {}
        t[amode] = tt
        for dmode = 1, 4, 1 do
            local ttt = {
                [1] = {"Atk_R", string.format("Atk%d_R", amode), string.format("AAtk%d_R",dmode)},
                [2] = {"Imm_R", string.format("Imm%d_R", dmode), string.format("DImm%d_R",amode)}
            }
            tt[ dmode] = ttt
        end
    end
    gArgMatch = t
end

init_arg_match()

local function _attack(A, As, D, Ds, mode, rate)
    rate = rate or 1

    local amode = A.mode
    local dmode = D.mode

    A.hit = dmode

    local node = gArgMatch[ amode ][ dmode ]

    local atkR = 0
    local immR = 0
    for _, v in pairs(node[1]) do atkR = atkR + (As[ v ] or 0) + A.ef[ v ] + As.ef[ v ] end
    for _, v in pairs(node[2]) do immR = immR + (Ds[ v ] or 0) + D.ef[ v ] + Ds.ef[ v ] end

    atkR = (1 + atkR * 0.0001)
    immR = (1 + immR * 0.0001)

    local edmg = 0
    local idmg = 0
    local cdmg = 0
    if mode == 0 then
        edmg = A.ef.ExtraDmg0 + As.ef.ExtraDmg0
        idmg = D.ef.ImmuDmg0 + Ds.ef.ImmuDmg0
        cdmg = D.ef.CounterAttack0 + Ds.ef.CounterAttack0
    elseif mode == 1 then
        edmg = A.ef.ExtraDmg1 + As.ef.ExtraDmg1
        idmg = D.ef.ImmuDmg1 + Ds.ef.ImmuDmg1
        cdmg = D.ef.CounterAttack1 + Ds.ef.CounterAttack1
    end

    for _, a in pairs(A.objs) do
        if a.num > 0 then
            local atk = a.prop.Atk * atkR * a.num * rate
            for _, d in pairs(D.objs) do
                if d.num > 0 then
                    -- ############################ --
                    local dmg = atk * d.pow / D.pow
                    dmg = dmg * (1-d.prop.Imm * immR)
                    -- ############################ --
                    --print(string.format("amode=%d, dmode=%d, dmg=%f", amode, dmode, dmg))

                    if not a.hero and not d.hero then
                        dmg = dmg * math.pow(1.2, a.prop.Lv - d.prop.Lv)
                    end

                    if dmg < 0 then dmg = 0 end

                    local maxdmg = d.num * d.prop.Hp
                    if dmg > maxdmg then dmg = maxdmg end

                    if mode == 0 then a.mkdmg0 = (a.mkdmg0 or 0) + dmg
                    elseif mode == 1 then a.mkdmg1 = (a.mkdmg1 or 0) + dmg end

                    local rawdmg = dmg
                    a.mkdmg = (a.mkdmg or 0) + rawdmg

                    local delta = 0
                    if edmg > 0 then delta = delta + dmg * edmg * 0.0001 end
                    if idmg > 0 then delta = delta - dmg * idmg * 0.0001 end
                    if cdmg > 0 then a.dmg = a.dmg + dmg * cdmg * 0.0001 end
                    dmg = dmg + delta

                    if dmg < 0 then dmg = 0 end
                    if dmg > maxdmg then dmg = maxdmg end

                    d.dmg = (d.dmg or 0) + dmg
                    --LOG("_attack %d:%4.2f -> %d:%4.2f, dmg=%6.2f", a.id, a.num, d.id, d.num, dmg)

                    --return rawdmg
                end
            end
        end
    end
end

function _calc(As)
    local res = {0,0,0,0}
    local total = 0
    for mode = 1, 4, 1 do
        local lives = 0
        local A = As.arms[mode]
        if A and A.num > 0 then
            local dmgToHp0 = A.ef.DmgToHp0 + As.ef.DmgToHp0
            local dmgToHp1 = A.ef.DmgToHp1 + As.ef.DmgToHp1

            local hpR = A.ef.HpR + As.ef.HpR
            local hpDec = A.ef.HpDec + As.ef.HpDec

            for _, v in pairs(A.objs) do
                if v.num > 0 then
                    v.dmg = v.dmg or 0

                    if hpDec > 0 then v.dmg = v.dmg + v.num * v.prop.Hp * hpDec * 0.0001 end

                    local tohp = 0
                    if dmgToHp0 > 0 then tohp = tohp + (v.mkdmg0 or 0) * dmgToHp0 * 0.0001 end
                    if dmgToHp1 > 0 then tohp = tohp + (v.mkdmg1 or 0) * dmgToHp1 * 0.0001 end
                    v.dmg = v.dmg - tohp
                    if v.dmg < 0 then v.dmg = 0 end

                    -- ############################ --
                    local dead = v.dmg / (v.prop.Hp * (1 + hpR * 0.0001))
                    v.num = v.num - dead
                    -- ############################ --

                    --print(string.format("dmode=%d, total dmg=%f, dead=%f, v.num=%f", A.mode, v.dmg, dead, v.num))

                    if v.num < 0 then v.num = 0 end
                    v.dmg = 0
                    v.mkdmg = 0
                    v.mkdmg0 = 0
                    v.mkdmg1 = 0
                    --print("num:", v.num)
                end
                lives = lives + v.num
            end
            A.num = lives
            total = total + lives
        end
        res[mode] = math.ceil(lives)
    end
    return res, math.ceil(total)
end

local _fight_seqs = {
        [1] = {3,1,4,2},
        [2] = {1,2,4,3},
        [3] = {2,3,4,1},
        [4] = {4,1,2,3},
    }

-- A, D = arms
local function _round(A, D)
    for amode, a in pairs(A.arms) do
        if a.num > 0 then
            if a.mode == 4 then
                local rate = {0.05, 0.05, 0.05, 1}
                local sum = 0
                for dmode, d in pairs(D.arms) do
                    if d.num > 0 then sum = sum + d.pow * rate[ dmode ] end
                end

                for dmode, d in pairs(D.arms) do
                    if d.num > 0 then
                        local r = d.pow * rate[dmode] / sum
                        _attack(a, A, d, D, 0, r)
                    end
                end
            else
                local seq = _fight_seqs[ a.mode ]
                for _, dmode in ipairs(seq) do
                    local d = D.arms[ dmode ]
                    if d and d.num > 0 then
                        _attack(a, A, d, D, 0)
                        break
                    end
                end
            end
        end
    end
end

local function _tactics(As, Ds, round, report, who)
    local flag = false
    for amode, A in pairs(As.arms) do
        if A.num > 0 and amode ~= 4 then
            if not A.tacTm then A.tacTm = 0 end
            local ename = string.format("TacticsCd%d", A.mode)
            local cd = 10 + 10 * (A.ef[ename] + As.ef[ename])
            if round - A.tacTm >= cd then
                A.tacTm = round
                if A.ef.TacticsBlock + As.ef.TacticsBlock == 0 then
                    ename = string.format("TacticsAll%d", A.mode)

                    if _fight_seqs[ amode ][1] == A.hit or A.ef[ename] + As.ef[ename] > 0 then
                        local D = Ds.arms[ A.hit ]
                        _attack(A, As, D, Ds, 1, 1.5)
                        flag = true
                        table.insert(report, {round, 4, who, A.mode, "tactics"})

                        local more = A.ef.TacticsMore + As.ef.TacticsMore
                        if more > 0 then
                            for _, D in pairs(Ds.arms) do
                                if D.num > 0 and D.mode ~= A.hit then
                                    _attack(A, As, D, Ds, 1, 1.5 * (1 + more * 0.0001))
                                end
                            end
                        end
                        --todo, trig other
                    end
                end
            end
        end
    end
    return flag
end

function _get_num(A)
    local res = {0,0,0,0}
    for mode = 1,4,1 do
        local arm = A.arms[ mode ]
        if arm then res[mode] = math.ceil(arm.num) end
    end
    return res
end

local function _all_dead(T)
    for _, v in pairs(T.arms) do
        if v.num > 0 then return false end
    end
    return true
end

vfunc_cond = {}
vfunc_cond["AND"] = function (A, As, Ds, ...)  -- A obj, D obj, A arms, D arms
    for _, v in pairs({...}) do
        if not do_cond(A, As, Ds, unpack(v)) then return false end
    end
    return true
end

vfunc_cond["OR"] = function (A, As, Ds, ...)  -- A obj, D obj, A arms, D arms
    for _, v in pairs({...}) do
        if do_cond(A, As, Ds, unpack(v)) then return true end
    end
end

-- A, self,
-- A attck D, B attack A
vfunc_cond["AMODE"] = function (A, As, Ds, mode)
    if not A then return false end
    return A and A.mode == mode
end

vfunc_cond["DMODE"] = function (A, As, Ds, mode)
    if not A then return false end
    for _, v in pairs(A.as) do
        if v == mode then return true end
    end
end

vfunc_cond["BMODE"] = function (A, As, Ds, mode)
    if not A then return false end
    for _, v in pairs(A.ds) do
        if v == mode then return true end
    end
end


vfunc_cond["RATE"] = function (A, As, Ds, rate)
    return math.random(1,10000) < rate
end

function do_cond(A, As, Ds, Func, ...)
    if vfunc_cond[ Func ] then
       return vfunc_cond[ Func ](A, As, Ds, ...)
   else
       WARN("fight, do_cond, Func = %s", Func)
       return false
   end
end

function buff_check(buf, A, As, Ds)
    local cond = buf.cond
    if cond and #cond > 0 then
        return do_cond(A, As, Ds, unpack(cond))
    else
        return true
    end
end

function skill_check(skill, A, As, Ds)
    local cond = skill.cond
    if cond and #cond > 0 then
        return do_cond(A, As, Ds, unpack(cond))
    else
        return true
    end
end

function do_add_buf(tab, buf, count)
    --todo, buf mutex
    --INFO("BUF add, id=%d, count=%d", buf.ID, count)
    table.insert(tab, {buf,count})
end

-- A attack D; B attack A

vfunc_skill = {}
vfunc_skill[ "AddBuf" ] = function (Target, A, As, Ds, bufid, count)
    local buf = resmng.prop_buff[ bufid ]
    if buf then
        if Target == "A" then
            do_add_buf(A.buf, buf, count)

        elseif Target == "AS" then
            do_add_buf(As.buf, buf, count)

        elseif Target == "D" then
            for k, v in pairs(A.as) do
                local D = Ds.arms[ v ]
                if D then
                    do_add_buf(D.buf, buf, count)
                end
            end

        elseif Target == "DS" then
            do_add_buf(Ds.buf, buf, count)

        elseif Target == "B" then
            for k, v in pairs(A.ds) do
                local D = Ds.arms[ v ]
                if D then
                    do_add_buf(D.buf, buf, count)
                end
            end
        elseif Target == "BS" then
            do_add_buf(Ds.buf, buf, count)
        end
    end
end

function do_skill_fire(Target, A, As, Ds, Func, ...)
    if vfunc_skill[ Func ] then
        vfunc_skill[ Func ](Target, A, As, Ds, ...)
    end
end

function skill_fire(skill, A, As, Ds)
    local effect = skill.Effect
    if effect then
        for _, e in pairs(effect) do
            do_skill_fire(skill.Target or "A", A, As, Ds, unpack(e))
        end
    end
end

local function _launch_skills(As, Ds, round, report, who)
    for _, A in pairs(As.arms) do
        for _, obj in pairs(A.objs) do
            if obj.hero and obj.lead then
                for _, v in pairs(obj.skills) do
                    local skill = resmng.prop_skill[v]
                    if skill and skill_check(skill, A, As, Ds) then
                        skill_fire(skill, A, As, Ds)
                        table.insert(report, {round, 3, who, A.mode, obj.id, skill.ID, "skills"})
                    end
                end
            end
        end
    end
end

local function _launch_skill(As, Ds, round, report, who)
    for _, A in pairs(As.arms) do
        for _, obj in pairs(A.objs) do
            if obj.hero and obj.lead then
                local skill = resmng.prop_skill[obj.skill]
                if skill and skill_check(skill, A, As, Ds) then
                    skill_fire(skill, A, As, Ds)
                    table.insert(report, {round, 2, who, A.mode, obj.id, skill.ID, "skill"})
                end
            end
        end
    end
end

function do_buf_dec(bs)
    local ns = {}
    local chg = false
    for _, b in pairs(bs) do
        b[2] = b[2] - 1
        if b[2] > 0 then
            table.insert(ns, b)
        else
            chg = true
            --INFO("BUF, del, id=%d", b[1].ID)
        end
    end
    return ns, chg
end

local _mt_eff = { __index = function (tab, key) return 0 end }
function do_buf_recalc(bs, A, As, Ds)
    local es = {}
    for _, v in pairs(bs) do
        local b = v[1]
        if b then
            if buff_check(b, A, As, Ds) then
                for key, val in pairs(b.Value or {}) do
                    es[ key ] = (es[key] or 0) + val
                end
            end
        end
    end
    return setmetatable(es, _mt_eff)
end

function refresh_buf(As)
    As.buf, chg = do_buf_dec(As.buf or {})
    As.ef = do_buf_recalc(As.buf or {})
    for _, A in pairs(As.arms or {}) do
        A.buf = do_buf_dec(A.buf or {})
        A.ef = do_buf_recalc(A.buf or {})
    end
end


function get_hero(sn)
    local what = type(sn)
    if what == "table" then
        return sn
    elseif what == "string" then
        local idx, pid = string.match(sn, "(%d+)_(%d+)")
        local p = getPlayer(tonumber(pid))
        if p then
            return p:get_hero(tonumber(idx))
        end
    end
end


function init_troop(A) 
    local t = {num=0, arms={}}
    if troop_t.is_shell(A) then
        for idx, tid in ipairs(A.troops) do
            local tr = troop_t.get_by_tid(tid)
            if tr then
                add_troop_to(t, tr.arms, idx)
            end
        end
    else
        add_troop_to(t, A.arms, 1)
    end

    t.buf = {}
    local p = get_ply(A.aid)
    for _, am in pairs(gArgMatch) do
        for _, bm in pairs(am) do
            for _, n in pairs(bm) do
                for _, arg in pairs(n) do
                    if p then
                        --t[ arg ] = p:getProp(arg)
                        t[ arg ] = p:get_val(arg)
                    else
                        t[ arg ] = 0
                    end
                end
            end
        end
    end
    return t
end

function add_troop_to(t, arms, idx)
    if not t.heros then t.heros = {0,0,0,0} end
    for mode = 1, 4, 1 do
        local arm = arms[ mode ]
        if arm then
            --arm.buf = {}
            local node = t.arms[ mode ]
            if not node then
                node = {mode=mode, num=0, objs={}, buf={}}
                t.arms[ mode ] = node
            end
            for _, v in pairs(arm.objs) do
                if v.hero then
                    local h = heromng.get_fight_attr(v.hero)
                    if h then
                        h.link = v
                        v.Lv = h.prop.Lv
                        v.id = h.id
                        h.num0 = h.num
                        if idx == 1 then 
                            h.lead = 1 
                            t.heros[ mode ] = h.id
                        end
                        table.insert(node.objs, h)
                        node.num = node.num + h.num
                        t.num = t.num + h.num
                    end
                else
                    local prop = resmng.prop_arm[ v.id ]
                    if prop then
                        table.insert(node.objs, {id=v.id, num=v.num, num0=v.num, prop=prop, link=v})
                        node.num = node.num + v.num
                        t.num = t.num + v.num
                    end
                end
            end
        end
    end
end


function _match(As, Ds)
    for _, C in pairs({As, Ds}) do
        for mode, arm in pairs(C.arms) do
            arm.as = {}
            arm.ds = {}
        end
    end

    for amode, A in pairs(As.arms) do
        if A.num > 0 then
            local seq = _fight_seqs[ amode ]
            for _, dmode in pairs(seq) do
                local D = Ds.arms[ dmode ]
                if D and D.num > 0 then
                    table.insert(A.as, dmode)
                    table.insert(D.ds, amode)
                    if amode ~= 4 then break end
                end
            end
        end
    end

    for dmode, D in pairs(Ds.arms) do
        if D.num > 0 then
            local seq = _fight_seqs[ dmode ]
            for _, amode in pairs(seq) do
                local A = As.arms[ amode ]
                if A and  A.num > 0 then
                    table.insert(D.as, amode)
                    table.insert(A.ds, dmode)
                    if dmode ~= 4 then break end
                end
            end
        end
    end
end


fight.pvp = function(action, A0, D0)
    -- Bu,1; Qi,2; Gong,3; Che 4;
    local total = 0

    local A = init_troop(A0)
    local D = init_troop(D0)

    local report = {{0,0,A0.eid, A0.aid, A0.did, A.heros, D.heros }}
    table.insert(report, {0, 1, _get_num(A), _get_num(D) })

    for i = 1, 30, 1 do
        _match(A, D)
        if i == 1 then
            _launch_skills(A, D, i, report, 1)
            _launch_skills(D, A, i, report, 2)
        end

        if (i - 4) % 6 == 0 then
            _launch_skill(A, D, i, report, 1)
            _launch_skill(D, A, i, report, 2)
        end

        refresh_buf(A)
        refresh_buf(D)

        for _, C in pairs({A, D}) do
            for _, arm in pairs(C.arms) do
                local pow = 0
                for _, obj in pairs(arm.objs) do
                    if obj.num > 0 then
                        obj.pow = obj.num * obj.prop.Pow
                        pow = pow + obj.pow
                    end
                end
                arm.pow = pow
            end
        end

        _round(A, D)
        _round(D, A)

        _tactics(A, D, i, report, 1)
        _tactics(D, A, i, report, 2)

        local ta, la = _calc(A)
        local td, ld = _calc(D)
        table.insert(report, {i, 1, ta, td })

        if la == 0 or ld == 0 then break end
        --if _all_dead(A) or _all_dead(D) then break end
    end

    local losts = {-1,}
    for _, C in ipairs({A, D}) do
        local live = 0
        local lost = 0
        for _, arm in pairs(C.arms) do
            local total = 0
            for k, obj in pairs(arm.objs) do
                if not obj.hero then obj.num = math.ceil(obj.num) end

                lost = lost + obj.prop.Pow * (obj.num0 - obj.num)
                obj.deads = obj.num0 - obj.num
                if obj.num > 0 then
                    live = live + obj.num
                    total = total + obj.num
                end

                local n = obj.link
                if n then
                    n.num0 = n.num
                    n.num = obj.num
                else
                    dumpTab(C, "no link")
                end
            end
            arm.num = total
        end
        C.live = live
        C.lost = lost

        if C==A then 
            A0.live = live 
        else 
            D0.live = live 
        end
        table.insert(losts, lost)
    end
    table.insert(report, losts)

    local win = 0
    if losts[3] >= losts[2] then win = 1 else win = 2 end -- defence should be lose when lost same
    if _all_dead(A) ~= _all_dead(D) then
        if _all_dead(A) then win = 2 else win = 1 end
    end
    table.insert(report, {win=win})

    if win==1 then
        A0.win = 1
        D0.win = nil
    else
        A0.win = nil
        D0.win = 1
    end

    result(action, A0, D0, A, D)

    A = A0
    D = D0

    --todo, clean when live long enough

    local pid = 0
    local uid = 0
    local atker = get_ply(A.aid)
    if atker then
        pid = atker.pid
        uid = atker.uid
    end
    Rpc:around0(A.did, "battle", A.eid, A.aid, A.did, pid, uid)
    gFightReports[ A.eid ] = {gTime, report}

    --result(action, A, D)
    return report
end

function result(action, At, Dt, Ainfo, Dinfo)
    if func_result[action] then
        func_result[action](At, Dt, Ainfo, Dinfo)
    else
        local A = get_ety(At.aid)
        local D = get_ety(Dt.aid)
        A:troop_back(At)
        D:troop_home(Dt)
    end
end

function do_get_troop_statistic(At)
    local pid = 0
    local propid = 0
    local name = ""

    -- todo 
    local trans = 1
    if At.action == TroopAction.Seige then trans = 0 end

    if is_ply(At.aid) then
        local p = get_ply(At.aid)
        if p then
            pid = p.pid
            name = p.name
        end

    elseif is_monster(At.aid) then
        local m = get_ety(At.aid)
        if m then propid = m.propid end
    end

    local soldiers = {}
    local heros = {}

    for mode, arm in pairs(At.arms) do
        for _, obj in pairs(arm.objs) do
            if obj.hero then
                table.insert(heros, {obj.id, obj.Lv, obj.num})
            else
                local live = obj.num
                local dead = obj.num0 - obj.num
                local hurt = math.ceil(dead * trans)
                dead = dead - hurt
                obj.num = live
                obj.dead = (obj.dead or 0) + dead
                obj.hurt = (obj.hurt or 0) + hurt
                obj.num0 = nil
                table.insert(soldiers, {obj.id, obj.num, dead, hurt})
            end
        end
    end
    -- -- -- schema -- -- --
    return {pid, name, propid, soldiers, heros}
end


function get_troop_statistic(At)
    local infos = {}
    if troop_t.is_shell(At) then
        for k, v in pairs(At.troops) do
            local tr = troop_t.get_by_tid(v)
            if tr then
                local n = do_get_troop_statistic(tr)
                table.insert(infos, n)
            end
        end
    else
        local n = do_get_troop_statistic(At)
        table.insert(infos, n)
    end
    return infos
end

function get_troop_buf(At)
    local args = {
        "Atk_R", "Atk1_R", "Atk2_R", "Atk3_R", "Atk4_R",
        "Def_R", "Def1_R", "Def2_R", "Def3_R", "Def4_R",
        "Imm_R", "Imm1_R", "Imm2_R", "Imm3_R", "Imm4_R",
        "Hp_R", "Hp1_R", "Hp2_R", "Hp3_R", "Hp4_R",
        "MaxSoldier_A" 
    }
    local A = get_ply(At.aid)
    local buf = {}
    if A then
        for k, v in pairs(args) do
            local n = A:getProp(v) 
            --if n ~= 0 then
                buf[ v ] = (buf[ v ] or 0) + n
            --end
        end
    end
    return buf
end


func_result={}
func_result.seige = function(At, Dt, Ainfo, Dinfo)
    local ainfo = get_troop_statistic(At)
    local dinfo = get_troop_statistic(Dt)
    local abuf = get_troop_buf(At)
    local dbuf = get_troop_buf(Dt)
    local its = {}

    if At.win then
        table.insert(its, {1,1,10000})
        --todo, reward allocate
    else
        its = nil
    end

    local A = get_ety(At.aid)
    local D = get_ety(Dt.aid)

    local content = {x=D.x, y=D.y, A={x=A.x, y=A.y, info=ainfo, buf=abuf}, D={x=D.x, y=D.y, info=dinfo, buf=dbuf}, carry=its}
    local mail = {class=MAIL_CLASS.FIGHT, content=content}

    if troop_t.is_shell(At) then
        if At.win then mail.mode = MAIL_FIGHT_MODE.MASS_SUCCESS else mail.mode = MAIL_FIGHT_MODE.MASS_FAIL end
        for _, tid in pairs(At.troops) do
            local _, pid = string.match(tid, "(%d+)_(%d+)")
            local A = getPlayer(pid)
            if A then
                A:mail_new(mail)
                At.carry = its
            end
        end
    else
        if At.win then mail.mode = MAIL_FIGHT_MODE.ATTACK_SUCCESS else mail.mode = MAIL_FIGHT_MODE.ATTACK_FAIL end
        local A = get_ply(At.aid)
        if A then
            A:mail_new(mail)
            At.carry = its
        end
    end

    mail = copyTab(mail)

    if troop_t.is_shell(Dt) then
        if Dt.win then 
            mail.mode = MAIL_FIGHT_MODE.DEFEND_MASS_SUCCESS 
        else 
            mail.mode = MAIL_FIGHT_MODE.DEFEND_MASS_FAIL 
            D:release_all_prisoner()
        end
        for _, tid in pairs(Dt.troops) do
            local _, pid = string.match(tid, "(%d+)_(%d+)")
            local D = getPlayer(pid)
            if D then
                D:mail_new(mail)
            end
        end
    else
        if Dt.win then 
            mail.mode = MAIL_FIGHT_MODE.DEFEND_SUCCESS 
        else 
            mail.mode = MAIL_FIGHT_MODE.DEFEND_FAIL 
            D:mail_new(mail)
            D:release_all_prisoner()
        end
        local D = get_ply(Dt.aid)
        if D then
            D:mail_new(mail)
        end
    end

    -- Hx@2016-01-28: 战斗记录
    -- TODO: 更详细划分日志
    local Au = A:union()
    local Du = D:union()
    local log = {
        action = At.action,
        A = {
            pid = A.pid,
            name = A.name,
            win = At.win,
            x = At.sx,
            y = At.sy,
        },
        D = {
            pid = D.pid,
            name = D.name,
            win = Dt.win,
            x = At.dx,
            y = At.dy,
        }
    }
    if Au then Au:add_log(resmng.EVENT_TYPE.FIGHT, log) end
    if Du then Du:add_log(resmng.EVENT_TYPE.FIGHT, log) end

    -- capture hero
    if true or At.win then
        --if A:get_castle_lv() >= 10 and D:get_castle_lv() >= 10 then
        if true then
            local totala = 0
            local ahs = {}
            for mode, arm in pairs(Ainfo.arms) do
                for _, v in pairs(arm.objs) do
                    --if v.hero and v.lead == 1 and v.num > 0 then
                    if v.hero and v.lead == 1 then
                        local cr = get_val_by("Captive", A._ef, arm.ef)
                        totala = totala + cr
                        table.insert(ahs, {v.hero, cr})
                    end
                end
            end
            if totala > 0 then
                local dhs = {}
                for mode, arm in pairs(Dinfo.arms) do
                    for _, v in pairs(arm.objs) do
                        if v.hero and v.lead == 1 then
                        --if v.hero and v.lead == 1 and v.num > 0 then
                            local cr = get_val_by("CounterCaptive", D._ef, arm.ef)
                            local rm = 10000-v.num
                            if rm < 1 then rm = 1 end
                            table.insert(dhs, {v.hero, cr, v.num, rm})
                        end
                    end
                end

                if #dhs > 0 then

                    local ha = ahs[1]
                    local hd = dhs[1]

                    --local dhs1 = {}
                    --for _, v in pairs(dhs) do
                    --    if v[3] == 0 then table.insert(dhs1, v) end
                    --end
                    --if #dhs1 > 0 then dhs = dhs1 end

                    --local ra = math.random(1, totala)
                    --local r = 0
                    --local ha = false
                    --for k, v in pairs(ahs) do
                    --    r = r + v[2]
                    --    if ra <= r then
                    --        ha = v
                    --        break
                    --    end
                    --end

                    --local hd = false
                    --local totald = 0
                    --for k, v in pairs(dhs) do
                    --    totald = totald + v[4]
                    --end
                    --local rd = math.random(1, totald)
                    --r = 0
                    --for k, v in pairs(dhs) do
                    --    r = r + v[4]
                    --    if rd <= r then
                    --        hd = v
                    --        break
                    --    end
                    --end

                    if ha and hd then
                        local rate = math.random(1, 100000)
                        if true or rate < ha[2] - hd[2] then
                            heromng.capture(ha[1], hd[1])
                        end
                    end
                end
            end
        end
    end

    A:troop_back(At)
    D:troop_home(Dt)
end

func_result.jungle = function(At, Dt)
    local ainfo = get_troop_statistic(At)
    local dinfo = get_troop_statistic(Dt)

    local its = 0
    local title = ""
    if At.win then
        if Dt.live == 0 then its = {{2001003,10}}
        else its = {{2001003,1}} end
    end

    local D = get_ety(Dt.aid)
    local content = {propid=D.propid, x=D.x, y=D.y, A={x=At.sx, y=At.sy, info=ainfo}, D={x=At.dx, y=At.dy, info=dinfo}, carry=its}
    local mail = {class=MAIL_CLASS.REPORT, mode=MAIL_REPORT_MODE.JUNGLE, content=content}

    if troop_t.is_shell(At) then
        for _, tid in pairs(At.troops) do
            local _, pid = string.match(tid, "(%d+)_(%d+)")
            local A = getPlayer(pid)
            if A then
                A:mail_new(mail)
                if its ~= 0 then
                    for _, v in pairs(its) do A:inc_item(v[1], v[2], VALUE_CHANGE_REASON.JUNGLE) end
                end
            end
        end
    else
        local A = get_ply(At.aid)
        if A then
            A:mail_new(mail)
            if its ~= 0 then
                for _, v in pairs(its) do A:inc_item(v[1], v[2], VALUE_CHANGE_REASON.JUNGLE) end
            end
        end
    end
    local A = get_ety(At.aid)
   local D = get_ety(Dt.aid)

    A:troop_back(At)
    D:troop_home(Dt)
end

func_result.grab = function(At, Dt)
end


--function heromng.capture(_idA, _idD)
--function heromng.back_from_battle(_id, num)
--function heromng.go_to_battle(_id)
--funciton player_t.get_def_hero()  --return { hero_id, false, hero_id, hero_id }


