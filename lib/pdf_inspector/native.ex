defmodule PdfInspector.Native do
  @moduledoc false

  version = Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :pdf_inspector,
    crate: :pdf_inspector_nif,
    base_url: "https://github.com/torepettersen/pdf_inspector/releases/download/v#{version}",
    version: version,
    nif_versions: ["2.15"],
    targets: [
      "aarch64-apple-darwin",
      "aarch64-unknown-linux-gnu",
      "aarch64-unknown-linux-musl",
      "x86_64-apple-darwin",
      "x86_64-pc-windows-msvc",
      "x86_64-unknown-linux-gnu",
      "x86_64-unknown-linux-musl"
    ],
    force_build: System.get_env("PDF_INSPECTOR_BUILD") in ["1", "true"]

  def process(_bytes, _options), do: :erlang.nif_error(:nif_not_loaded)
end
