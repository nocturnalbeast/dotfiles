# dmenu all-in-one patch

This folder contains a patch that is a combination of the following patches:

 * [case-insensitive](https://tools.suckless.org/dmenu/patches/case-insensitive)
 * [fuzzyhighlight](https://tools.suckless.org/dmenu/patches/fuzzyhighlight)
 * [fuzzymatch](https://tools.suckless.org/dmenu/patches/fuzzymatch)
 * [grid](https://tools.suckless.org/dmenu/patches/grid)
 * [line-height](https://tools.suckless.org/dmenu/patches/line-height)
 * [mouse-support](https://tools.suckless.org/dmenu/patches/mouse-support)
 * [xresources](https://tools.suckless.org/dmenu/patches/xresources)
 * [xyw](https://tools.suckless.org/dmenu/patches/xyw)
 * alpha (based on [dwm's alpha patch](https://dwm.suckless.org/patches/alpha))

## Usage

Run the command:

```
suckless-install dmenu
```

If the `suckless-install` script is present in `$PATH` (which it should be, assuming the dotfiles are installed), this will automatically download, patch and install dmenu.

Alternatively, this is also possible manually using the regular method of downloading the source code and patching manually.
