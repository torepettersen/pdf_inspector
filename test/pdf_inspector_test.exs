defmodule PdfInspectorTest do
  use ExUnit.Case, async: true

  doctest PdfInspector

  alias PdfInspector.Error
  alias PdfInspector.Result

  @invoice Path.join(__DIR__, "fixtures/columns.pdf")
  @pages Path.join(__DIR__, "fixtures/pages.pdf")

  test "file and binary processing return the same extracted facts" do
    assert {:ok, %Result{} = from_file} = PdfInspector.process_file(@invoice)
    assert {:ok, %Result{} = from_binary} = PdfInspector.process_binary(File.read!(@invoice))

    assert Map.delete(from_file, :processing_time_ms) ==
             Map.delete(from_binary, :processing_time_ms)

    assert from_file.pdf_type == :text_based
    assert from_file.page_count == 1
    assert from_file.pages_needing_ocr == []
    refute from_file.has_encoding_issues
    assert from_file.markdown =~ "|LEVERANDØR|FAKTURAMOTTAKER|"
    assert from_file.markdown =~ "|Nord Partner AS|Tore-konsulentvirksomhet (fiktiv)|"
  end

  test "bang variants return a result" do
    assert %Result{page_count: 1} = PdfInspector.process_file!(@invoice)
    assert %Result{page_count: 1} = PdfInspector.process_binary!(File.read!(@invoice))
  end

  test "missing files return File.Error and bang variants raise it" do
    path = Path.join(__DIR__, "fixtures/missing.pdf")
    assert {:error, %File.Error{reason: :enoent, path: ^path}} = PdfInspector.process_file(path)
    assert_raise File.Error, fn -> PdfInspector.process_file!(path) end
  end

  test "invalid PDFs return a parser exception and bang variants raise it" do
    assert {:error, %Error{message: message}} = PdfInspector.process_binary("broken PDF")
    assert is_binary(message)
    assert_raise Error, fn -> PdfInspector.process_binary!("broken PDF") end
  end

  test "scanned and mixed documents report pages requiring OCR" do
    assert {:ok, scanned} = PdfInspector.process_file(Path.join(__DIR__, "fixtures/scanned.pdf"))
    assert scanned.pages_needing_ocr == [1]
    assert scanned.markdown == nil

    assert {:ok, mixed} = PdfInspector.process_file(Path.join(__DIR__, "fixtures/mixed.pdf"))
    assert mixed.page_count == 2
    assert 2 in mixed.pages_needing_ocr
  end

  test "detect and analyze modes skip Markdown rendering" do
    for mode <- [:detect, :analyze] do
      assert {:ok, result} = PdfInspector.process_file(@invoice, mode: mode)
      assert result.pdf_type == :text_based
      assert result.page_count == 1
      assert result.markdown == nil
    end
  end

  test "classification uses upstream's default page sampling in long documents" do
    # Page 8 is scanned but falls outside upstream's default sample.
    path = Path.join(__DIR__, "fixtures/sampled.pdf")
    bytes = File.read!(path)

    for opts <- [[], [mode: :full], [mode: :detect], [mode: :analyze]] do
      assert {:ok, result} = PdfInspector.process_file(path, opts)
      assert result.page_count == 10
      assert result.pdf_type == :text_based
      assert result.confidence == 1.0

      assert {:ok, from_binary} = PdfInspector.process_binary(bytes, opts)

      assert Map.delete(from_binary, :processing_time_ms) ==
               Map.delete(result, :processing_time_ms)
    end
  end

  test "page selection limits extraction while preserving the document page count" do
    assert {:ok, all} = PdfInspector.process_file(@pages)
    assert all.markdown =~ "FIRST PAGE"
    assert all.markdown =~ "SECOND PAGE"

    assert {:ok, selected} = PdfInspector.process_file(@pages, pages: [2])
    assert selected.page_count == 2
    assert selected.markdown =~ "SECOND PAGE"
    refute selected.markdown =~ "FIRST PAGE"
  end

  test "full scanning reports an isolated scanned page outside the default sample" do
    path = Path.join(__DIR__, "fixtures/long_mixed.pdf")
    bytes = File.read!(path)

    for mode <- [:full, :detect, :analyze] do
      assert {:ok, sampled} = PdfInspector.process_binary(bytes, mode: mode)
      assert sampled.pdf_type == :text_based
      assert sampled.pages_needing_ocr == []

      opts = [mode: mode, scan_strategy: :full]
      assert {:ok, full} = PdfInspector.process_binary(bytes, opts)
      assert full.pdf_type == :mixed
      assert full.pages_needing_ocr == [8]
      assert full.page_count == 10

      assert {:ok, from_file} = PdfInspector.process_file(path, opts)

      assert Map.delete(from_file, :processing_time_ms) ==
               Map.delete(full, :processing_time_ms)
    end
  end

  test "Markdown formatting options use a trailing keyword list" do
    assert {:ok, result} = PdfInspector.process_file(@pages, profile: :compact, page_breaks: true)
    assert result.markdown =~ "<!-- Page"
    assert result.markdown =~ "SECOND PAGE"
  end

  test "a password unlocks an encrypted PDF through both input APIs" do
    path = Path.join(__DIR__, "fixtures/encrypted.pdf")
    assert {:error, %Error{}} = PdfInspector.process_file(path)
    assert {:ok, result} = PdfInspector.process_file(path, password: "reader-password")
    assert result.markdown =~ "Nord Partner AS"

    assert {:ok, from_binary} =
             PdfInspector.process_binary(File.read!(path), password: "reader-password")

    assert from_binary.markdown == result.markdown
  end

  test "unknown and invalid options raise useful argument errors" do
    bytes = File.read!(@invoice)

    for opts <- [
          [unknown: true],
          [mode: :invalid],
          [pages: []],
          [pages: [0]],
          [pages: [4_294_967_296]],
          [pages: "1"],
          [password: 123],
          [profile: :invalid],
          [page_breaks: "yes"],
          [scan_strategy: :invalid]
        ] do
      assert_raise ArgumentError, fn -> PdfInspector.process_binary(bytes, opts) end
    end
  end
end
