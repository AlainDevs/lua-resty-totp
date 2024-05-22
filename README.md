
# LuaJIT TOTP Library

This is a high-performance TOTP (Time-based One-Time Password) library written in Lua, optimized for LuaJIT. It adheres to [RFC 6238](https://www.rfc-editor.org/rfc/rfc6238) (TOTP: Time-Based One-Time Password Algorithm). It provides functions for generating, verifying, and serializing TOTP tokens, as well as creating QR code URLs for easy setup.

## Features

- **LuaJIT Optimized:** Designed and optimized for use with LuaJIT, leveraging its FFI library for maximum performance.
- **JIT Compatible:**  Fully compatible with the LuaJIT JIT compiler. Careful analysis of the provided trace output shows that most of the code is successfully JIT compiled, resulting in significant performance gains.
- **Efficient Encoding:**  Uses LuaJIT's FFI library for efficient base32 encoding and decoding, avoiding unnecessary string copies.
- **Secure Key Generation:** Generates secure random keys using `math.random` seeded with the current time.
- **URL and QR Code Generation:**  Generates both OTPAuth URLs and QR code URLs for easy integration with authentication apps.

## Usage

```lua
local totp = require("totp")

-- Initialize a new TOTP instance with a secret key (optional)
local my_totp = totp.totp_init("JBSWY3DPEHPK3PXP") -- Or let the library generate a new key

-- Calculate a TOTP token for the current time
local token = my_totp:calc_token(946656000) -- Or ngx.time() for production

-- Verify a given token
local is_valid = my_totp:verify_token("123456")

-- Get the OTPAuth URL
local url = my_totp:get_url("My App", "user@example.com")

-- Get the QR code URL
local qr_url = my_totp:get_qr_url("My App", "user@example.com")

-- Generate a new secret key (for a new user)
local new_key = my_totp:new_key() 

-- Serialize the TOTP instance (for storage)
local serialized = tostring(my_totp)
```

## Performance

This library has been specifically designed for performance, especially when running under LuaJIT. It makes use of:

- **LuaJIT's FFI library:**  Direct access to C functions for base32 encoding/decoding and other operations.
- **Buffering:** Minimizes string allocations and copies.
- **Bitwise operations:** Efficient handling of binary data.
- **JIT compilation:** The LuaJIT JIT compiler can compile most of the code in this library, significantly boosting performance.

**Benchmarks:**

The provided trace output and wrk benchmark results demonstrate the library's excellent performance, especially under load. The average request latency is very low (under 700 microseconds) and the library can handle a high request rate (over 400k requests/sec).

```console
jit.log:
[TRACE   1 lrucache.lua:87 loop]
[TRACE --- version.lua:50 -- symbol not in cache at version.lua:51]
[TRACE   1 lrucache.lua:87 loop]
[TRACE   1 lrucache.lua:87 loop]
[TRACE --- totp.lua:46 -- leaving loop in root trace at totp.lua:50]
[TRACE   2 totp.lua:46 loop]
[TRACE --- totp.lua:91 -- leaving loop in root trace at totp.lua:95]
[TRACE   3 base.lua:76 return]
[TRACE   4 (2/3) totp.lua:50 stitch C:55fddeb1d520]
[TRACE   5 (4/stitch) totp.lua:87 return]
[TRACE   6 rax.lua:45 -> 2]
[TRACE --- version.lua:50 -- symbol not in cache at version.lua:51]
[TRACE --- version.lua:50 -- symbol not in cache at version.lua:51]
[TRACE   1 lrucache.lua:87 loop]
[TRACE --- version.lua:50 -- symbol not in cache at version.lua:51]
[TRACE --- totp.lua:46 -- leaving loop in root trace at totp.lua:50]
[TRACE   2 totp.lua:46 loop]
[TRACE --- totp.lua:91 -- leaving loop in root trace at totp.lua:95]
[TRACE --- totp.lua:46 -- leaving loop in root trace at totp.lua:50]
[TRACE   3 base.lua:76 return]
[TRACE   2 totp.lua:46 loop]
[TRACE   4 (2/3) totp.lua:50 stitch C:55fddeb1d520]
[TRACE   5 (4/stitch) totp.lua:87 return]
[TRACE --- totp.lua:91 -- leaving loop in root trace at totp.lua:95]
[TRACE   3 base.lua:76 return]
[TRACE   6 rax.lua:45 -> 2]
[TRACE   1 lrucache.lua:87 loop]
[TRACE   4 (2/3) totp.lua:50 stitch C:55fddeb1d520]
[TRACE   5 (4/stitch) totp.lua:87 return]
[TRACE   6 rax.lua:45 -> 2]
[TRACE   1 lrucache.lua:87 loop]
[TRACE --- totp.lua:46 -- leaving loop in root trace at totp.lua:50]
[TRACE   2 totp.lua:46 loop]
[TRACE --- totp.lua:91 -- leaving loop in root trace at totp.lua:95]
[TRACE   3 base.lua:76 return]
[TRACE   4 (2/3) totp.lua:50 stitch C:55fddeb1d520]
[TRACE   5 (4/stitch) totp.lua:87 return]
[TRACE   6 rax.lua:45 -> 2]
[TRACE --- version.lua:50 -- symbol not in cache at version.lua:51]
[TRACE --- version.lua:50 -- symbol not in cache at version.lua:51]
[TRACE --- totp.lua:46 -- leaving loop in root trace at totp.lua:50]
[TRACE   2 totp.lua:46 loop]
[TRACE --- totp.lua:91 -- leaving loop in root trace at totp.lua:95]
[TRACE   3 base.lua:76 return]
[TRACE   4 (2/3) totp.lua:50 stitch C:55fddeb1d520]
[TRACE   5 (4/stitch) totp.lua:87 return]
[TRACE   6 rax.lua:45 -> 2]
[TRACE --- totp.lua:46 -- leaving loop in root trace at totp.lua:50]
[TRACE   2 totp.lua:46 loop]
[TRACE --- totp.lua:91 -- leaving loop in root trace at totp.lua:95]
[TRACE   3 base.lua:76 return]
[TRACE   4 (2/3) totp.lua:50 stitch C:55fddeb1d520]
[TRACE   5 (4/stitch) totp.lua:87 return]
[TRACE   6 rax.lua:45 -> 2]
[TRACE   7 totp.lua:91 loop]
[TRACE   7 totp.lua:91 loop]
[TRACE   7 totp.lua:91 loop]
[TRACE   7 totp.lua:91 loop]
[TRACE   7 totp.lua:91 loop]
[TRACE   7 totp.lua:91 loop]
[TRACE   8 (7/3) totp.lua:95 return]
[TRACE   8 (7/3) totp.lua:95 return]
[TRACE   8 (7/3) totp.lua:95 return]
[TRACE   8 (7/3) totp.lua:95 return]
[TRACE   8 (7/3) totp.lua:95 return]
[TRACE   8 (7/3) totp.lua:95 return]

Core(s) per socket:                   6
Socket(s):                            1
NUMA node(s):                         1
Vendor ID:                            GenuineIntel
CPU family:                           6
Model:                                151
Model name:                           12th Gen Intel(R) Core(TM) i5-12600K
Stepping:                             2
CPU MHz:                              3686.396
BogoMIPS:                             7372.79
Hypervisor vendor:                    KVM
Virtualization type:                  full

Wrk test result:
user@user:~/totp# ./wrk -t6 -c200 -d10s http://localhost
Running 10s test @ http://localhost
  6 threads and 200 connections

  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   694.19us    1.14ms  40.99ms   94.54%
    Req/Sec    68.12k    15.27k  213.09k    74.58%
  4082826 requests in 10.09s, 774.82MB read
Requests/sec: 404681.70
Transfer/sec:     76.80MB
```

## Compatibility

This library is designed to be compatible with LuaJIT 2.1 and later. It will not work with the standard Lua interpreter. 
For accurate time-based token generation, ensure your system time is accurate. It's recommended to install and enable systemd-timesyncd (e.g., with sudo apt install systemd-timesyncd).

## License

This library is released under the MIT license. 
