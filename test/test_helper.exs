[{Joken.CurrentTime.Mock, _}] = Code.load_file("test/support/mock_current_time.exs")

File.mkdir_p(Path.dirname(JUnitFormatter.get_report_file_path()))
ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start()
