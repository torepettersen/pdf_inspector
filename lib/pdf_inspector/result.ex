defmodule PdfInspector.Result do
  @moduledoc """
  The result of processing a PDF.

  The original document's type is :text_based, :scanned, :image_based or :mixed.
  `page_count` always describes the original document, including when pages is set.
  markdown is `nil` in `:detect` and `:analyze` modes and when no readable text exists.

  pages_needing_ocr contains 1-indexed document page numbers. `has_encoding_issues`
  flags suspect decoded text; `false` in `:detect` mode means it was not checked.
  Document information fields are `nil` when absent. creation_date and mod_date
  retain the PDF's original date strings rather than implying a parsed timezone.
  """

  defstruct [
    :markdown,
    :pdf_type,
    :page_count,
    :processing_time_ms,
    :confidence,
    :title,
    :author,
    :subject,
    :keywords,
    :creator,
    :producer,
    :creation_date,
    :mod_date,
    pages_needing_ocr: [],
    has_encoding_issues: false
  ]

  @type t :: %__MODULE__{
          markdown: String.t() | nil,
          pdf_type: :text_based | :scanned | :image_based | :mixed,
          page_count: non_neg_integer(),
          processing_time_ms: non_neg_integer(),
          confidence: float(),
          pages_needing_ocr: [pos_integer()],
          has_encoding_issues: boolean(),
          title: String.t() | nil,
          author: String.t() | nil,
          subject: String.t() | nil,
          keywords: String.t() | nil,
          creator: String.t() | nil,
          producer: String.t() | nil,
          creation_date: String.t() | nil,
          mod_date: String.t() | nil
        }
end
