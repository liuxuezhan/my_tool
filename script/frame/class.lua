function mkcall( module )
    local mt = {}
    mt.__index = _G
    mt.__call = function(func, ...) return func.new(...) end
    setmetatable( module, mt )
end

function singleton( module )
	module.mt = module.mt or {__index=module}
	module.new = function()
		local ins = {}
		setmetatable(ins, module.mt)
		if ins.init then ins:init() end
		return ins
	end
	module.getInstance = function()
		local ins = rawget(module, "instance_")
		if not ins then
			ins = module.new()
			rawset(module, "instance_", ins)
		end
		return ins
	end

	local mt = {}
	mt.__index = _G
	mt.__call = function(func)
		return func.getInstance()
	end
	setmetatable( module, mt )
end

function deriveClass( child, parent )
	child.mt = child.mt or {__index=child}
	child.new = function(...)
		local ins = {}
		setmetatable(ins, child.mt)
		if ins.init then ins:init(...) end
		return ins
	end

	local mt = {}
	mt.__index = parent or _G
	mt.__call = function(func, ...) return func.new(...) end
	setmetatable( child, mt )
end

function singletonClass( child, parent )
	child.mt = child.mt or {__index=child}
	child.new = function()
		local ins = {}
		setmetatable(ins, child.mt)
		if ins.init then ins:init() end
		return ins
	end
	child.getInstance = function()
		local ins = rawget(child, "instance_")
		if not ins then
			ins = child.new()
			rawset(child, "instance_", ins)
		end
		return ins
	end

	local mt = {}
	mt.__index = parent or _G
	mt.__call = function(func)
		return func.getInstance()
	end
	setmetatable( child, mt )
end

-- --.-----------------------------------------------------------------------.--
-- Hx@2016-03-09: module based class
-- 需要注意加载顺序，基类先加载
function create_module_class(name, base)
    module(name, package.seeall)
    if base then setmetatable(_ENV, {__index=base}) end
    setfenv(2, getfenv(1))   

    _example = {}
    for k, v in pairs((base and base._example) or {}) do
        _example[k] = _example[k] or v
    end

    local meta = {
        __index = function(t, k)
            if _example[k] then 
                t._pro[k] = (type(_example[k]) ~= "table" and _example[k]) or copyTab(_example[k]) 
            end
            return t._pro[k] or _ENV[k] or (base and base[k]) or rawget(t, k)
        end,
        __newindex = function(t, k, v)
            if not _example[k] then return rawset(t, k, v) end
            if not check_pending then return end
            if not _cache[t._id] then _cache[t._id] = {} end
            t._pro[k] = v
            _cache[t._id][k] = v
            _cache[t._id]._n_ = nil
        end
    }
    
    function new(t)
        local self = {_pro=t or {}}
        setmetatable(self, meta)
        self:init()
        return self
    end

    function init(self)
        print("[ModuleClass] init!!!")
    end

    function delete(self)
        print("[ModuleClass] delete!!!")
    end
end

function attach_check_pending(example)
    setfenv(1, getfenv(2))   

    for k, v in pairs(example or {}) do
        _example[k] = _example[k] or v
    end
    assert(_example._id, "[ModuleClass] _id!!!")

    _cache = {}
    _ack_frame = 0

    function check_pending()
        --TODO
        local db = dbmng:tryOne()
        if not db then return end
        --assert(db, "get db FAILED")
        local dels = {}
        local hit = false
        for _id, chgs in pairs(_cache) do
            if chgs._n_ then
                if chgs._n_ <= _ack_frame then
                    table.insert(dels, _id)
                end
            else
                on_check_pending(db, _id, chgs)
                hit = true
                chgs._n_ = gFrame
            end
        end
        for _, v in pairs(dels) do
            _cache[v] = nil
        end
        if hit then get_db_checker(db, gFrame)() end
        on_check_pending()
    end

    function on_check_pending(db, _id, chgs)
        print("[ModuleClass] on_check_pending!!!")
    end

    function get_db_checker(db, frame)
        local f = function( )
            local info = db:runCommand("getPrevError")
            dumpTab(info)
            if frame > _ack_frame then
                _ack_frame = frame
            end
        end
        return coroutine.wrap(f)
    end
end
-- --'-----------------------------------------------------------------------'--

