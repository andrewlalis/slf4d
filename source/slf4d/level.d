/**
 * Defines the concept of a *Log Level*, that is, a quantifiable *severity* of
 * a log message, which can be used to determine if such a message is shown, or
 * where that message gets routed.
 */
module slf4d.level;

/** 
 * The set of pre-defined logging levels that are universally recognized.
 */
const enum Levels {
    TRACE = Level(10, "TRACE"),
    DEBUG = Level(20, "DEBUG"),
    INFO = Level(30, "INFO"),
    WARN = Level(40, "WARN"),
    ERROR = Level(50, "ERROR")
}

unittest {
    assert(Levels.TRACE.value < Levels.DEBUG.value);
    assert(Levels.DEBUG.value < Levels.INFO.value);
    assert(Levels.INFO.value < Levels.WARN.value);
    assert(Levels.WARN.value < Levels.ERROR.value);
}

/** 
 * The struct definition of a logging level.
 */
struct Level {
    /** 
     * The integer value of this level. A higher value indicates a greater
     * severity of the log message.
     */
    public const int value;

    /** 
     * The textual name of this level, which may be shown in formatted log
     * messages.
     */
    public const string name;
}
