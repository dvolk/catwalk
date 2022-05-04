# Package

version       = "0.1.0"
author        = "Denis Volk"
description   = "Cat walk"
license       = "AGPL"
srcDir        = "src"
bin           = @["cw_server", "cw_client", "cw_webui"]


# Dependencies

requires "nim >= 1.0.0"
requires "jester >= 0.4.3"
requires "cligen >= 0.9.38"
requires "jsony"
