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
    /** 
     * The lowest severity log level defined by SLF4D, usually for fine-grained
     * debugging of individual statements and control flow.
     */
    TRACE = Level(10, "TRACE"),
    /** 
     * A low severity log level used for extra information that's only useful
     * when debugging a program's behavior.
     */
    DEBUG = Level(20, "DEBUG"),

    /** 
     * A medium severity log level used for reporting information during
     * standard, nominal program operation.
     */
    INFO = Level(30, "INFO"),

    /** 
     * A higher severity log level for reporting anomalous but non-fatal issues
     * that arise at runtime.
     */
    WARN = Level(40, "WARN"),

    /** 
     * A severe log level for program errors that indicate a fatal bug that
     * leads to program failure or inconsistent state.
     */
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
    public int value;

    /** 
     * The textual name of this level, which may be shown in formatted log
     * messages.
     */
    public string name;
}
