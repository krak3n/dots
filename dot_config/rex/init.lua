-- Rex config, mirroring the keybindings in ../herdr/config.toml so muscle memory
-- carries over. Every binding hangs off the same prefix herdr uses (ctrl+a),
-- written as a Rex key sequence ("ctrl+a>x").
--
-- herdr bindings with no Rex equivalent are intentionally left out: copy mode
-- (prefix+v), edit scrollback, rename pane, detach (Rex's server always
-- persists), and the Pickr / herdr-nvim plugin pickers. Use the command
-- palette (cmd+shift+p by default) in place of the pickers.

local prefix = "ctrl+a"

-- Once ctrl+a starts a sequence it no longer reaches the terminal, which would
-- break zsh's beginning-of-line. Pressing it twice sends a literal ctrl+a,
-- the same as tmux's `send-prefix`.
rex.bind(prefix .. ">ctrl+a", "pane.send_key", { key = "ctrl+a" })

-- Splits: side-by-side and stacked, like tmux's `bind |` and `bind '"'`.
-- Keys are written unshifted and follow the keyboard layout (UK here), so |
-- is shift+\ and " is shift+2. On a US layout " would be shift+' instead.
rex.bind(prefix .. ">shift+\\", "pane.split", { direction = "right" })
rex.bind(prefix .. ">shift+2", "pane.split", { direction = "down" })

-- Pane focus (vim keys)
rex.bind(prefix .. ">h", "pane.focus.left")
rex.bind(prefix .. ">j", "pane.focus.down")
rex.bind(prefix .. ">k", "pane.focus.up")
rex.bind(prefix .. ">l", "pane.focus.right")

-- Pane resize
rex.bind(prefix .. ">shift+h", "pane.resize", { direction = "left" })
rex.bind(prefix .. ">shift+j", "pane.resize", { direction = "down" })
rex.bind(prefix .. ">shift+k", "pane.resize", { direction = "up" })
rex.bind(prefix .. ">shift+l", "pane.resize", { direction = "right" })

-- Close pane (herdr's default prefix+x, not listed in its config.toml)
rex.bind(prefix .. ">x", "pane.close")

-- Zoom (matches tmux's `bind M`; herdr moved it off its default prefix+z)
rex.bind(prefix .. ">shift+m", "pane.zoom")

-- Tabs
rex.bind(prefix .. ">ctrl+l", "client.tab.next")
rex.bind(prefix .. ">ctrl+h", "client.tab.previous")
rex.bind(prefix .. ">alt+shift+left", "client.tab.move.backward")
rex.bind(prefix .. ">alt+shift+right", "client.tab.move.forward")
rex.bind(prefix .. ">,", "client.tab.rename")  -- tmux's rename-window binding

-- herdr workspaces are Rex sessions. herdr spreads the picker over n (its
-- workspace picker), s (Pickr spaces) and w (tmux-style navigator). Rex's own
-- switcher covers n and s; w opens the tree picker defined further down.
rex.bind(prefix .. ">n", "session.switch")
rex.bind(prefix .. ">s", "session.switch")

-- Reload this file (herdr's prefix+shift+r)
rex.bind(prefix .. ">shift+r", "client.config.reload")

-- Lazygit popup, a floating layer over the focused window (herdr's prefix+g).
-- Run through a login zsh so lazygit is on PATH and picks up CONFIG_DIR from
-- ~/.zprofile; the Rex server's own environment has neither.
rex.action{
  name  = "lazygit",
  title = "Lazygit",
  run   = function(ctx, args)
    local terminal = "com.superlogical.terminal"
    local options = {
      command = { "/bin/zsh", "-lc", "lazygit" },
      shell = "none",
    }

    -- Open in the focused pane's directory so lazygit lands in the right repo.
    -- Prefer the directory the shell reported (OSC 7: a percent-encoded
    -- file:// URL, or a plain path), but our zsh doesn't send it, so fall back
    -- to the working directory of the pane's foreground process. If neither is
    -- known, cwd stays unset and Rex picks its default.
    local pwd = rex.block.call(terminal, "pwd", {})
    if pwd ~= nil and pwd.pwd ~= nil then
      local path = pwd.pwd:gsub("^file://[^/]*", "")
      path = path:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
      options.cwd = path
    else
      local proc = rex.block.call(terminal, "process", {})
      if proc ~= nil and proc.foreground ~= nil then
        options.cwd = proc.foreground.cwd
      end
    end

    local _, err = rex.session.new_layer{
      bounds = { 0.025, 0.025, 0.95, 0.95 },
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        options = options,
      },
    }
    if err ~= nil then error(err, 0) end
  end,
}
rex.bind(prefix .. ">g", "lazygit")

-- tmux choose-tree style picker (herdr's tmux-session-navigator on prefix+w):
-- a floating layer listing sessions > tabs > panes with a preview of the
-- selected pane. The script is dot_config/rex/executable_session-tree.
--
-- The action returns straight away rather than waiting for the picker (actions
-- are cut off after 30 seconds); the layer closes itself when the picker exits.
-- ctx.client_id is passed through so the jump switches the window that pressed
-- the key. Jumping calls the client action session.select over the CLI, which
-- Rex only allows with Remote Control on (Settings > Rex Server).
--
-- Known Rex bug: opening a focused floating layer clears pane zoom, and closing
-- it doesn't restore it.
rex.action{
  name  = "session_tree",
  title = "Session Tree",
  run   = function(ctx, args)
    local _, err = rex.session.new_layer{
      bounds = { 0.05, 0.05, 0.9, 0.9 },
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        options = {
          -- Login zsh so fzf and python3 are on PATH; "$@" is the client id
          -- (the first word after the script is $0).
          command = {
            "/bin/zsh", "-lc", 'exec "$HOME/.config/rex/session-tree" "$@"',
            "session-tree", ctx.client_id or "",
          },
          shell = "none",
        },
      },
    }
    if err ~= nil then error(err, 0) end
  end,
}
rex.bind(prefix .. ">w", "session_tree")
