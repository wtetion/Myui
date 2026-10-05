# CascadeStyleUI — executor version

This package keeps the System Settings UI and its Cascade v1.4.0 components,
but runs through an executor `loadstring` flow. It does not need a Roblox Studio
`LocalScript`, `ModuleScript`, `ReplicatedStorage`, `script.Parent`, or
`require`.

## Files

- `Ui-library.luau` — reusable library. It returns the UI API and loads the
  pinned Cascade v1.4.0 release when `CreateSystemSettings` is called.
- `Example.executor.luau` — runner that loads the library, creates the window,
  and shows the tab icons and example controls.

## Run it

1. Put both files in the executor workspace, keeping the library named
   `Ui-library.luau`.
2. Run `Example.executor.luau` in the executor.

The example reads the library with the executor's `readfile` function. To load
it remotely instead, set `LIBRARY_URL` at the top of the example to the public
raw URL for `Ui-library.luau`; the example then compiles it with `loadstring`.
The library fetches Cascade v1.4.0, compiles it, and creates the complete UI.

## Use it from another runner

```luau
local LIBRARY_URL = "https://raw.githubusercontent.com/USER/REPO/main/Ui-library.luau"
local UI = loadstring(game:HttpGet(LIBRARY_URL))()
local app, handles = UI.CreateSystemSettings()
```

To use a custom Sign In badge image, pass an image asset ID:

```luau
local app, handles = UI.CreateSystemSettings({
    SignInLogo = "rbxassetid://1234567890",
})
```

Leave out `SignInLogo` to keep the Apple logo badge from the reference UI, or
set `SignInLogo = false` to hide the badge. The Sign In page is visual only and
does not request or store account credentials.

## UI included

The library preserves the Settings layout: Sign In, Software Update, colored
tab icons, sidebar search, Appearance previews, theme/accent controls,
Connectivity, System, Privacy & Security, and Farm Settings. The example
callbacks only print their values; connect them to your own permitted game
logic.

The Cascade source is loaded from its pinned official v1.4.0 release. The
official project is MIT-licensed: https://github.com/cascadeui/Cascade
