---
name: show-me
description: Help the user understand the current topic visually with concise diagrams, code-shape sketches, and published visual artifacts.
---

Help the user understand the current topic of conversation visually. Skip the preamble and keep prose brief. Pick the smallest view that makes the key point clear.

The text forms below — pseudocode, trees, diffs, code — render inline in the terminal, so put them directly in your reply, next to the sentence they support. Mermaid and rich visuals do not render in the terminal; publish those as an Artifact and hand back the link. See **publishing**.

- Show logic or an algorithm as pseudocode:

```text
on(save)
  if content is unchanged
    return cached result
  write new content
  return fresh result
```

- Show runtime control flow as a call tree:

```text
submitForm
  createSession
    persistPrompt
    launchAgent
  navigateToSession
```

- Show UI structure as a component tree, including state and module boundaries that matter:

```tsx
<SessionPage> (apps/example/src/routes/session.tsx)
  useSessionEvents()
  <SessionToolbar>
    <RunSkillButton> (packages/ui)
```

- Show file responsibility or a broad refactor as a shallow file tree:

```text
src/
├── commands/       # parses user actions
├── sessions/       # owns session state
└── transport/      # sends API requests
```

- Show component interaction, control flow, or data flow with Mermaid — in an Artifact, never as a terminal fence. Reach for it only when the relationship genuinely needs a graph; a call tree or pseudocode is cheaper and reads inline. Artifacts render mermaid natively from a `<pre class="mermaid">` block, so do not load a library:

```html
<pre class="mermaid">
sequenceDiagram
    participant User
    participant UI
    participant Daemon
    User->>UI: choose command
    UI->>Daemon: send expanded prompt
    Daemon-->>UI: stream result
</pre>
```

- Use `diff` when the point is what changes and the surrounding shape already exists. Match the diff shape to the topic.

For a component change:

```diff
 <SessionPage>
   useSessionEvents()
   <SessionToolbar>
+    <RunSkillButton />
   <SessionTimeline>
+    <SkillResultCard />
```

For a file-layout change:

```diff
 src/
 ├── commands/
+│   └── show-me.ts       # expands the slash command
 ├── sessions/
-└── transport.ts
+└── transport/
+    ├── client.ts
+    └── stream.ts
```

For a call-tree or call-stack change:

```diff
 submitForm
   createSession
     persistPrompt
+    expandSkillMention
     launchAgent
-  navigateToSession
+  navigateToSession
+    subscribeToEvents
```

For a state or control-flow change:

```diff
 on(save)
-  write content
+  if content is unchanged
+    return cached result
+  write new content
+  invalidate cache
```

- Show the whole block when most of it is new, when omitted context would hide ownership or order, or when the user needs a copyable target shape:

```ts
function expandSkill(command: string): string {
  const skillName = command.slice(1)
  return `use the ${skillName} skill`
}
```

- For a visual UI, layout, state comparison, or concept too dense for Mermaid, build one focused page — a diagram, an infographic, or a short slide deck, whichever fits the point. Match the product's colors, type, spacing, and components; use real labels and data; support desktop and mobile.

### publishing

When the view is a mermaid diagram or a rich visual:

1. Load the `artifact-design` skill before writing anything.
2. Write one self-contained HTML file to the scratchpad directory. Page content only — no `<!DOCTYPE>`, `<html>`, `<head>` or `<body>` tags; put a short `<title>` and your `<style>` at the top of the file.
3. Publish it with the Artifact tool (`file_path`, plus `favicon` and a one-line `description` on first publish), then give the user the link in one line.
4. To revise, edit the same file and call Artifact again with the same path — it redeploys to the same URL.

Put several related diagrams on one page rather than publishing a page each. Keep the prose in the terminal: the reply should still stand on its own, with the artifact carrying the picture.

### guidance

Place each visual next to the short text it supports. Keep only the calls, files, props, states, and boundaries needed to answer the user's current question or the options to resolve the current discussion point.

You may use one of these, you may use several, it is unlikely you will use all of them. Use your judgement and don't overwhelm the user.
