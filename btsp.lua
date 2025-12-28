local btsp = {}
btsp.__index__ = btsp
btsp.__updater__ = require("update")
btsp.can_continue = true
efunc = function() end
--[[
Apioframe CORE Bootstrap V0.0.1
- By Ktzukii ;3

2025/12/05 @ 00:49
]]

local function readFile(path)
    local file = fs.open(path, "r")
    if not file then return nil end
    local contents = file.readAll()
    file.close()
    return textutils.unserialiseJSON(contents)
end
local function writeFile(path, tbl)
    local json = textutils.serialiseJSON(tbl)
    local file = fs.open(path);file.write(json)
    file.close()
    return true
end
local function appendFile(path, tbl)
    local existing = readFile(path) or {}
    table.insert(existing, tbl)
    return writeFile(path, existing)
end

function btsp.finish_install()
    writeFile("bootstrap.__data__", {
        time = btsp.sha256(tostring(os.date()))
    })
end

function btsp.init(program,gituri)
    btsp.clog("Bootstrap is loading...", colors.green)
    os.sleep(0.1+math.random(-0.05,0.05))

    local ok, out = pcall(btsp.__updater__.update, btsp, gituri)
    if ok then
        btsp.clog("Update finished.", colors.green)
    else
        btsp.error("Update on bootstrap initialization failed.", tostring(out))
        return false
    end
    if not btsp.can_continue then return false end
    local pok, pout = xpcall(require, efunc, program)
    print(pok)
    print(pout)
end

function btsp.error(name, detail)
    local pc = term.getTextColor()
    term.setTextColor(colors.red)
    print("A error was called!\n\nOverview:\n"..tostring(name)
        .."\n\nDetail:\n"..tostring(detail))
    btsp.can_continue = false
end

function btsp.warn(s)
    local pc = term.getTextColor()
    term.setTextColor(colors.yellow)
    print("[WARN] "..tostring(s))
    term.setTextColor(pc)
end

function btsp.clog(s,c)
    local pc = term.getTextColor()
    term.setTextColor(c)
    print("[LOG] "..tostring(s))
    term.setTextColor(pc)
end

function btsp.sha256(s)
    local function rshift(x,n) return math.floor(x/2^n) end
    local function lshift(x,n) return (x*2^n) % 2^32 end
    local function band(a,b)
        local r,p=0,1
        while a>0 or b>0 do
            local A=a%2 B=b%2
            if A==1 and B==1 then r=r+p end
            a=(a-A)/2 b=(b-B)/2 p=p*2
        end
        return r
    end
    local function bxor(a,b)
        local r,p=0,1
        while a>0 or b>0 do
            local A=a%2 B=b%2
            if A~=B then r=r+p end
            a=(a-A)/2 b=(b-B)/2 p=p*2
        end
        return r
    end
    local function bor(a,b)
        local r,p=0,1
        while a>0 or b>0 do
            local A=a%2 B=b%2
            if A==1 or B==1 then r=r+p end
            a=(a-A)/2 b=(b-B)/2 p=p*2
        end
        return r
    end
    local function rrot(x,n) return bor(rshift(x,n), lshift(x,32-n)) end

    local K={
        0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
        0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
        0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
        0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
        0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
        0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
        0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
        0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
    };local H={
        0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,
        0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19
    }

    local bytes={s:byte(1,#s)}
    local bitlen=#bytes*8
    bytes[#bytes+1]=0x80
    while (#bytes%64)~=56 do bytes[#bytes+1]=0 end
    for i=7,0,-1 do bytes[#bytes+1]=rshift(bitlen,8*i)%256 end

    for i=1,#bytes,64 do
        local w={}
        for j=0,15 do
            local idx=i+j*4
            w[j+1]=lshift(bytes[idx],24)+lshift(bytes[idx+1],16)+lshift(bytes[idx+2],8)+bytes[idx+3]
        end
        for j=17,64 do
            local s0=bxor(rrot(w[j-15],7), bxor(rrot(w[j-15],18), rshift(w[j-15],3)))
            local s1=bxor(rrot(w[j-2],17), bxor(rrot(w[j-2],19), rshift(w[j-2],10)))
            w[j]=(w[j-16]+s0+w[j-7]+s1)%2^32
        end

        local a,b,c,d,e,f,g,h=table.unpack(H)
        for j=1,64 do
            local S1=bxor(rrot(e,6), bxor(rrot(e,11), rrot(e,25)))
            local ch=bxor(band(e,f), band((2^32-1-e)%2^32,g))
            local t1=(h+S1+ch+K[j]+w[j])%2^32
            local S0=bxor(rrot(a,2), bxor(rrot(a,13), rrot(a,22)))
            local maj=bxor(band(a,b), bxor(band(a,c), band(b,c)))
            local t2=(S0+maj)%2^32
            h=g g=f f=e e=(d+t1)%2^32 d=c c=b b=a a=(t1+t2)%2^32
        end
        H[1]=(H[1]+a)%2^32 H[2]=(H[2]+b)%2^32 H[3]=(H[3]+c)%2^32 H[4]=(H[4]+d)%2^32
        H[5]=(H[5]+e)%2^32 H[6]=(H[6]+f)%2^32 H[7]=(H[7]+g)%2^32 H[8]=(H[8]+h)%2^32
    end

    local out=""
    for i=1,8 do out=out..string.format("%08x",H[i]) end
    return out
end

return btsp