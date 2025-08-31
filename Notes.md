## Nixification
- [x] build
- [x] * generate compile_commands.json
    - [ ] generate it as a separate item?
        But how? currently mini_compile_commands is woven into the package, not a package itself

## Dev enironment
- I am _not_ going to use VSCode
    - Neovim all the way
- [x] devshell
    - 20250830 devshell does work, but...
        - despite using a compile_commands.json, (clangd) LSP can't find `<irrTypes.h>`
            - and it's not supposed to use the system-installed version, luanti has a `irr/` directory!
                How do I redirect a `#include <>`
                - figure out more complicated `.clangd` file
            - adding nixpkgs.irrlicht to the shell does not solve this problem
        - you have to actually build to generate compile_commands.json

## The harder part once dev environment is set up
- Modernize C++ usage?
    - Possibly, if something big comes up
- Make a proxy class for multi-world game
    - Instead of every server and client knowing about an extra world coordinate, isolate this feature and state to just the proxy
        - Clients/servers/mods can remain vanilla
            - That's a lot of work to avoid
    - (siwwy voice) But I wanna wun dis on my iwwy biwwy wazbewwy pi
        - you should pick hardware to match the workload
        - I don't fucking care
    - The proxy is going to have to, to some degree, control the servers
        - it would be best if the servers didn't have to be local to the proxy
        - Merely multi-threading isn't going to quite cut it, need a little more isolation.
            - spawned processes and ...?
                - mod channels? It's built-in at this point
                    - can it be a always-on control channel proxy<->server?
                    - there currently has to be a client-server connection
                        - could get around this be making a (preferably hidden) super-admin SYSTEM account
                - control sockets? that deviates from vanilla servers
                - Some form of pub-sub hub, IRC may fit the bit
                    - keep it textual?
                    - there's already a IRC server mod
            - some worlds are going to be lairs, which will be a procedural layer beyond the overworld
            - pocket worlds will be a bonus
        - Isolation leads to a separate problem of synchronizing user data on world transition
            -
