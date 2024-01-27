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
	import slf4d.test;
	/*
	Since we're testing how our function affects the global logging state, we
	need to test it in isolation from all other logging. Therefore, we can call
	withTestingProvider() and provide a delegate function that takes an instance
	of a TestingLoggingProvider. This code will be executed in a clean logging
	state, to make sure results are consistent.
	*/
	withTestingProvider((TestingLoggingProvider provider) {
		doStuff(5);
		provider.assertMessageCount(Levels.INFO, 1);
		provider.assertMessageCount(Levels.TRACE, 5);
		provider.reset();

		doStuff(3);
		provider.assertHasMessage(Levels.WARN);
		provider.assertHasMessage("N is too low: 3");
	});
}
