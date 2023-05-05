import slf4d;

void main() {
	doStuff(10);
}

void doStuff(int n) {
	info("Doing stuff");
	if (n < 5) {
		warnF!"N is too low: %d"(n);
	}
	while (n > 0) {
		trace("Doing some more stuff...");
		n--;
	}
}

unittest {
	import slf4d;
	import slf4d.testing_provider;
	shared TestingLoggingProvider provider = new shared TestingLoggingProvider();
	configureLoggingProvider(provider);

	doStuff(5);
	provider.assertMessageCount(Levels.INFO, 1);
	provider.assertMessageCount(Levels.TRACE, 5);
	provider.reset();

	doStuff(3);
	provider.assertHasMessage(Levels.WARN);
	provider.assertHasMessage("N is too low: 3");
}
