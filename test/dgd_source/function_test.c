int local_vars_should_parse() {
   string v;
   int a, b, c;

   return 0;
}

int v;

/** This method doesn't do anything, but it tests that the parser accepts arguments.
  *
  * @param clone not a real argument, though.
  * @see local_vars_should_parse
  */
float test_args(varargs int clone) {
   string v;
   object here_it_is;

   return 0;
}
