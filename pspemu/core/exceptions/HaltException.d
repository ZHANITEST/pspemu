module pspemu.core.exceptions.HaltException;
	
class HaltException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
    	super(msg, file, line, next);
    }
}

class TerminateCallbackException : HaltException {
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
    	super(msg, file, line, next);
    }
}