import std.stdio;
import slf4d;
import slf4d.provider;

import other;

private Logger log;
static this() {
	log = getLogger();
}

void main() {
	log.builder()
		.lvl(Levels.INFO)
		.msg("Testing")
		.log();
	doStuff();
	log.info("Hello world!");
	log.logF!"Hello, %d"(Levels.ERROR, 123);
	log.infoF!"This is an info message, %s"("Andrew");
	log.debug_("This is a debug message.");

	auto otherLog = getLogger("this_is_a_longer_logger_name");
	otherLog.info("Hello world!");
}
