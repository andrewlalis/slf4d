import slf4d;
import slf4d.default_provider;

void main() {
	configureLoggingProvider(new shared DefaultProvider(true, Levels.TRACE));

	example1Main();
	example2Exceptions();
	example3Loggers();
}

void example1Main() {
	info("Hello world!");
	try {
		int result = example1DoStuff();
		infoF!"Result = %d"(result);
	} catch (Exception e) {
		error("Failed to do stuff.", e);
	}
}

int example1DoStuff() {
	import std.random;
	int value = uniform(0, 100);
	if (value < 5) {
		throw new Exception("Value is too small!");
	}
	return value;
}

void example2Exceptions() {
	try {
		throw new Exception("Oh no!");
	} catch (Exception e) {
		warn("Uh oh, something went wrong.", e);
		error(e);
	}
}

void example3Loggers() {
	Logger logger = getLogger();
	logger.info("Hello world!");

	// The above code is equivalent to this:
	info("Hello world!");

	Logger logger2 = getLogger("Test Logs");
	logger2.warn("A message");
}
