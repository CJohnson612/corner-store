---
name: annotation-load
description: Reads an @agd: annotation from a source file and loads the corresponding AGD artifact node context into the conversation. Called by the AGD session agent when working on annotated files, and by hooks when a file is opened.
user-invocable: false
---

# Annotation Load

This skill bridges source code and the AGD artifact tree. When a source file contains an `@agd:` annotation, this skill resolves the annotation path to the corresponding artifact node and loads its README.md into the conversation context.

Any agent working on an annotated file can load the design intent, decisions, and principles that govern that file — without navigating the artifact tree manually.

---

## Annotation Format

The annotation is a code comment containing a relative path into the artifact tree:

```
// @agd: architecture/user-auth/jwt-implementation
# @agd: design/payment-processor/stripe-adapter
<!-- @agd: capabilities/content-management -->
```

The path after `@agd:` maps directly to the artifact node directory under `.claude/agd/`.

---

## On Invocation

Two call patterns:

**Pattern A — From agent (file already read):**
```
annotation_path: [e.g. "architecture/user-auth/jwt-implementation"]
```
The agent has already parsed the annotation from the file content and passes the path directly.

**Pattern B — From hook (file path provided):**
```
source_file: [absolute path to the annotated file]
```
The skill scans the file for `@agd:` annotations itself.

---

## Execution Steps

### Pattern A

1. **Resolve the node path:** `.claude/agd/[annotation_path]/README.md`

2. **Verify the file exists.** If not: return `error: node_not_found [resolved_path]`.

3. **Read README.md.** Return the full content.

4. **Also read children.md** if it exists and is non-empty. Append it to the return payload so the agent has a complete picture of the node and its immediate children.

5. **Return the result:**

```
ANNOTATION LOAD RESULT
annotation_path: [path]
node_path: [resolved .claude/agd/ path]
readme: |
  [full README.md content]
children_summary: |
  [children.md content, or null if no children]
```

### Pattern B

1. **Read the source file.**

2. **Scan for `@agd:` annotations.** Extract the path from each line matching the pattern `@agd:\s*([^\s*]+)`. If multiple annotations found, process each one.

3. **For each annotation found:** execute Pattern A steps 1-4.

4. **Return results for all annotations found:**

```
ANNOTATION LOAD RESULT
annotations_found: [N]
results:
  - annotation_path: [path]
    node_path: [resolved path]
    readme: |
      [README.md content]
    children_summary: |
      [children.md content or null]
  [repeat for each annotation]
```

If no annotations found in the file: return `annotations_found: 0`. The agent or hook handles this gracefully — no error.

---

## Agent Usage

When the session agent opens or reads a file during a session, it checks whether the file contains `@agd:` annotations. If annotations are found, it invokes this skill (Pattern B) and uses the returned node context to inform its understanding of that file's design intent before asking questions or making suggestions about the code.

The agent does not surface the raw README content to the practitioner — it uses it as background context. The practitioner can ask "what does the AGD node say about this file?" to get a summary.

---

## Adding an Annotation to a File

When the practitioner asks to annotate a file with an AGD node reference, the agent writes the annotation as a comment on the first non-blank, non-shebang line of the file, using the appropriate comment syntax for that file type:

| File type | Annotation format |
|---|---|
| JavaScript, TypeScript, Java, Go, C, C++ | `// @agd: [path]` |
| Python, Ruby, Shell, YAML | `# @agd: [path]` |
| HTML, XML, Markdown | `<!-- @agd: [path] -->` |
| CSS, SCSS | `/* @agd: [path] */` |

---

## Error Handling

| Scenario | Action |
|---|---|
| Node README not found at resolved path | Return `error: node_not_found [path]`. Agent surfaces: "No AGD artifact node exists at `[path]`. The annotation may be stale — check with `/agd:session`." |
| Source file not readable (Pattern B) | Return `error: file_not_readable [path] [OS error]`. |
| Annotation path is malformed (contains `..` or absolute path) | Return `error: invalid_annotation_path [path]`. Annotation paths must be relative and within `.claude/agd/`. |
| `.claude/agd/` directory not found | Return `error: agd_not_initialized`. Agent surfaces: "This project does not have an AGD session yet. Start one with `/agd:session`." |
| Multiple annotations in one file | Process all. Return all results. Not an error. |
