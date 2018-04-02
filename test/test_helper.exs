File.mkdir_p(Path.dirname(JUnitFormatter.get_report_file_path()))
ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start()
