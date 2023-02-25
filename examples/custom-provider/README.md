# Custom Provider Example

This example shows how you'd define a dub project for a custom SLF4D LoggingProvider implementation. In this example, we define a simple provider that uses a custom LogHandler that just writes messages to stdout, but you can essentially do whatever you want in the `handle` method. It uses the `DefaultLoggerFactory` from SLF4D's default provider, since we just need something to construct Loggers with a log handler, and no other fancy features.

Run `dub test` within this directory to test it out.
