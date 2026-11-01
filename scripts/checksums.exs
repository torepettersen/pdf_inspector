directory =
  case System.argv() do
    [directory] -> directory
    _args -> raise ArgumentError, "usage: elixir scripts/checksums.exs ARCHIVE_DIRECTORY"
  end

archives = Path.wildcard(Path.join(directory, "*.tar.gz"))

if archives == [] do
  raise ArgumentError, "no precompiled archives found in #{directory}"
end

checksums =
  Map.new(archives, fn archive ->
    hash = :crypto.hash(:sha256, File.read!(archive)) |> Base.encode16(case: :lower)
    {Path.basename(archive), "sha256:" <> hash}
  end)

File.write!(
  "checksum-Elixir.PdfInspector.Native.exs",
  inspect(checksums, pretty: true, limit: :infinity) <> "\n"
)
