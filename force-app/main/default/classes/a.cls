global virtual class a {
    global static void log(Object obj) {
        System.debug(obj);
    }

    // Prints iterable
    global static void log(Iterable<Object> obj) {
        for (Object o : obj) {
            System.debug(o);
        }
    }
    // Prints map
    global static void log(Map<Object, Object> obj) {
        for (Object key : obj.keySet()) {
            System.debug(key + ': ' + obj.get(key));
        }
    }
    // Prints list
    global static void log(List<Object> obj) {
        for (Object o : obj) {
            System.debug(o);
        }
    }
    // Prints set
    global static void log(Set<Object> obj) {
        for (Object o : obj) {
            System.debug(o);
        }
    }
}