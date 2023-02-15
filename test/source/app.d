import std.stdio;
import slf4d;
import slf4d.provider;

import other;

void main() {
	// configureLoggingProvider(new MyProvider());
	auto log = getLogger();
	log.builder()
		.lvl(Levels.INFO)
		.msg("Testing")
		.log();
	doStuff();
	log.info("Hello world!");
	log.logF!"Hello, %d"(Levels.ERROR, 123);
	log.infoF!"This is an info message, %s"("Andrew");
}

class MyProvider : LoggingProvider {
	shared shared(LoggerFactory) defineLoggerFactory() {
		return new shared SimpleLoggerFactory(
			new shared StdoutLogHandler(),
			Levels.TRACE
		);
	}
}
