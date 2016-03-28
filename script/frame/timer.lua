module("timer", package.seeall)
_sns = _sns or {}
_funs = _funs or {}

function newTimer(node)
    addTimer(node._id, (node.over-gTime)*1000, node.tag or 0)
end

function get(id)
    return _sns[ id ]
end

function mark(node)
    local db = dbmng:getOne(node._id)
    db.timer:update({_id=node._id}, node, true)
end

function new(what, sec, ...)
    if sec >= 1 and _funs[ what ] then
        local id = false
        while true do
            local sn = getSn("timer")
            if not timer.get(sn) then
                id = sn
                break
            end
        end

        local node = {_id=id, tag=0, start=gTime, over=gTime+sec, what=what, param={...}}
        _sns[ id ] = node
        newTimer(node)
        mark(node)
        return id, node
    end
end

function cycle(what, sec, cycle, ...)
    if sec >= 1 and cycle >= 1 then
        local id, node = new(what, sec, ...)
        if id then
            node.cycle = cycle
            mark(node)
        end
    end
end

function del(id)
    local node = _sns[id]
    if node then
        _sns[ id ] = {_id=id, tag=node.tag, invalid=1}
    end
    local db = dbmng:getOne(id)
    db.timer:delete({_id=id})
end

function acc(id, sec)
    local node = get(id)
    if node then
        node.over = node.over - sec
        node.tag = (node.tag or 0) + 1
        newTimer(node)
        mark(node)
    end
end

function callback(id, tag)
    local t = get(id)
    if t and t.tag == tag then
        _sns[id] = nil
        if t.invalid then return end

        local db = dbmng:getOne(id)
        db.timer:delete({_id=id})

        local fun = _funs[ t.what ]
        LOG("_timer_,  do, %s, %d, over:%s ", t.what, gTime, os.date("%y-%m-%d %H:%M:%S", t.over))
        if fun then
            local rt =  fun(id, unpack(t.param))
            if rt == 1 and t.cycle then
                t.start = gTime
                t.over = t.over + t.cycle
                t.tag = t.tag + 1
                _sns[ id ] = t
                timer.newTimer(t)
                db.timer:update({_id=id}, t, true)
            end
        end
    end
end

