# Testing Your Logging

When you incorporate logging into your application or library's logic, you should test that log messages are generated when you expect them to be, and that no log messages are generated when you're not expecting any.

SLF4D offers a logging provider implementation specifically designed to make testing your logging behavior easy: the [TestingLoggingProvider](ddoc-slf4d.testing_provider.TestingLoggingProvider). In `unittest` blocks (i.e. when the `unittest` version switch is active), SLF4D will automatically initialize with this provider.

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
    auto testingProvider = getTestingProvider();
    assert(getFileContents("missing-file") == "");
    assert(testingProvider.messageCount == 1);
    assert(testingProivder.messages[0].level == Levels.WARN);
}
```
