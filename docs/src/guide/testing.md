# Testing Your Logging

When you incorporate logging into your application or library's logic, you should test that log messages are generated when you expect them to be, and that no log messages are generated when you're not expecting any.

SLF4D offers a logging provider implementation specifically designed to make testing your logging behavior easy: the [TestingLoggingProvider](ddoc-slf4d.testing_provider.TestingLoggingProvider). In `unittest` blocks, you can make use of this by importing the `slf4d.test` module.

## Example: Testing for Logs

Suppose you have some function which will emit log messages under certain conditions. We can test it by getting a reference to the TestingLoggingProvider and inspecting the messages it accumulates.

```d
string getFileContents(string filename) {
    import std.file : readText, exists;
    if (!exists(filename)) {
        warnF!"File %s doesn't exist."(filename);
        return "";
    } else {
        return readText(filename);
    }
}

unittest {
    import slf4d.test;
    withTestingProvider((provider) {
        assert(getFileContents("missing-file") == "");
        assert(provider.messageCount == 1);
        assert(proivder.messages[0].level == Levels.WARN);
    });
}
```
