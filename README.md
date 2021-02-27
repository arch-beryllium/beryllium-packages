# beryllium-packages

This repo holds the scripts to build the custom packages required for the device or any of the UIs.  
It only works on Arch based systems, because it uses a lot of the tools.

You can also use this to compile any package for the device (or aarch64 in general).  
You should try using `cross_compile_package.sh` before `host_compile_package.sh`, because it is much faster, but it
might not work.  
Especially cmake projects don't seem to work, but you should still give it a try.

First setup this repo using `./setup.sh`. In order to compile a package go into the directory of the package and
run `/path/to/this/repo/{cross,host}_compile_package.sh`.