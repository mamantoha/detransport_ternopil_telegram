module DetransportTelegram
  @@logger : Logger?

  def self.logger
    log_file = File.new("#{__DIR__}/../../log/telegram.log", "a")
    stdout = STDOUT

    writer = IO::MultiWriter.new(log_file, stdout)

    @@logger ||= Logger.new(writer).tap do |l|
      l.level = Logger::Severity.parse("DEBUG")
    end
  end
end
