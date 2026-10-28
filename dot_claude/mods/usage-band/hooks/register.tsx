import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { GitState, Workspace } from '../types'

// Bumped whenever the figures may have changed, so the band redraws: the
// render hook reads usage itself (the plain call is free), but a redraw only
// happens when an atom it read is written.
const tick = atom({ plugin: 'usage-band', key: 'tick' } as const, 0)

// Read by `refresh`, never by a render: kubectl and git are processes, so the
// band draws what the last refresh found.
const workspace = atom({ plugin: 'usage-band', key: 'workspace' } as const, null)

const MINUTE = 60_000
const HOUR = 60 * MINUTE
const DAY = 24 * HOUR

// OneDark's gutter grey, for the empty part of a bar (the theme is OneDark
// everywhere else in these dotfiles).
const TRACK = '#3e4451'

// OneDark, for the workspace chips: the fill, and the dark ink drawn on it.
const CHIP_INK = '#282c34'

// Half circles that round the ends of a chip or a bar (Nerd Font glyphs).
const CAP_LEFT = '\ue0b6'
const CAP_RIGHT = '\ue0b4'

// Drawn on a limit's bar where the window is: how much of it has gone. The
// Nerd Font indent-line glyph (nf-indent-line).
const PACE_MARKER = '\ue621'
const BLUE = '#61afef'
const YELLOW = '#e5c07b'
const GREEN = '#98c379'
const RED = '#e06c75'

// Material Design icons, as the kube chip's: an hourglass, a week of days, a
// gauge for anything else, and a memory chip for the context window.
const GAUGE = '\u{f029a}'

// The verdict's icon for each state it can be in: a limit reached (a lock), a
// pace that will run out before the reset (a cross), a close one (an alert)
// and one with room to spare (a check).
const VERDICT_REACHED = '\u{f033e}'
const VERDICT_RUNS_OUT = '\u{f0159}'
const VERDICT_CLOSE = '\u{f0026}'
const VERDICT_OK = '\u{f05e0}'
const MEMORY = '\u{f035b}'

const LIMITS: Record<string, { label: string; icon: string; windowMs?: number }> = {
  five_hour: { label: '5 Hour', icon: '\u{f051f}', windowMs: 5 * HOUR },
  seven_day: { label: 'Weekly', icon: '\u{f0a33}', windowMs: 7 * DAY },
  spend_limit: { label: 'Spend', icon: GAUGE },
}

// A chip is its icon, a space and a label, in a body capped by two half
// circles: this many cells wide for the limits' six-letter labels and for
// "Context", which the bars to their right are measured from.
const LIMIT_CHIP = 10
const CONTEXT_CHIP = 11

const tone = (percent: number): string =>
  percent >= 85 ? RED : percent >= 60 ? YELLOW : GREEN

const tokens = (n: number): string =>
  n >= 1_000_000
    ? `${+(n / 1_000_000).toFixed(1)}M`
    : n >= 1000
      ? `${Math.round(n / 1000)}k`
      : `${n}`

const duration = (ms: number): string => {
  const minutes = Math.max(0, Math.round(ms / MINUTE))
  const days = Math.floor(minutes / 1440)
  const hours = Math.floor((minutes % 1440) / 60)

  return days > 0
    ? `${days}d ${hours}h`
    : hours > 0
      ? `${hours}h ${minutes % 60}m`
      : `${minutes}m`
}

// `bg` fills the cell behind the text: a bar is drawn in filled cells, as the
// chips are, so its body is flush with its caps rather than made of block glyphs.
type Run = { text: string; color: string; bg?: string }

const run = async ($: EngineInterface, argv: string[], cwd?: string): Promise<string | null> => {
  try {
    const result = await $.process.run(argv, { cwd, timeoutMs: 5000 })

    return result.exitCode === 0 ? result.stdout : null
  } catch {
    return null
  }
}

// `git status --porcelain=v2 --branch`: headers (`# branch.head main`,
// `# branch.ab +1 -0`), then one line per path. XY is the index and worktree
// state of a tracked path, `.` meaning unchanged.
const parseGit = (out: string): GitState => {
  const git: GitState = {
    branch: '',
    isDetached: false,
    ahead: 0,
    behind: 0,
    staged: 0,
    modified: 0,
    untracked: 0,
    conflicted: 0,
  }
  let oid = ''

  for (const line of out.split('\n')) {
    if (line.startsWith('# branch.head ')) {
      git.branch = line.slice('# branch.head '.length)
      git.isDetached = git.branch === '(detached)'
    } else if (line.startsWith('# branch.oid ')) {
      oid = line.slice('# branch.oid '.length, '# branch.oid '.length + 7)
    } else if (line.startsWith('# branch.ab ')) {
      const counts = /\+(\d+) -(\d+)/.exec(line)
      git.ahead = Number(counts?.[1] ?? 0)
      git.behind = Number(counts?.[2] ?? 0)
    } else if (line.startsWith('1 ') || line.startsWith('2 ')) {
      if (line[2] !== '.') git.staged += 1
      if (line[3] !== '.') git.modified += 1
    } else if (line.startsWith('u ')) {
      git.conflicted += 1
    } else if (line.startsWith('? ')) {
      git.untracked += 1
    }
  }

  if (git.isDetached) {
    git.branch = oid
  }

  return git
}

// What the branch has done, beside its chip: how far it is from its upstream,
// then what is staged (+), modified (~), untracked (?) and conflicted (!), or
// a tick when the tree is clean.
const gitRuns = (git: GitState): Run[] => {
  const runs: Run[] = []
  const add = (n: number, text: string, color: string) => {
    if (n > 0) runs.push({ text: `${text}${n}`, color })
  }

  add(git.ahead, '↑', GREEN)
  add(git.behind, '↓', RED)
  add(git.staged, '+', GREEN)
  add(git.modified, '~', YELLOW)
  add(git.untracked, '?', 'gray')
  add(git.conflicted, '!', RED)

  if (git.staged + git.modified + git.untracked + git.conflicted === 0) {
    runs.push({ text: '✓', color: GREEN })
  }

  return runs
}

// The branch chip's fill says how the tree is: red when it has conflicts,
// yellow when it has changes, green when it is clean.
const gitTone = (git: GitState): string =>
  git.conflicted > 0
    ? RED
    : git.staged + git.modified + git.untracked > 0
      ? YELLOW
      : GREEN

// `text` cut to `max` characters, ending in an ellipsis when it was longer.
const clip = (text: string, max: number): string =>
  text.length > max ? `${text.slice(0, Math.max(0, max - 1))}…` : text

// /Users/me/Code/x -> ~/Code/x
const home = (path: string): string => path.replace(/^\/(?:Users|home)\/[^/]+/, '~')

// A pill-shaped bar `width` cells across, its two end cells the rounded caps:
// `percent` filled in `fill`, the rest track, and an optional white marker at
// `marker` (0 to 1) for how far through its window the limit is.
const limitBar = (percent: number, fill: string, width: number, marker?: number): Run[] => {
  const cells = Math.max(1, width - 2)
  const filled = Math.round((Math.min(Math.max(percent, 0), 100) / 100) * cells)
  const at = marker === undefined ? -1 : Math.min(cells - 1, Math.round(marker * cells))
  const runs: Run[] = []

  for (let i = 0; i < cells; i += 1) {
    const bg = i < filled ? fill : TRACK
    const run: Run = i === at ? { text: PACE_MARKER, color: 'white', bg } : { text: ' ', color: bg, bg }
    const last = runs[runs.length - 1]

    // Adjacent cells of one color share a Text; the marker stays its own.
    if (last && last.bg === bg && run.text !== PACE_MARKER && last.text !== PACE_MARKER) {
      last.text += run.text
    } else {
      runs.push(run)
    }
  }

  // Each cap is the color of the cell it closes.
  return [
    { text: CAP_LEFT, color: runs[0]?.bg ?? TRACK },
    ...runs,
    { text: CAP_RIGHT, color: runs[runs.length - 1]?.bg ?? TRACK },
  ]
}

let isRefreshing = false

// Looks at kubectl and git again. Never throws and never waits on a hook:
// the band is not worth a stalled tool call.
async function refresh($: EngineInterface) {
  if (isRefreshing) {
    return
  }

  isRefreshing = true

  try {
    const cwd = await $.session.cwd()
    const [kube, status] = await Promise.all([
      run($, ['kubectl', 'config', 'current-context']),
      run($, ['git', '--no-optional-locks', 'status', '--porcelain=v2', '--branch'], cwd),
    ])
    const found: Workspace = {
      kube: kube?.trim() || null,
      cwd,
      git: status === null ? null : parseGit(status),
    }

    if (JSON.stringify(await read($, workspace)) !== JSON.stringify(found)) {
      await update($, workspace, () => found)
    }
  } catch {
    // Keep what the band last drew.
  } finally {
    isRefreshing = false
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    // The reset countdowns tick down, and the workspace is looked at again.
    $.clock.every(15_000, () => {
      void refresh($)
      void update($, tick, n => n + 1)
    })
    void refresh($)
    await update($, tick, n => n + 1)

    return result
  }).catch(($, e, next) => next(e))

  on('prompt.submit', async ($, e, next) => {
    const result = await next(e)
    await update($, tick, n => n + 1)

    return result
  }).catch(($, e, next) => next(e))

  // A tool is what changes the branch, the tree or the context.
  on('tool.call', async ($, e, next) => {
    const result = await next(e)
    void refresh($)
    await update($, tick, n => n + 1)

    return result
  }).catch(($, e, next) => next(e))

  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    void refresh($)
    await update($, tick, n => n + 1)

    return result
  }).catch(($, e, next) => next(e))

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    await read($, tick)
    const where = await read($, workspace)

    if (e.props.hasSurvey) {
      return next(e)
    }

    const width = e.props.bodyColumns
    const now = await $.clock.now()
    const { context, rateLimits, cost } = await $.session.usage({
      breakdown: 'summary',
      columns: width,
    })
    const { Box, Text } = $.ui.resolve(e)

    // Two sections side by side, four cells apart, inside a cell of padding at
    // each edge; with no rate-limit readings (API billing) the context section
    // takes the whole row. `inner*` is each one's width.
    const hasLimits = rateLimits.length > 0
    const room = width - 2
    const innerLeft = hasLimits ? Math.floor((room - 4) / 2) : 0
    const innerRight = hasLimits ? room - 4 - innerLeft : room

    // How each limit is pacing: the share of its window gone, and where the
    // current burn rate lands at reset.
    const limits = rateLimits.map(limit => {
      const known = LIMITS[limit.kind]
      const resetsIn = limit.resetsAt ? Date.parse(limit.resetsAt) - now : undefined
      const elapsed =
        known?.windowMs !== undefined && resetsIn !== undefined
          ? Math.min(1, Math.max(0, 1 - resetsIn / known.windowMs))
          : undefined
      const projected =
        elapsed !== undefined && elapsed >= 0.03 ? limit.percentUsed / elapsed : undefined

      return {
        limit,
        label: known?.label ?? limit.kind,
        icon: known?.icon ?? GAUGE,
        resetsIn,
        elapsed,
        projected,
      }
    })

    const worst = limits.reduce<(typeof limits)[number] | undefined>(
      (a, b) => ((b.projected ?? b.limit.percentUsed) > (a?.projected ?? -1) ? b : a),
      undefined,
    )
    const weekly = limits.find(l => l.limit.kind === 'seven_day')
    const exhausted = limits.find(l => l.limit.percentUsed >= 100)

    let verdict: { text: string; color: string; icon: string } | undefined
    if (exhausted) {
      verdict = {
        text: `${exhausted.label} limit reached${exhausted.resetsIn === undefined ? '' : ` — resets in ${duration(exhausted.resetsIn)}`}.`,
        color: RED,
        icon: VERDICT_REACHED,
      }
    } else if (worst?.projected !== undefined && worst.projected > 100) {
      verdict = {
        text: `At this pace you'll hit your ${worst.label} limit before it resets.`,
        color: RED,
        icon: VERDICT_RUNS_OUT,
      }
    } else if (worst?.projected !== undefined && worst.projected > 85) {
      verdict = {
        text: `Close to your ${worst.label} limit at this pace.`,
        color: YELLOW,
        icon: VERDICT_CLOSE,
      }
    } else if (limits.length > 0) {
      const day =
        weekly?.limit.resetsAt === undefined
          ? undefined
          : new Date(weekly.limit.resetsAt).toLocaleDateString('en', { weekday: 'long' })
      verdict = {
        text: `On track.${day ? ` You should reach ${day}'s reset with room to spare.` : ''}`,
        color: GREEN,
        icon: VERDICT_OK,
      }
    }

    // Context, split by what fills it: the biggest two rows, the rest as Other.
    const percent = Math.round(context.percent ?? 0)
    const breakdown = context.breakdown
    const used = (breakdown?.categories ?? [])
      .filter(c => c.kind === 'used' && c.tokens > 0)
      .sort((a, b) => b.tokens - a.tokens)
    const top = used.slice(0, 2)
    const other = used.slice(2).reduce((sum, c) => sum + c.tokens, 0)
    const total = breakdown?.rawMaxTokens ?? context.window
    const inUse = breakdown?.totalTokens ?? context.tokens ?? 0
    const free = Math.max(0, total - inUse)
    const contextBar = Math.max(1, innerRight - CONTEXT_CHIP - 1)
    // The bar is pill-shaped like the limits': its end cells are the caps.
    const contextCells = Math.max(1, contextBar - 2)
    const cells = (n: number) => Math.round((n / total) * contextCells)
    const segments: Run[] = [
      ...top.map(c => ({ text: ' '.repeat(cells(c.tokens)), color: c.color, bg: c.color })),
      { text: ' '.repeat(cells(other)), color: 'gray', bg: 'gray' },
    ].filter(s => s.text.length > 0)
    const filled = segments.reduce((sum, s) => sum + s.text.length, 0)
    const capLeft = segments[0]?.color ?? TRACK
    const capRight = filled >= contextCells ? (segments[segments.length - 1]?.color ?? TRACK) : TRACK

    // A rounded chip: dark ink on a filled body, capped with half-circles (which
    // carry their own padding, so the label sits right against them).
    const chip = (key: string, fill: string, label: string) => (
      <Box key={key}>
        <Text color={fill}>{CAP_LEFT}</Text>
        <Text color={CHIP_INK} backgroundColor={fill} bold>
          {label}
        </Text>
        <Text color={fill}>{CAP_RIGHT}</Text>
      </Box>
    )


    const bar = (runs: Run[]) => (
      <Box>
        {runs.map((r, i) => (
          <Text key={`${i}`} color={r.color} backgroundColor={r.bg}>
            {r.text}
          </Text>
        ))}
      </Box>
    )

    return (
      <Box flexDirection="column">
        <Text color={TRACK}>{'─'.repeat(width)}</Text>
        {verdict && (
          <Box paddingX={1}>
            {chip(
              'verdict',
              verdict.color,
              `${verdict.icon} ${clip(verdict.text, width - 8)}`,
            )}
          </Box>
        )}
        <Box columnGap={4} paddingX={1} marginTop={1}>
          {hasLimits && (
            <Box flexDirection="column" width={innerLeft}>
              {limits.map(({ limit, label, icon, resetsIn, elapsed, projected }, index) => (
                <Box key={limit.kind} flexDirection="column" marginTop={index === 0 ? 0 : 1}>
                  <Box columnGap={1}>
                    {chip(limit.kind, tone(limit.percentUsed), `${icon} ${label.slice(0, 6).padEnd(6)}`)}
                    {bar(
                      limitBar(
                        limit.percentUsed,
                        tone(limit.percentUsed),
                        Math.max(1, innerLeft - LIMIT_CHIP - 6),
                        elapsed,
                      ),
                    )}
                    <Text bold color={tone(limit.percentUsed)}>
                      {`${Math.round(limit.percentUsed)}%`.padStart(4)}
                    </Text>
                  </Box>
                  <Box paddingLeft={LIMIT_CHIP + 1}>
                    <Text dimColor>
                      {projected === undefined ? 'On pace' : `On pace for about ${Math.round(projected)}% by reset`}
                      {resetsIn === undefined ? '' : ` — resets in ${duration(resetsIn)}`}
                    </Text>
                  </Box>
                </Box>
              ))}
            </Box>
          )}
          <Box flexDirection="column" width={innerRight}>
            <Box columnGap={1}>
              {chip('context', tone(percent), `${MEMORY} Context`)}
              <Box>
                <Text color={capLeft}>{CAP_LEFT}</Text>
                {segments.map((run, i) => (
                  <Text key={`${i}`} color={run.color} backgroundColor={run.bg}>
                    {run.text}
                  </Text>
                ))}
                <Text color={TRACK} backgroundColor={TRACK}>
                  {' '.repeat(Math.max(0, contextCells - filled))}
                </Text>
                <Text color={capRight}>{CAP_RIGHT}</Text>
              </Box>
            </Box>
            <Box paddingLeft={CONTEXT_CHIP + 1} width={innerRight} justifyContent="space-between">
              <Text>
                <Text bold color={tone(percent)}>
                  {`${percent}% used`}
                </Text>
                {cost && <Text dimColor>{` · session $${cost.usd.toFixed(2)}`}</Text>}
              </Text>
              <Text dimColor>
                {tokens(free)} free of {tokens(total)}
              </Text>
            </Box>
            {top.map(c => (
              <Box
                key={c.name}
                paddingLeft={CONTEXT_CHIP + 1}
                width={innerRight}
                justifyContent="space-between"
              >
                <Text color={c.color}>{c.name}</Text>
                <Text dimColor>{tokens(c.tokens)}</Text>
              </Box>
            ))}
            {other > 0 && (
              <Box paddingLeft={CONTEXT_CHIP + 1} width={innerRight} justifyContent="space-between">
                <Text>Other</Text>
                <Text dimColor>{tokens(other)}</Text>
              </Box>
            )}
          </Box>
        </Box>
        {where && (
          <Box paddingX={1} columnGap={1} flexWrap="wrap" marginTop={1}>
            {where.kube && chip('kube', BLUE, `\u{f0833} ${where.kube}`)}
            {chip('dir', YELLOW, `\u{f024b} ${home(where.cwd)}`)}
            {where.git && (
              <Box columnGap={1}>
                {chip('git', gitTone(where.git), `\u{f062c} ${where.git.branch}`)}
                {gitRuns(where.git).map((r, i) => (
                  <Text key={`${i}`} color={r.color} bold>
                    {r.text}
                  </Text>
                ))}
              </Box>
            )}
          </Box>
        )}
      </Box>
    )
  })
}
