{ terminal, color, font }:

{ config, lib, pkgs, ... }:

let
  withMessengers = fn:
    lib.strings.concatImapStrings (i: x: let si = toString i; in fn si x) config.home.local.messengers;

  xmonadHs = ''
    import XMonad
    import XMonad.Hooks.PerWindowKbdLayout
    import XMonad.Hooks.DynamicBars
    import XMonad.Hooks.DynamicLog
    import XMonad.Hooks.ManageDocks
    import XMonad.Hooks.EwmhDesktops
    import XMonad.Hooks.ManageHelpers
    import XMonad.Hooks.SetWMName
    import XMonad.Hooks.Rescreen
    import XMonad.Layout.CenteredIfSingle
    import XMonad.Layout.NoBorders
    import XMonad.Layout.IfMax
    import XMonad.Layout.ThreeColumns
    import XMonad.Layout.PerWorkspace
    import XMonad.Layout.PerScreen
    import XMonad.Layout.Spacing
    import XMonad.Layout.Gaps
    import XMonad.Layout.Tabbed
    import XMonad.Util.Run
    import XMonad.Util.NamedScratchpad
    import XMonad.Actions.FocusNth
    import Data.List (isInfixOf)
    import System.Exit
    import qualified XMonad.StackSet as W
    import qualified Data.Map        as M

    myModMask = mod4Mask

    myWorkspaces    = ["term","dev","web","web2","misc","misc2","media","chat","mail","0"]

    myScratchPads = [ NS "keepassxc" "keepassxc" findKeepass manage
                    , NS "yubioath" "yubioath-flutter" findYubioath manage
                    , NS "terminal" "${terminal} start --always-new-process --class scratchterm" findTerminal manageTerminal
${withMessengers
  (idx: m: "                    , NS \"messenger${idx}\" \"${m.exe}\" findMessenger${idx} manageMessenger${idx}\n")}
                    ]
      where
        manage          = (customFloating $ W.RationalRect (1/2) (1/8) (3/7) (3/4))
        findKeepass     = (className =? "KeePassXC")
        findYubioath    = (className =? ".yubioath-flutter-wrapped_")
        findTerminal    = (className =? "scratchterm")
        manageTerminal  = (customFloating $ W.RationalRect (1/4) 0 (5/7) (3/4))
${withMessengers
  (idx: m: "        manageMessenger${idx} = (customFloating $ W.RationalRect (1/6) (1/10) (4/6) (8/10))\n" +
           "        findMessenger${idx}   = (className =? \"${m.class}\")\n")}

    myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
      [ ((modm,               xK_Return), spawn $ XMonad.terminal conf)
      , ((modm,               xK_a     ), namedScratchpadAction myScratchPads "terminal")
      , ((modm,               xK_q     ), namedScratchpadAction myScratchPads "keepassxc")
      , ((modm,               xK_x     ), namedScratchpadAction myScratchPads "yubioath")
${withMessengers
  (idx: m:
  "      , ((${m.hotkey}), namedScratchpadAction myScratchPads \"messenger${idx}\")\n")}
      , ((modm .|. shiftMask, xK_c     ), kill)
      , ((modm,               xK_space ), sendMessage NextLayout)
      , ((modm .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf)
      , ((modm,               xK_n     ), refresh)
      , ((modm,               xK_Tab   ), windows W.focusDown)
      , ((modm,               xK_j     ), windows W.focusDown)
      , ((modm,               xK_k     ), windows W.focusUp)
      , ((modm .|. shiftMask, xK_Return), windows W.swapMaster)
      , ((modm .|. shiftMask, xK_j     ), windows W.swapDown)
      , ((modm .|. shiftMask, xK_k     ), windows W.swapUp)
      , ((modm,               xK_g     ), sendMessage $ ToggleGaps)
      , ((modm,               xK_h     ), sendMessage Shrink)
      , ((modm,               xK_l     ), sendMessage Expand)
      , ((modm,               xK_t     ), withFocused $ windows . W.sink)
      , ((modm              , xK_comma ), sendMessage (IncMasterN 1))
      , ((modm              , xK_period), sendMessage (IncMasterN (-1)))
      , ((modm .|. shiftMask, xK_q     ), io (exitWith ExitSuccess))
      , ((modm .|. shiftMask, xK_r     ), spawn "xmonad --restart")
      ]
      ++
      [((m .|. modm, k), windows $ f i)
          | (i, k) <- zip (drop 5 (XMonad.workspaces conf)) ([xK_F1 .. xK_F5])
          , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
      ++
      [((m .|. modm, k), windows $ f i)
          | (i, k) <- zip (XMonad.workspaces conf) ([xK_1 .. xK_9] ++ [xK_0])
          , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
      ++
      [((modm .|. mod1Mask, k), focusNth i)
       | (i, k) <- zip [0..4] [xK_1 ..]]
      ++
      [((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
         | (key, sc) <- zip [xK_s, xK_d, xK_f] [0, 1, 2]
          , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]

    myLayoutHook =
      ifWider 1920 (mkLayout wide) (mkLayout narrow)
      where
        mkLayout l =
          spacingRaw True (Border 0 0 0 0) False (Border 3 3 3 3) True $ avoidStruts l
        narrow  = smartBorders tiled ||| noBorders Full ||| Mirror tiled
        withGaps l r layout = gaps [(U,40), (D,40), (L,l), (R,r)] layout
        wide    =
              smartBorders (
                ifMax 1 (withGaps 960 960 Full) (
                  ifMax 2 (withGaps 480 480 tiled) (
                    withGaps 40 40 (ThreeColMid 1 (3/100) (4/10))
                  )
                )
              )
          ||| noBorders Full
        chat    = threeCl ||| tiled ||| Mirror tiled
        tiled   = Tall nmaster delta ratio
        threeCl = ThreeCol nmaster delta (1/3)
        nmaster = 1
        ratio   = 1/2
        delta   = 3/100

    myManageHook = composeAll . concat $
      [ [ manageDocks ]
      , [ (namedScratchpadManageHook myScratchPads) ]
      , [ isDialog --> doFloat ]
      , floatClass [ "fontforge", "arandr", ".arandr-wrapped", "Pavucontrol" ]
      , sendTitleTo "chat" [ "Viber", "Skype", "Slack", "Signal" ]
      , sendTitleTo "mail" [ "Thunderbird" ]
      , sendTitleTo "web2" [ "Google Chrome" ]
      , sendTitleTo "dev"  [ "IntelliJ IDEA", "Visual Studio Code" ]
      ]
      where
        floatClass cs     = [ className =? c --> doFloat | c <- cs ]
        sendClassTo ws cs = [ className =? c --> doF (W.shift ws) | c <- cs ]
        sendTitleTo ws ts = [ fmap (t `isInfixOf`) title --> doF (W.shift ws) | t <- ts ]

    myNormalBorderColor = "${color.bg}"
    myFocusedBorderColor = "${color.border}"

    myPP = namedScratchpadFilterOutWorkspacePP $ xmobarPP
      { ppTitle   = xmobarColor "${color.fg}" "" . shorten 100
      , ppCurrent = xmobarColor "${color.highlight}" "" . wrap "" ""
      , ppSep     = xmobarColor "${color.highlight}" "" " | "
      , ppUrgent  = xmobarColor "${color.urgent}" ""
      , ppLayout  = const "" -- to disable the layout info on xmobar
      }

    toggleStrutsKey XConfig {XMonad.modMask = modMask} = (modMask, xK_b)

    barCreate (S sid) = do
      spawn $ "sleep 2 && systemctl --user restart stalonetray.service"
      spawnPipe $ "xmobar --screen " ++ show sid

    barDestroy = return ()

    myStartupHook = setWMName "LG3D"
      <+> dynStatusBarStartup barCreate barDestroy
    myEventHook = perWindowKbdLayout
      <+> dynStatusBarEventHook barCreate barDestroy

    myLogHook = multiPP myPP myPP

    myAfterRescreenHook :: X ()
    myAfterRescreenHook = spawn "sleep 1; xmonad --restart"

    myRandrChangeHook :: X ()
    myRandrChangeHook = spawn "autorandr --change"

    rescreenCfg :: RescreenConfig
    rescreenCfg =
      def
      { afterRescreenHook = myAfterRescreenHook
      , randrChangeHook = myRandrChangeHook
      }

    main = do
      xmonad =<< statusBar "xmobar" myPP toggleStrutsKey (ewmh defaultConfig
        { terminal           = "${terminal} start --always-new-process"
        , modMask            = myModMask
        , borderWidth        = 3
        , keys               = myKeys
        , manageHook         = myManageHook
        , workspaces         = myWorkspaces
        , handleEventHook    = myEventHook
        , layoutHook         = myLayoutHook
        , normalBorderColor  = myNormalBorderColor
        , focusedBorderColor = myFocusedBorderColor
        , startupHook        = myStartupHook
        , logHook            = myLogHook
        })
  '';

in

{
  imports = [ (import ./xmobarrc.nix { inherit font color; }) ];

  xsession.windowManager.xmonad = {
    enable = true;
    enableContribAndExtras = true;
    config = pkgs.writeText "xmonad.hs" xmonadHs;
  };
}
