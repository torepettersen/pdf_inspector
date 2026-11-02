defmodule PdfInspector.MixProject do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/torepettersen/pdf_inspector"

  def project do
    [
      app: :pdf_inspector,
      version: @version,
      elixir: "~> 1.15",
      description:
        "Local PDF classification and Markdown extraction powered by Firecrawl's Rust parser",
      source_url: @source_url,
      homepage_url: @source_url,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: [
        main: "readme",
        extras: ["README.md", "CHANGELOG.md", "LICENSE"],
        source_ref: "v#{@version}",
        groups_for_modules: [
          API: [PdfInspector],
          Results: [PdfInspector.Result, PdfInspector.Error]
        ]
      ]
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:rustler_precompiled, "~> 0.10"},
      {:rustler, "~> 0.38", optional: true, runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Upstream parser" => "https://github.com/firecrawl/pdf-inspector"
      },
      files: [
        "lib",
        "native/pdf_inspector_nif/src",
        "native/pdf_inspector_nif/.cargo",
        "native/pdf_inspector_nif/Cargo.toml",
        "native/pdf_inspector_nif/Cargo.lock",
        "checksum-*.exs",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "LICENSE"
      ]
    ]
  end
end
