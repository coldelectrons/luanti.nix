## Nixification
- [x] build
## Dev enironment
- I am _not_ going to use VSCode
    - Neovim all the way
- [ ] devshell
    - [x] * generate compile_commands.json
        - This can be done interactively in the devshell via cmake
        - There doesn't seem to be a good, working automated method
            - I've tried both `mini_compile_commands` and `compileCommandsFor`
                - mini_compile_commands isn't working properly
                    - produces cc.json, but paths are to /build/uuid instead of /nix/store/uuid
                - switch to compileCommandsFor
                    - success! mostly
                    - now I just have issues of finding `config.h` which should be in "src/"
                    - may also have issue of finding "cmake_config.h"
                    - compileCommandsFor makes a bunch of '-I/build/xxx' flags for the project source
                        - forked and added sed command to change them to '-I/nix/store/xxx'

## Things I already hate
- Preprocessor #if.then.else with #include files
- cmake
    - multiple layers hiding cmake on nixos
        - luanti uses a 'cmake_config.h.in', but this is hidden away in the store
        - there should be a way to not just link 'result' into the flake, but also 'build'
- luanti is stuck around C++14, it seems
    - upgrade to C++17/20/23, if it's not going to create net protocol problems
        - that's a crapton of faffing about I've just given myself

## The harder part once dev environment is set up
- Make a multiplexor proxy for multi-world gameplay
    - Instead of every server and client knowing about an extra world coordinate, isolate this feature and state to just the multiplexor proxy
        - Clients/servers/mods can remain vanilla
            - That's a lot of work to avoid

The mux should be almost like a server, with alot of stuff removed.
The mux should handle login/auth, but not produce any content
The server list should be dynamic, built off of IRC messaging

Can the client handle the raw packet stream being multiplexed between servers?
The client may not have provisions to restart the login sequence.
The client should be able to pull content at any time - TODO check this.
