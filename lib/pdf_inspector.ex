defmodule PdfInspector do
  @moduledoc """
  Local PDF classification and Markdown extraction with Firecrawl's Rust parser.

  Use `process_file/2` for a filesystem path and `process_binary/2` for PDF contents.
  Both accept a trailing keyword list and return `{:ok, result}` or `{:error, exception}`.
  Their bang variants return the result directly or raise the exception.

  Precompiled native libraries are downloaded and checksum-verified at compile time.
  No Rust compiler, Node runtime, external API, model download or OCR engine is needed
  for a supported platform. Extraction stays in memory and runs on a dirty CPU
  scheduler; a running native parse cannot be cancelled.

  ## Options

    * `:mode` - `:full` (default) extracts Markdown, `:detect` classifies without
      extraction, and `:analyze` extracts document metadata without rendering Markdown.
    * `:pages` - a non-empty list of positive, 1-indexed page numbers. Defaults to
      all pages. Document classification and `page_count` describe the original PDF;
      pages limits extraction. Selecting pages may intentionally omit document content.
    * `:password` - a binary password for encrypted PDFs. Defaults to `nil`.
    * `:profile` - `:fidelity` (default) preserves source characters, or `:compact`
      enables token-saving Markdown rewrites.
    * `:page_breaks` - inserts Markdown page markers when `true`. Defaults to `false`.
    * `:scan_strategy` - `:default` preserves upstream detection defaults; `:full`
      checks every page for OCR needs, including pages outside the default sample.

  By default, classification samples up to eight pages. Scanned pages
  are reported in PdfInspector.Result.pages_needing_ocr; this library does not perform OCR.
  Do not treat partial Markdown as a complete document without checking that field
  and `has_encoding_issues`. Sampling may miss isolated scanned pages in long documents.
  In detection mode, encoding issues have not been checked.

  Unknown options or invalid option values raise `ArgumentError`.
  """

  alias PdfInspector.Error
  alias PdfInspector.Native
  alias PdfInspector.Result

  @type option ::
          {:mode, :full | :detect | :analyze}
          | {:pages, [pos_integer()] | nil}
          | {:password, binary() | nil}
          | {:profile, :fidelity | :compact}
          | {:page_breaks, boolean()}
          | {:scan_strategy, :default | :full}

  @doc """
  Processes a PDF file, reading it into memory.

  Returns a File.Error when the file cannot be read, or a PdfInspector.Error
  when parsing fails.

  ## Examples

      PdfInspector.process_file("invoice.pdf", pages: [1, 2])
  """
  @spec process_file(Path.t(), [option()]) ::
          {:ok, Result.t()} | {:error, %File.Error{} | Error.t()}
  def process_file(path, opts \\ []) do
    case File.read(path) do
      {:ok, bytes} ->
        process_binary(bytes, opts)

      {:error, reason} ->
        {:error, File.Error.exception(reason: reason, action: "read file", path: path)}
    end
  end

  @doc """
  Processes a binary containing PDF bytes.

  ## Examples

      bytes = File.read!("invoice.pdf")
      PdfInspector.process_binary(bytes, profile: :compact)

      iex> match?({:error, %PdfInspector.Error{}}, PdfInspector.process_binary("not a PDF"))
      true
  """
  @spec process_binary(binary(), [option()]) :: {:ok, Result.t()} | {:error, Error.t()}
  def process_binary(bytes, opts \\ []) when is_binary(bytes) do
    options = validate_options(opts)

    case Native.process(bytes, options) do
      {:ok, result} -> {:ok, result}
      {:error, message} -> {:error, Error.exception(message)}
    end
  end

  @doc "Processes a PDF file and returns its result, raising on a file or parser error."
  @spec process_file!(Path.t(), [option()]) :: Result.t()
  def process_file!(path, opts \\ []) do
    case process_file(path, opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc "Processes PDF bytes and returns their result, raising on a parser error."
  @spec process_binary!(binary(), [option()]) :: Result.t()
  def process_binary!(bytes, opts \\ []) do
    case process_binary(bytes, opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  defp validate_options(opts) do
    options =
      opts
      |> Keyword.validate!(
        mode: :full,
        pages: nil,
        password: nil,
        profile: :fidelity,
        page_breaks: false,
        scan_strategy: :default
      )
      |> Map.new()

    unless options.mode in [:full, :detect, :analyze] do
      raise ArgumentError, ":mode must be :full, :detect or :analyze"
    end

    unless options.pages == nil or
             (is_list(options.pages) and options.pages != [] and
                Enum.all?(options.pages, &(is_integer(&1) and &1 > 0 and &1 <= 4_294_967_295))) do
      raise ArgumentError,
            ":pages must be nil or a non-empty list of positive 32-bit page numbers"
    end

    unless options.password == nil or is_binary(options.password) do
      raise ArgumentError, ":password must be nil or a binary"
    end

    unless options.profile in [:fidelity, :compact] do
      raise ArgumentError, ":profile must be :fidelity or :compact"
    end

    unless is_boolean(options.page_breaks) do
      raise ArgumentError, ":page_breaks must be a boolean"
    end

    unless options.scan_strategy in [:default, :full] do
      raise ArgumentError, ":scan_strategy must be :default or :full"
    end

    options
  end
end
