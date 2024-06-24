-- load comment libs
local require = require

-- local function
local ngx            = ngx
local ngx_hmac_sha1  = ngx.hmac_sha1
local ngx_time       = ngx.time
local gsub           = ngx.re.gsub
local bit_band       = bit.band
local bit_lshift     = bit.lshift
local bit_rshift     = bit.rshift
local math_floor     = math.floor
local math_random    = math.random
local string_char    = string.char
local string_format  = string.format
local string_reverse = string.reverse
local table_concat   = table.concat
local table_insert   = table.insert
-- Use the optimized `unpack` function from LuaJIT's FFI library
local ffi = require("ffi")
local base_encoding = require("resty.base_encoding")

-- module define
local _M = {
    _VERSION = '0.03.01',
}

local function totp_time_calc(ngx_time)
    local time_str = ffi.new("uint8_t[8]")
    for i = 7, 0, -1 do
        time_str[i] = bit_band(ngx_time, 0xFF)
        ngx_time = bit_rshift(ngx_time, 8)
    end
    return ffi.string(time_str, 8)
end

local function totp_new_key()
    local tmp_k = {} -- Use a table to store bytes
    math.randomseed(ngx_time())
    for i = 1, 10 do
        table_insert(tmp_k, string_char(math_random(0, 255)))
    end
    -- Concatenate the bytes efficiently with table.concat
    return base_encoding.encode_base32(table_concat(tmp_k))
end

------ TOTP functions ------
local TOTP_MT = {}

function _M.totp_init(secret_key)
    local m = {
        type = "totp",
    }
    setmetatable(m, { __index = TOTP_MT, __tostring = TOTP_MT.serialize })
    m:new_key(secret_key)
    return m
end

function TOTP_MT:new_key(secret_key)
    self.key = secret_key or totp_new_key()
    self.key_decoded = base_encoding.decode_base32(self.key)
end

function TOTP_MT:calc_token(var_time)
    local ngx_time = math_floor(var_time / 30)
    local hmac_result = ngx_hmac_sha1(self.key_decoded, totp_time_calc(ngx_time))
    
    local HMAC_offset = bit_band(hmac_result:byte(20), 0xF) 
    local TOTP_token = 0
    for i = 1, 4 do
        TOTP_token = TOTP_token + bit_lshift(hmac_result:byte(HMAC_offset + i), (4 - i) * 8)
    end

    TOTP_token = bit_band(TOTP_token, 0x7FFFFFFF)
    TOTP_token = TOTP_token % 1000000
    return string_format("%06d", TOTP_token)
end

function TOTP_MT:verify_token(token)
    return (token == self:calc_token(ngx_time()))
end

function TOTP_MT:get_url(issuer, account)
    return table_concat{
        "otpauth://totp/",
        account,
        "?secret=", self.key,
        "&issuer=", issuer,
    }
end

function TOTP_MT:serialize()
    return table_concat{
        "type:totp\n",
        "secret:", self.key,
        "secret_decoded", self.key_decoded,
    }
end

------ HOTP functions ------
local HOTP_MT = {}

function _M.hotp_init(secret_key)
    local m = {
        type = "hotp",
        counter = 0,
    }
    setmetatable(m, { __index = HOTP_MT, __tostring = HOTP_MT.serialize })
    m:new_key(secret_key)
    return m
end

function HOTP_MT:new_key(secret_key)
    self.key = secret_key or totp_new_key()
    self.key_decoded = base_encoding.decode_base32(self.key)
end

function HOTP_MT:calc_token(counter)
    local counter_str = ffi.new("uint8_t[8]")
    for i = 7, 0, -1 do
        counter_str[i] = bit_band(counter, 0xFF)
        counter = bit_rshift(counter, 8)
    end
    local hmac_result = ngx_hmac_sha1(self.key_decoded, ffi.string(counter_str, 8))
    
    local HMAC_offset = bit_band(hmac_result:byte(20), 0xF) 
    local HOTP_token = 0
    for i = 1, 4 do
        HOTP_token = HOTP_token + bit_lshift(hmac_result:byte(HMAC_offset + i), (4 - i) * 8)
    end

    HOTP_token = bit_band(HOTP_token, 0x7FFFFFFF)
    HOTP_token = HOTP_token % 1000000
    return string_format("%06d", HOTP_token)
end

function HOTP_MT:verify_token(token)
    local current_token = self:calc_token(self.counter)
    if token == current_token then
        self.counter = self.counter + 1
        return true
    end
    return false
end

function HOTP_MT:get_url(issuer, account)
    return table_concat{
        "otpauth://hotp/",
        account,
        "?secret=", self.key,
        "&issuer=", issuer,
        "&counter=", self.counter,
    }
end

function HOTP_MT:serialize()
    return table_concat{
        "type:hotp\n",
        "secret:", self.key,
        "secret_decoded", self.key_decoded,
        "counter:", self.counter,
    }
end

return _M
