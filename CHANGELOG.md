# Changelog

## 0.1.1

* Preserve upstream's default detection strategy instead of forcing a full-page scan.
* Add `scan_strategy: :full` for callers that need OCR detection on every page.

## 0.1.0

* Local PDF classification and Markdown extraction using Firecrawl pdf-inspector 1.25.2.
* File and binary APIs with trailing keyword options, result structs and bang variants.
* Page selection, PDF passwords, processing modes and Markdown formatting options.
* Checksummed precompiled NIFs for Linux, macOS and Windows.
* ExDoc API documentation.
