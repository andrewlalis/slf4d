module other;

import slf4d;

void doStuff() {
    auto log = getLogger();
    log.infoBuilder().msg("Hello").log();
}