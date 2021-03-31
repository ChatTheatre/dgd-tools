require "dgd-tools/version"

require "treetop"

Treetop.load "#{__dir__}/dgd_grammar.tt"

module DGD; end

module DGD::Doc

  class SourceFile
    def initialize(path)
      unless File.exist?(path)
        raise "No such source file for DGD::Doc::Sourcefile: #{path.inspect}"
      end

      @path = path
    end

    private

    def parse_contents
      s = File.read(@path)

      remaining = parse_inherits(s)
      remaining = parse_top_level_decls(remaining)
      if remaining != ""
        raise "Tried to parse #{@path.inspect} but had text remaining!\n#{remaining.inspect}"
      end
    end

    def parse_inherits(contents)
      @inherits = []

      # Inherit: OptPrivate 'inherit' OptLabel OptObject StringExp ';'

    end

    def parse_top_level_decls(contents)
      @decls = []

      # Parse a data decl or a func decl
      ""
    end
  end
end


=begin
DGD Grammar:
complex_string = /\"([^\"\\\\\n]|\\\\.)+\"/                             \
simple_char = /'[^'\\\\\n]+'/                                           \
complex_char = /'([^'\\\\\n]|\\\\.)+'/                                  \
decimal = /[1-9][0-9]*/                                                 \
octal = /0[0-7]*/                                                       \
hexadecimal = /0[xX][a-fA-F0-9]+/                                       \
float = /[0-9]+\\.[0-9]+([eE][-+]?[0-9]+)?/                             \
float = /\\.[0-9]+([eE][-+]?[0-9]+)?/                                   \
float = /[0-9]+[eE][-+]?[0-9]+/                                         \
whitespace = /([ \t\v\f\r\n]|\\/\\*([^*]*\\*+[^/*])*[^*]*\\*+\\/)+/     " +
"\
Inherit: OptPrivate 'inherit' OptLabel OptObject StringExp ';'          \
                                                        ? inh           \
OptPrivate:                                             ? false         \
OptPrivate: 'private'                                   ? true          \
OptLabel:                                               ? opt           \
OptLabel: ident                                                         \
OptObject:                                                              \
OptObject: 'object'                                     ? empty         \
DataDecl: ClassType Dcltrs ';'                          ? dataDecl      \
FuncDecl: ClassType FunctionDcltr CompoundStmt          ? functionDecl  \
FuncDecl: Class FunctionName '(' Formals ')' CompoundStmt ? voidDecl    \
Formals:                                                ? noArguments   \
Formals: 'void'                                         ? noArguments   \
Formals: FormalList                                     ? arguments     \
Formals: FormalList '...'                               ? ellipsis      \
FormalList: Formal                                                      \
FormalList: FormalList ',' Formal                                       \
Formal: ClassType DataDcltr                             ? formal        \
Formal: ident                                           ? formalMixed   " +
"\
ClassType: ClassSpecList TypeSpec                       ? classType     \
ClassType: ClassSpecList 'object' ListExp               ? classTypeName \
Class: ClassSpecList                                    ? classType     \
ClassSpecList:                                                          \
ClassSpecList: ClassSpecList ClassSpec                                  \
ClassSpec: 'private'                                                    \
ClassSpec: 'static'                                                     \
ClassSpec: 'atomic'                                                     \
ClassSpec: 'nomask'                                                     \
ClassSpec: 'varargs'                                                    \
TypeSpec: 'int'                                                         \
TypeSpec: 'float'                                                       \
TypeSpec: 'string'                                                      \
TypeSpec: 'object'                                                      \
TypeSpec: 'mapping'                                                     \
TypeSpec: 'mixed'                                                       \
TypeSpec: 'void'                                                        \
DataDcltr: Stars ident                                                  \
Stars: StarList                                         ? count         \
StarList:                                                               \
StarList: StarList '*'                                                  " +
"\
FunctionName: ident                                                     \
FunctionName: Operator                                  ? concat        \
Operator: 'operator' '+'                                                \
Operator: 'operator' '-'                                                \
Operator: 'operator' '*'                                                \
Operator: 'operator' '/'                                                \
Operator: 'operator' '%'                                                \
Operator: 'operator' '&'                                                \
Operator: 'operator' '^'                                                \
Operator: 'operator' '|'                                                \
Operator: 'operator' '<'                                                \
Operator: 'operator' '>'                                                \
Operator: 'operator' '>='                                               \
Operator: 'operator' '<='                                               \
Operator: 'operator' '<<'                                               \
Operator: 'operator' '>>'                                               \
Operator: 'operator' '~'                                                \
Operator: 'operator' '++'                                               \
Operator: 'operator' '--'                                               \
Operator: 'operator' '[' ']'                                            \
Operator: 'operator' '[' ']' '='                                        \
Operator: 'operator' '[' '..' ']'                                       " +
"\
FunctionDcltr: Stars FunctionName '(' Formals ')'                       \
Dcltr: DataDcltr                                        ? list          \
Dcltr: FunctionDcltr                                    ? list          \
Dcltrs: ListDcltr                                       ? noCommaList   \
ListDcltr: Dcltr                                                        \
ListDcltr: ListDcltr ',' Dcltr                                          \
Locals: ListLocal                                       ? list          \
ListLocal:                                                              \
ListLocal: ListLocal DataDecl                                           \
ListStmt:                                                               \
ListStmt: ListStmt Stmt                                 ? listStmt      " +
"\
OptElse: 'else' Stmt                                    ? parsed_1_     \
OptElse:                                                ? opt           \
Stmt: ListExp ';'                                       ? expStmt       \
Stmt: CompoundStmt                                                      \
Stmt: 'if' '(' ListExp ')' Stmt OptElse                 ? ifStmt        \
Stmt: 'do' Stmt 'while' '(' ListExp ')' ';'             ? doWhileStmt   \
Stmt: 'while' '(' ListExp ')' Stmt                      ? whileStmt     \
Stmt: 'for' '(' OptListExp ';' OptListExp ';' OptListExp ')' Stmt       \
                                                        ? forStmt       \
Stmt: 'rlimits' '(' ListExp ';' ListExp ')' CompoundStmt                \
                                                        ? rlimitsStmt   \
Stmt: 'catch' CompoundStmt ':' Stmt                     ? catchErrStmt  \
Stmt: 'catch' CompoundStmt                              ? catchStmt     " +
"\
Stmt: 'switch' '(' ListExp ')' CompoundStmt             ? switchStmt    \
Stmt: 'case' Exp ':' Stmt                               ? caseStmt      \
Stmt: 'case' Exp '..' Exp ':' Stmt                      ? caseRangeStmt \
Stmt: 'default' ':' Stmt                                ? defaultStmt   \
Stmt: ident ':' Stmt                                    ? labelStmt     \
Stmt: 'goto' ident ';'                                  ? gotoStmt      \
Stmt: 'break' ';'                                       ? breakStmt     \
Stmt: 'continue' ';'                                    ? continueStmt  \
Stmt: 'return' ListExp ';'                              ? returnExpStmt \
Stmt: 'return' ';'                                      ? returnStmt    \
Stmt: ';'                                               ? emptyStmt     \
CompoundStmt: '{' Locals ListStmt '}'                   ? compoundStmt  " +
"\
FunctionCall: FunctionName                                              \
FunctionCall: '::' FunctionName                                         \
FunctionCall: ident '::' FunctionName                                   \
String: simple_string                                   ? simpleString  \
String: complex_string                                  ? complexString \
CompositeString: StringExp                                              \
CompositeString: CompositeString '+' StringExp          ? stringExp     \
StringExp : String                                                      \
StringExp: '(' CompositeString ')'                      ? parsed_1_     " +
"\
Exp1: decimal                                           ? expIntDec     \
Exp1: octal                                             ? expIntOct     \
Exp1: hexadecimal                                       ? expIntHex     \
Exp1: simple_char                                       ? simpleChar    \
Exp1: complex_char                                      ? complexChar   \
Exp1: float                                             ? expFloat      \
Exp1: 'nil'                                             ? expNil        \
Exp1: String                                                            \
Exp1: '(' '{' OptArgListComma '}' ')'                   ? expArray      \
Exp1: '(' '[' OptAssocListComma ']' ')'                 ? expMapping    \
Exp1: ident                                             ? expVar        \
Exp1: '::' ident                                        ? expGlobalVar  \
Exp1: '(' ListExp ')'                                   ? parsed_1_     \
Exp1: FunctionCall '(' OptArgList ')'                   ? expFuncall    \
Exp1: 'catch' '(' ListExp ')'                           ? expCatch      \
Exp1: 'new' OptObject StringExp                         ? expNew1       \
Exp1: 'new' OptObject StringExp '(' OptArgList ')'      ? expNew2       \
Exp1: Exp2 '->' ident '(' OptArgList ')'                ? expCallOther  \
Exp1: Exp2 '<-' StringExp                               ? expInstance   " +
"\
Exp2: Exp1                                                              \
Exp2: Exp2 '[' ListExp ']'                              ? expIndex      \
Exp2: Exp2 '[' ListExp '..' ListExp ']'                 ? expRange      " +
"\
PostfixExp: Exp2                                                        \
PostfixExp: PostfixExp '++'                             ? expPostIncr   \
PostfixExp: PostfixExp '--'                             ? expPostDecr   " +
"\
PrefixExp: PostfixExp                                                   \
PrefixExp: '++' CastExp                                 ? expPreIncr    \
PrefixExp: '--' CastExp                                 ? expPreDecr    \
PrefixExp: '+' CastExp                                  ? expPlus       \
PrefixExp: '-' CastExp                                  ? expMinus      \
PrefixExp: '!' CastExp                                  ? expNot        \
PrefixExp: '~' CastExp                                  ? expNegate     " +
"\
CastExp: PrefixExp                                                      \
CastExp: '(' ClassType Stars ')' CastExp                ? expCast       " +
"\
MultExp: CastExp                                                        \
MultExp: MultExp '*' CastExp                            ? expMult       \
MultExp: MultExp '/' CastExp                            ? expDiv        \
MultExp: MultExp '%' CastExp                            ? expMod        " +
"\
AddExp: MultExp                                                         \
AddExp: AddExp '+' MultExp                              ? expAdd        \
AddExp: AddExp '-' MultExp                              ? expSub        " +
"\
ShiftExp: AddExp                                                        \
ShiftExp: ShiftExp '<<' AddExp                          ? expLShift     \
ShiftExp: ShiftExp '>>' AddExp                          ? expRShift     " +
"\
RelExp: ShiftExp                                                        \
RelExp: RelExp '<' ShiftExp                             ? expLess       \
RelExp: RelExp '>' ShiftExp                             ? expGreater    \
RelExp: RelExp '<=' ShiftExp                            ? expLessEq     \
RelExp: RelExp '>=' ShiftExp                            ? expGreaterEq  " +
"\
EquExp: RelExp                                                          \
EquExp: EquExp '==' RelExp                              ? expEqual      \
EquExp: EquExp '!=' RelExp                              ? expUnequal    " +
"\
BitandExp: EquExp                                                       \
BitandExp: BitandExp '&' EquExp                         ? expAnd        " +
"\
BitxorExp: BitandExp                                                    \
BitxorExp: BitxorExp '^' BitandExp                      ? expXor        " +
"\
BitorExp: BitxorExp                                                     \
BitorExp: BitorExp '|' BitxorExp                        ? expOr         " +
"\
AndExp: BitorExp                                                        \
AndExp: AndExp '&&' BitorExp                            ? expLand       " +
"\
OrExp: AndExp                                                           \
OrExp: OrExp '||' AndExp                                ? expLor        " +
"\
CondExp: OrExp                                                          \
CondExp: OrExp '?' ListExp ':' CondExp                  ? expQuest      " +
"\
Exp: CondExp                                                            \
Exp: CondExp '=' Exp                                    ? expAssign     \
Exp: CondExp '+=' Exp                                   ? expAsgnAdd    \
Exp: CondExp '-=' Exp                                   ? expAsgnSub    \
Exp: CondExp '*=' Exp                                   ? expAsgnMult   \
Exp: CondExp '/=' Exp                                   ? expAsgnDiv    \
Exp: CondExp '%=' Exp                                   ? expAsgnMod    \
Exp: CondExp '<<=' Exp                                  ? expAsgnLShift \
Exp: CondExp '>>=' Exp                                  ? expAsgnRShift \
Exp: CondExp '&=' Exp                                   ? expAsgnAnd    \
Exp: CondExp '^=' Exp                                   ? expAsgnXor    \
Exp: CondExp '|=' Exp                                   ? expAsgnOr     " +
"\
ListExp: Exp                                                            \
ListExp: ListExp ',' Exp                                ? expComma      \
OptListExp:                                             ? opt           \
OptListExp: ListExp                                                     " +
"\
ArgList: Exp                                                            \
ArgList: ArgList ',' Exp                                                \
OptArgList:                                             ? noArguments   \
OptArgList: ArgList                                     ? arguments     \
OptArgList: ArgList '...'                               ? ellipsis      \
OptArgListComma:                                        ? list          \
OptArgListComma: ArgList                                ? noCommaList   \
OptArgListComma: ArgList ','                            ? noCommaList   " +
"\
AssocPair: Exp ':' Exp                                  ? parsed_0_2_   \
AssocList: AssocPair                                                    \
AssocList: AssocList ',' AssocPair                                      \
OptAssocListComma:                                      ? list          \
OptAssocListComma: AssocList                            ? noCommaList   \
OptAssocListComma: AssocList ','                        ? noCommaList   ",


DGD String:
unescaped = /[^\\\\]+/                                                  \
octal = /\\\\[0-7][0-7]?[0-7]?/                                         \
hexadecimal = /\\\\[xX][0-9a-fA-F][0-9a-fA-F]?/                         \
escaped = /\\\\./                                                       \
                                                                        \
String:                                                                 \
String: String Characters                                               \
Characters: unescaped                                                   \
Characters: octal                                       ? octal         \
Characters: hexadecimal                                 ? hexadecimal   \
Characters: escaped                                     ? escaped
=end