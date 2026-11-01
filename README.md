# PdfInspector

Local PDF classification and Markdown extraction for Elixir, backed by
[Firecrawl's pdf-inspector](https://github.com/firecrawl/pdf-inspector).

Read a file or pass PDF bytes. Options are ordinary trailing keyword arguments.
Supported platforms use checksum-verified precompiled NIFs, so installing the
library does not require Rust or Node.

[API documentation](https://torepettersen.github.io/pdf_inspector/) ·
[Source](https://github.com/torepettersen/pdf_inspector)

## Installation

Until the first Hex publication, use the GitHub release:

```elixir
{:pdf_inspector,
 github: "torepettersen/pdf_inspector",
 tag: "v0.1.0"}
```

Precompiled NIFs are provided for x86-64 and ARM64 Linux (glibc and musl),
Apple Silicon and Intel macOS, and x86-64 Windows (MSVC). Linux glibc x86-64
builds require glibc 2.35 or newer. The NIF ABI is 2.15, compatible with
Erlang/OTP 22 and newer; the Elixir library requires Elixir 1.15 or newer.

## Usage

```elixir
{:ok, result} = PdfInspector.process_file("invoice.pdf")

bytes = File.read!("invoice.pdf")
{:ok, result} = PdfInspector.process_binary(bytes, pages: [1, 2], profile: :compact)

result.markdown
result.pdf_type
result.page_count
result.pages_needing_ocr

# Bang variants return the result or raise.
result = PdfInspector.process_file!("invoice.pdf")
result = PdfInspector.process_binary!(bytes, page_breaks: true)
```

Both inputs return a `%PdfInspector.Result{}` with Markdown, classification,
page count, processing time, OCR flags, encoding flags, and optional PDF metadata.

### Options

| Option | Default | Meaning |
| --- | --- | --- |
| `mode` | `:full` | `:full`, `:detect` or `:analyze` |
| `pages` | `nil` | Non-empty list of 1-indexed pages to extract; nil selects all |
| `password` | `nil` | PDF decryption password |
| `profile` | `:fidelity` | `:compact` enables token-saving Markdown rewrites |
| `page_breaks` | `false` | Insert Markdown page markers |

`:detect` only classifies the document. `:analyze` computes extraction/layout
metadata without rendering Markdown. Both return `markdown: nil`.
Classification and page count describe the original document even with
`pages: [...]`; selecting pages deliberately limits extracted content.

Unknown options and invalid option values raise `ArgumentError`.

### Errors

Non-bang functions return `{:error, exception}`. File read failures return
`%File.Error{}`; parser failures return `%PdfInspector.Error{}`. Bang functions
raise the same exception.

### OCR and native execution

OCR is not enabled. Check `pages_needing_ocr` and `has_encoding_issues` before
treating Markdown as a complete document. In `:detect` mode, encoding quality
has not been checked. Every document page is inspected for OCR requirements.

Processing stays in memory with no disk cache, network API or model download.
File processing reads the file into memory first. Native parsing runs on a dirty
CPU scheduler and cannot be cancelled or given a hard timeout. A malformed or
very large PDF can consume substantial CPU or memory; callers control input sizes.

## Development

Install Rust/Cargo and build from source explicitly:

```sh
mix deps.get
PDF_INSPECTOR_BUILD=true mix test
PDF_INSPECTOR_BUILD=true mix docs --warnings-as-errors
```

`PDF_INSPECTOR_BUILD=true` forces source compilation. It is intended for
development and unsupported targets, and requires the optional Rustler dependency.
Normal installation downloads only the current platform's release artifact.

## Releases

1. Update the package version and changelog.
2. Run **Build precompiled NIFs** from GitHub Actions and wait for all targets.
3. Download its `nif-*` artifacts and put all archives in one directory.
4. Generate and commit `checksum-Elixir.PdfInspector.Native.exs`:

   ```sh
   elixir scripts/checksums.exs /path/to/archives
   ```

5. Tag the checksum commit, then create a GitHub release with those exact archives.
6. Verify normal installation without `PDF_INSPECTOR_BUILD`.
7. `mix hex.build` prepares the Hex package, including checksums and source
   fallback files. Publishing to Hex is a separate authenticated step.

The checksums must match the archives attached to the version's release.
Never replace release assets after publishing a package.

## License

MIT. The upstream Rust parser is also MIT-licensed.
