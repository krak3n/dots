export type Tick = number

// Where the session is working, as the shell prompt used to show it: the
// kubectl context (null without one), the directory, and the repo's state
// (null outside one).
export type Workspace = { kube: string | null; cwd: string; git: GitState | null }

export type GitState = {
  branch: string
  isDetached: boolean
  ahead: number
  behind: number
  staged: number
  modified: number
  untracked: number
  conflicted: number
}

declare module 'claude-code' {
  interface PluginState {
    'usage-band': { tick: Tick; workspace: Workspace | null }
  }
}
