import std.stdio;
import slf4d;
import slf4d.level;

import other;

static LoggerFactory loggerFactory;
static this() {
	loggerFactory = getLoggerFactory();
}

void main() {
	auto log = loggerFactory.getLogger();
	log.builder()
		.lvl(Levels.INFO)
		.msg("Testing")
		.log();
	doStuff();
	log.info("Hello world!");
	log.logF!"Hello, %d"(Levels.ERROR, 123);
	log.infoF!"This is an info message, %s"("Andrew");
}

private LoggerFactory getLoggerFactory() {
	return new SimpleLoggerFactory(
		new StdoutLogHandler(),
		Levels.TRACE
	);
}
